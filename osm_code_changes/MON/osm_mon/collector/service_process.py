# -*- coding: utf-8 -*-

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

# This version uses a ProcessThreadPoolExecutor in order to limit the number of processes launched

import logging
import time
from typing import List

from osm_mon.collector.infra_collectors.onos import OnosInfraCollector
from osm_mon.collector.infra_collectors.openstack import OpenstackInfraCollector
from osm_mon.collector.infra_collectors.vio import VIOInfraCollector
from osm_mon.collector.infra_collectors.vmware import VMwareInfraCollector
from osm_mon.collector.metric import Metric
from osm_mon.collector.vnf_collectors.juju import VCACollector
from osm_mon.collector.vnf_collectors.openstack import OpenstackCollector
from osm_mon.collector.vnf_collectors.vio import VIOCollector
from osm_mon.collector.vnf_collectors.vmware import VMwareCollector
from osm_mon.core.common_db import CommonDbClient
from osm_mon.core.config import Config

import multiprocessing
import concurrent.futures

log = logging.getLogger(__name__)

VIM_COLLECTORS = {
    "openstack": OpenstackCollector,
    "vmware": VMwareCollector,
    "vio": VIOCollector
}
VIM_INFRA_COLLECTORS = {
    "openstack": OpenstackInfraCollector,
    "vmware": VMwareInfraCollector,
    "vio": VIOInfraCollector
}
SDN_INFRA_COLLECTORS = {
    "onos": OnosInfraCollector
}

class CollectorService:

    # The processes getting metrics will store the results in this queue
    queue = multiprocessing.Queue()

    def __init__(self, config: Config):
        self.conf = config
        self.common_db = CommonDbClient(self.conf)

    # static methods to be executed in the Processes
    @staticmethod
    def _get_vim_type(conf: Config, vim_account_id: str) -> str:
        common_db = CommonDbClient(conf)
        vim_account = common_db.get_vim_account(vim_account_id)
        vim_type = vim_account['vim_type']
        if 'config' in vim_account and 'vim_type' in vim_account['config']:
            vim_type = vim_account['config']['vim_type'].lower()
            if vim_type == 'vio' and 'vrops_site' not in vim_account['config']:
                vim_type = 'openstack'
        return vim_type

    @staticmethod
    def _collect_vim_metrics(conf: Config, vnfr: dict, vim_account_id: str):
        # TODO(diazb) Add support for aws
        vim_type = CollectorService._get_vim_type(conf, vim_account_id)
        if vim_type in VIM_COLLECTORS:
            collector = VIM_COLLECTORS[vim_type](conf, vim_account_id)
            metrics = collector.collect(vnfr)
            for metric in metrics:
                pass
                CollectorService.queue.put(metric)
        else:
            log.debug("vimtype %s is not supported.", vim_type)

    @staticmethod
    def _collect_vca_metrics(conf: Config, vnfr: dict):
        vca_collector = VCACollector(conf)
        metrics = vca_collector.collect(vnfr)
        for metric in metrics:
            CollectorService.queue.put(metric)

    @staticmethod
    def _collect_vim_infra_metrics(conf: Config, vim_account_id: str):
        vim_type = CollectorService._get_vim_type(conf, vim_account_id)
        if vim_type in VIM_INFRA_COLLECTORS:
            collector = VIM_INFRA_COLLECTORS[vim_type](conf, vim_account_id)
            metrics = collector.collect()
            for metric in metrics:
                CollectorService.queue.put(metric)
        else:
            log.debug("vimtype %s is not supported.", vim_type)

    @staticmethod
    def _collect_sdnc_infra_metrics(conf: Config, sdnc_id: str):
        common_db = CommonDbClient(conf)
        sdn_type = common_db.get_sdnc(sdnc_id)['type']
        if sdn_type in SDN_INFRA_COLLECTORS:
            collector = SDN_INFRA_COLLECTORS[sdn_type](conf, sdnc_id)
            metrics = collector.collect()
            for metric in metrics:
                CollectorService.queue.put(metric)
        else:
            log.debug("sdn_type %s is not supported.", sdn_type)

    def collect_metrics(self) -> List[Metric]:
        vnfrs = self.common_db.get_vnfrs()
        metrics = []

        start_time = time.time()
        # TODO: Configure the number of polling processes
        with concurrent.futures.ProcessPoolExecutor(20) as executor:
            futures = []
            for vnfr in vnfrs:
                nsr_id = vnfr['nsr-id-ref']
                vnf_member_index = vnfr['member-vnf-index-ref']
                vim_account_id = self.common_db.get_vim_account_id(nsr_id, vnf_member_index)
                futures.append(executor.submit(CollectorService._collect_vim_metrics, self.conf, vnfr, vim_account_id))
                futures.append(executor.submit(CollectorService._collect_vca_metrics, self.conf, vnfr))

            vims = self.common_db.get_vim_accounts()
            for vim in vims:
                futures.append(executor.submit(CollectorService._collect_vim_infra_metrics, self.conf, vim['_id']))

            sdncs = self.common_db.get_sdncs()
            for sdnc in sdncs:
                futures.append(executor.submit(CollectorService._collect_sdnc_infra_metrics, self.conf, sdnc['_id']))

            # Timeout is 300 seconds
            # Collect results here to avoid having a big queue, which seems to block
            for future in concurrent.futures.as_completed(futures, 300):
                while not self.queue.empty():
                    metrics.append(self.queue.get())

        end_time=time.time()
        log.info("Collection completed in %s seconds", end_time - start_time)

        return metrics
