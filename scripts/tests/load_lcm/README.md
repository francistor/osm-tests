## Invoke main.sh 

When reaching about 22 instances of the created network service, mon starts to behave incorrectly.

The reason is as follows. mon has two loops

* One calling _collect_vim_metrics for each VDU, in a separate process, interacting with Gnocchi. The number of processes launched every 30 seconds is thus the number of VDU
* One calling _collect_vim_infra_metrics, launching a separate process for each VIM, but internally looping (sequentially) per VDU and invoking nova.servers.get(resource_uuid). This one takes time

The proccesses are joined using a 10 seconds timeout. When the second loop takes more than 10 seconds, mon behaves incorrectly, creating orphan processes.

