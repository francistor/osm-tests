## Load with cirros_with_monitoring image

mon starts to loose samples at about 22 NS instances.

mon has two loops for getting the metrics
* The one to collect vim metrics for each VDU (_collect_vim_metrics), which launches a separate process. The number of processes launched is thus the number of VDU in the system
* Another one to collect infra metrics (_collect_vim_infra_metrics), which launches a single separate process for each VIM, but this one internally loops over all VDU again
invoking nova.servers.get(resource_uuid)

When the second one takes more than the 10 seconds configured for process join, mon starts to behave incorrectly



