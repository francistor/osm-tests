# Copyright 2018 Whitestack, LLC
# *************************************************************

# This file is part of OSM Monitoring module
# All Rights Reserved to Whitestack, LLC

# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at

#         http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# For those usages not covered by the Apache License, Version 2.0 please
# contact: bdiaz@whitestack.com or glavado@whitestack.com
##
from enum import Enum
import logging
import time
from typing import List

from ceilometerclient import client as ceilometer_client
from ceilometerclient.exc import HTTPException
import gnocchiclient.exceptions
from gnocchiclient.v1 import client as gnocchi_client
from keystoneauth1.exceptions.catalog import EndpointNotFound
from keystoneclient.v3 import client as keystone_client
from neutronclient.v2_0 import client as neutron_client

from osm_mon.collector.metric import Metric
from osm_mon.collector.utils.openstack import OpenstackUtils
from osm_mon.collector.vnf_collectors.base_vim import BaseVimCollector
from osm_mon.collector.vnf_metric import VnfMetric
from osm_mon.core.common_db import CommonDbClient
from osm_mon.core.config import Config

log = logging.getLogger(__name__)

# OSM external names to internal names
METRIC_MAPPINGS = {
    "average_memory_utilization": "memory.usage",
    "disk_read_ops": "disk.read.requests.rate",
    "disk_write_ops": "disk.write.requests.rate",
    "disk_read_bytes": "disk.read.bytes.rate",
    "disk_write_bytes": "disk.write.bytes.rate",
    "packets_in_dropped": "network.outgoing.packets.drop",
    "packets_out_dropped": "network.incoming.packets.drop",
    "packets_received": "network.incoming.packets.rate",
    "packets_sent": "network.outgoing.packets.rate",
    "cpu_utilization": "cpu",
}

# Metric mapping -> Operation to fetch in gnocchi, aggregation type | scaling factor if dynamic aggregate
# For each metric name, specifies some parameter for the query in gnocchi
# - Metric name : parameters
# Parameters are
# 1. Operation for fetch in Gnocchi.  See https://gnocchi.xyz/rest.html#dynamic-aggregates
#       Possible syntax
#       (metric <metric-id> <aggregation>) --> Simple metric retieval
#       (aggregate <aggregation method> (operation)) --> Dynamic aggregation. Notice that this is recursive
# 2. Aggregation name to retrieve from the result.
#       If the operation was a metric retrieval, "mean" is used normally
#       If the operation was a dynamic aggregation, the parameter is not used
# 3. Scale factor to apply to the result
GNOCCHI_OPERATIONS_PARAMS = {
    "memory.usage": ["(metric memory.usage mean)", "mean", 1],
    "cpu": ["(aggregate rate:mean (metric cpu mean))", 0.0000001],
    "disk.read.requests.rate": ["(aggregate rate:mean (metric disk.device.read.requests mean))", "not-used", 1],
    "disk.write.requests.rate": ["(aggregate rate:mean (metric disk.device.write.requests mean))", "not-used", 1],
    "disk.read.bytes.rate": ["(aggregate rate:mean (metric disk.device.read.bytes mean))", "not-used", 1],
    "disk.write.bytes.rate": ["(aggregate rate:mean (metric disk.device.write.bytes mean))", "not-used", 1],
    "network.incoming.packets.drop": ["(metric network.incoming.packets.drop mean)", "mean", 1],
    "network.outgoing.packets.drop": ["(metric network.outgoing.packets.drop mean)", "mean", 1],
    "network.incoming.packets.rate": ["(aggregate rate:mean (metric network.incoming.packets mean))", "not-used", 1],
    "network.outgoing.packets.rate": ["(aggregate rate:mean (metric network.outgoing.packets mean))", "not-used", 1]
}

INTERFACE_METRICS = ['packets_in_dropped', 'packets_out_dropped', 'packets_received', 'packets_sent']
DISK_METRICS = ['disk_read_ops', 'disk_write_ops', 'disk_read_bytes', 'disk_write_bytes']

class MetricType(Enum):
    INSTANCE = 'instance'
    DISK = 'disk'
    INTERFACE_ALL = 'interface_all'
    INTERFACE_ONE = 'interface_one'

class OpenstackCollector(BaseVimCollector):
    def __init__(self, config: Config, vim_account_id: str):
        super().__init__(config, vim_account_id)
        self.common_db = CommonDbClient(config)
        vim_account = self.common_db.get_vim_account(vim_account_id)
        self.backend = self._get_backend(vim_account)

    def _build_keystone_client(self, vim_account: dict) -> keystone_client.Client:
        sess = OpenstackUtils.get_session(vim_account)
        return keystone_client.Client(session=sess)

    def _get_resource_uuid(self, nsr_id: str, vnf_member_index: str, vdur_name: str) -> str:
        vdur = self.common_db.get_vdur(nsr_id, vnf_member_index, vdur_name)
        return vdur['vim-id']

    def collect(self, vnfr: dict) -> List[Metric]:
        nsr_id = vnfr['nsr-id-ref']
        vnf_member_index = vnfr['member-vnf-index-ref']
        vnfd = self.common_db.get_vnfd(vnfr['vnfd-id'])

        # Populate extra tags for metrics
        tags = {}
        tags['ns_name'] = self.common_db.get_nsr(nsr_id)['name']
        if vnfr['_admin']['projects_read']:
            tags['project_id'] = vnfr['_admin']['projects_read'][0]
        else:
            tags['project_id'] = ''

        metrics = []
        for vdur in vnfr['vdur']:
            # This avoids errors when vdur records have not been completely filled
            if 'name' not in vdur:
                continue
            # vnfd['vdu'] gets all the vdu in the descriptor of the VNF
            # then get the one whose 'id' is the same as the 'vdu-id-ref' in the current vdur
            vdu = next(
                filter(lambda vdu: vdu['id'] == vdur['vdu-id-ref'], vnfd['vdu'])
            )

            if 'monitoring-parameter' in vdu:
                for param in vdu['monitoring-parameter']:
                    metric_name = param['performance-metric']
                    interface_name = param['interface-name-ref'] if 'interface-name-ref' in param else None
                    openstack_metric_name = METRIC_MAPPINGS[metric_name]
                    metric_type = self._get_metric_type(metric_name, interface_name)
                    try:
                        resource_id = self._get_resource_uuid(nsr_id, vnf_member_index, vdur['name'])
                    except ValueError:
                        log.warning(
                            "Could not find resource_uuid for vdur %s, vnf_member_index %s, nsr_id %s. "
                            "Was it recently deleted?",
                            vdur['name'], vnf_member_index, nsr_id)
                        continue
                    try:
                        log.debug("Collecting metric type: %s and metric_name: %s and resource_id %s and interface_name: %s"
                                  % (metric_type, metric_name, resource_id, interface_name))
                        value = self.backend.collect_metric(metric_type, openstack_metric_name, resource_id,
                                                            interface_name)
                        if value is not None:
                            log.debug("Metric value: %s" % (value))
                            if interface_name:
                                tags['interface'] = interface_name
                            metric = VnfMetric(nsr_id, vnf_member_index, vdur['name'], metric_name, value, tags)
                            metrics.append(metric)
                        else:
                            log.debug("metric value is empty")
                    except Exception as e:
                        log.exception("Error collecting metric %s for vdu %s" % (metric_name, vdur['name']))
                        log.info("Error in metric collection: %s" % e)
        return metrics

    def _get_backend(self, vim_account: dict):
        try:
            ceilometer = CeilometerBackend(vim_account)
            ceilometer.client.capabilities.get()
            log.debug("Using ceilometer backend to collect metric")
            return ceilometer
        except (HTTPException, EndpointNotFound):
            gnocchi = GnocchiBackend(vim_account)
            gnocchi.client.metric.list(limit=1)
            log.debug("Using gnocchi backend to collect metric")
            return gnocchi

    def _get_metric_type(self, metric_name: str, interface_name: str) -> MetricType:
        if metric_name in DISK_METRICS:
            return MetricType.DISK
        elif metric_name in INTERFACE_METRICS:
            if interface_name:
                return MetricType.INTERFACE_ONE
            else:
                return MetricType.INTERFACE_ALL
        else:
            return MetricType.INSTANCE

class OpenstackBackend:
    def collect_metric(self, metric_type: MetricType, metric_name: str, resource_id: str, interface_name: str):
        pass

class GnocchiBackend(OpenstackBackend):

    def __init__(self, vim_account: dict):
        self.client = self._build_gnocchi_client(vim_account)
        self.neutron = self._build_neutron_client(vim_account)

    def _build_gnocchi_client(self, vim_account: dict) -> gnocchi_client.Client:
        sess = OpenstackUtils.get_session(vim_account)
        return gnocchi_client.Client(session=sess)

    def _build_neutron_client(self, vim_account: dict) -> neutron_client.Client:
        sess = OpenstackUtils.get_session(vim_account)
        return neutron_client.Client(session=sess)

    def collect_metric(self, metric_type: MetricType, metric_name: str, resource_id: str, interface_name: str):
        try:
            if metric_type == MetricType.INTERFACE_ONE:
                return self._collect_interface_one_metric(metric_name, resource_id, interface_name)

            if metric_type == MetricType.INTERFACE_ALL:
                return self._collect_interface_all_metric(metric_name, resource_id)

            if metric_type == MetricType.DISK:
                return self._collect_disk_all_metric(metric_name, resource_id)

            elif metric_type == MetricType.INSTANCE:
                return self._collect_metric(metric_name, resource_id)

        except gnocchiclient.exceptions.NotFound as e:
            log.debug("No metric %s found of type %s for resource %s and interface name %s" % (metric_name, metric_type, resource_id, interface_name))

        except Exception as e:
            log.error("Error collecting metric %s found of type %s for resource %s and interface name %s %s" % (metric_name, metric_type, resource_id, interface_name, e))

        else:
            raise Exception('Unknown metric type %s' % metric_type.value)

    def _collect_interface_one_metric(self, openstack_metric_name, resource_id, interface_name):
        ports = self.neutron.list_ports(name=interface_name, device_id=resource_id)
        if not ports or not ports['ports']:
            log.warning(
                'Port not found for interface %s on instance %s' % (interface_name, resource_id))
            return None
        else:
            port = ports['ports'][0]
            port_uuid = port['id'][:11]
            tap_name = 'tap' + port_uuid
            interfaces = self.client.resource.search(resource_type='instance_network_interface',
                                                     query={'=': {'name': tap_name}})

            return self._collect_metric(openstack_metric_name, resource_id=interfaces[0]['id'])

    # TODO: Add the possibility to get the metrics for a single disk, as done for interfaces
    def _collect_disk_all_metric(self, openstack_metric_name, resource_id):
        total_measure = float(0)
        disks = self.client.resource.search(resource_type='instance_disk',
                                                 query={'=': {'instance_id': resource_id}})
        for disk in disks:

            measure = self._collect_metric(openstack_metric_name, resource_id=disk['id'])
            if measure:
                total_measure += measure

        return total_measure

    def _collect_interface_all_metric(self, openstack_metric_name, resource_id):
        total_measure = float(0)
        interfaces = self.client.resource.search(resource_type='instance_network_interface',
                                                 query={'=': {'instance_id': resource_id}})
        for interface in interfaces:
            measure = self._collect_metric(openstack_metric_name, resource_id=interface['id'])
            if measure:
                total_measure += measure

        return total_measure

    def _collect_metric(self, openstack_metric_name, resource_id):
        value = None
        gnocchi_operation_params = GNOCCHI_OPERATIONS_PARAMS.get(openstack_metric_name)
        if gnocchi_operation_params:

            start_time=time.time()
            agg = self.client.aggregates.fetch(
                operations=gnocchi_operation_params[0],
                search={"=": {"id": resource_id}},
                start=time.time() - 1200)
            end_time=time.time()
            log.debug("Collection of %s for resource %s took %s seconds", openstack_metric_name, resource_id, end_time - start_time)
            try:
                if 'aggregated' in agg['measures']:
                    # It is a dynamic aggregation, used for rates. The third parameter in gnocchi_operation is the
                    # scaling factor to apply after dividing by the main aggregation time, and the second is unused
                    value = float((agg['measures']['aggregated'][-1][2] / agg['measures']['aggregated'][-1][1]) * gnocchi_operation_params[2])

                else:
                    # Otherwise, the second parameter in gnocchi_operation is the aggregation method name to retrieve
                    value = float(agg['measures'][resource_id][openstack_metric_name][gnocchi_operation_params[1]][-1][2]) * gnocchi_operation_params[2]
            except Exception as e:
                log.debug("Empty metric %s for resource %s" % (openstack_metric_name, resource_id))

        else:
            log.warning("Not executing collection for %s" % (openstack_metric_name))

        return value

class CeilometerBackend(OpenstackBackend):
    def __init__(self, vim_account: dict):
        self.client = self._build_ceilometer_client(vim_account)

    def _build_ceilometer_client(self, vim_account: dict) -> ceilometer_client.Client:
        sess = OpenstackUtils.get_session(vim_account)
        return ceilometer_client.Client("2", session=sess)

    def collect_metric(self, metric_type: MetricType, metric_name: str, resource_id: str, interface_name: str):
        if metric_type != MetricType.INSTANCE:
            raise NotImplementedError('Ceilometer backend only support instance metrics')
        measures = self.client.samples.list(meter_name=metric_name, limit=1, q=[
            {'field': 'resource_id', 'op': 'eq', 'value': resource_id}])
        return measures[0].counter_volume if measures else None
