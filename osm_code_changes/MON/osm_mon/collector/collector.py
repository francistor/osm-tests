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
import logging
import time

from osm_mon.collector.backends.prometheus import PrometheusBackend
from osm_mon.collector.service import CollectorService
from osm_mon.core.config import Config

log = logging.getLogger(__name__)

METRIC_BACKENDS = [
    PrometheusBackend
]

class Collector:
    def __init__(self, config: Config):
        self.conf = config
        self.service = CollectorService(config)
        self.backends = []
        self._init_backends()

    def collect_forever(self):
        log.debug('collect_forever')
        while True:
            try:
                start_time = time.time()

                # Do metric collection here
                self.collect_metrics()

                # Sleep if necessary. Otherwise we are behind schedule
                next_time = start_time + int(self.conf.get('collector', 'interval'))
                current_time = time.time()
                sleep_time = next_time - current_time
                if sleep_time > 0:
                    time.sleep(sleep_time)
                else:
                    log.warning("Collector is getting behind by %s seconds", sleep_time)

            except Exception:
                log.exception("Error collecting metrics")

    def collect_metrics(self):
        metrics = self.service.collect_metrics()
        for backend in self.backends:
            backend.handle(metrics)

    def _init_backends(self):
        for backend in METRIC_BACKENDS:
            self.backends.append(backend())
