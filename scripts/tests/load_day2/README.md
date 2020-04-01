# Juju fault tolerance

Use main.sh in this directory to deploy ubuntu_2vdu_day2_ns and invoke Day 2 operations.


## LCM logs for initially failed Day2 operation

Get the name of the LXD for the juju container and execute

lxc stop <container-name> && lxc start <container-name>

The executing Day2 operation does not terminate (remains in EXECUTING state) and the subsequent
ones are enqueued.

```
2020-04-01T14:55:38 DEBUG lcm lcm.py:261 Task kafka_read receives ns action: {'_admin': {'created': 1585752938.6766653, 'modified': 1585752938.6766653, 'projects_read': ['e1d6c3ae-7834-44bd-9c55-556b19c863df'], 'projects_write': ['e1d6c3ae-7834-44bd-9c55-556b19c863df']}, '_id': 'fc72f4f9-a285-40ad-a31c-168b7ab0c633', 'detailedStatus': None, 'errorMessage': None, 'id': 'fc72f4f9-a285-40ad-a31c-168b7ab0c633', 'isAutomaticInvocation': False, 'isCancelPending': False, 'lcmOperationType': 'action', 'links': {'nsInstance': '/osm/nslcm/v1/ns_instances/e9ed72e0-ab6f-4a88-a023-0247fd44ee63', 'self': '/osm/nslcm/v1/ns_lcm_op_occs/fc72f4f9-a285-40ad-a31c-168b7ab0c633'}, 'nsInstanceId': 'e9ed72e0-ab6f-4a88-a023-0247fd44ee63', 'operationParams': {'lcmOperationType': 'action', 'member_vnf_index': '1', 'nsInstanceId': 'e9ed72e0-ab6f-4a88-a023-0247fd44ee63', 'primitive': 'touch', 'primitive_params': {'filename': '/tmp/day2-scripted'}}, 'operationState': 'PROCESSING', 'queuePosition': None, 'stage': None, 'startTime': 1585752938.6765842, 'statusEnteredTime': 1585752938.6765842}
2020-04-01T14:55:38 DEBUG lcm.ns ns.py:2891 Task ns=e9ed72e0-ab6f-4a88-a023-0247fd44ee63 action=fc72f4f9-a285-40ad-a31c-168b7ab0c633 Enter
Receiver: Connection closed, reconnecting
Receiver: Connection closed, reconnecting
Task exception was never retrieved
future: <Task finished coro=<Connection.reconnect() done, defined at /usr/local/lib/python3.6/dist-packages/juju/client/connection.py:564> exception=JujuConnectionError('Unable to connect to any endpoint: 10.170.42.191:17070',)>
Traceback (most recent call last):
  File "/usr/local/lib/python3.6/dist-packages/juju/client/connection.py", line 572, in reconnect
    await self._connect_with_login([(self.endpoint, self.cacert)])
  File "/usr/local/lib/python3.6/dist-packages/juju/client/connection.py", line 632, in _connect_with_login
    await self._connect(endpoints)
  File "/usr/local/lib/python3.6/dist-packages/juju/client/connection.py", line 609, in _connect
    '{}'.format(_endpoints_str))
juju.errors.JujuConnectionError: Unable to connect to any endpoint: 10.170.42.191:17070
Task exception was never retrieved
future: <Task finished coro=<Connection.reconnect() done, defined at /usr/local/lib/python3.6/dist-packages/juju/client/connection.py:564> exception=JujuConnectionError('Unable to connect to any endpoint: 10.170.42.191:17070',)>
Traceback (most recent call last):
  File "/usr/local/lib/python3.6/dist-packages/juju/client/connection.py", line 572, in reconnect
    await self._connect_with_login([(self.endpoint, self.cacert)])
  File "/usr/local/lib/python3.6/dist-packages/juju/client/connection.py", line 632, in _connect_with_login
    await self._connect(endpoints)
  File "/usr/local/lib/python3.6/dist-packages/juju/client/connection.py", line 609, in _connect
    '{}'.format(_endpoints_str))
juju.errors.JujuConnectionError: Unable to connect to any endpoint: 10.170.42.191:17070

```

## LCM logs for subsequent instantiation operations (after rebooting Juju Controller)

After the previous tests, invoke a ns creation operation


```
2020-04-01T14:56:58 DEBUG lcm.ns ns.py:873 Task ns=4ecca528-d89f-4f1f-92c3-3f3f8a48171a instantiate=b2d36bd1-3a3c-4570-b7f3-649276dd7212 Waiting VIM to deploy ns. RO_ns_id=c7308e7b-076c-4374-9fa8-93d402e1805d
2020-04-01T14:57:20 DEBUG lcm.ns ns.py:918 Task ns=4ecca528-d89f-4f1f-92c3-3f3f8a48171a instantiate=b2d36bd1-3a3c-4570-b7f3-649276dd7212 Deployed at VIM
2020-04-01T14:57:20 ERROR lcm.ns ns.py:1738 Task ns=4ecca528-d89f-4f1f-92c3-3f3f8a48171a instantiate=b2d36bd1-3a3c-4570-b7f3-649276dd7212 Deploy VCA 1.: Failed
2020-04-01T14:57:20 ERROR lcm.ns ns.py:1744 Task ns=4ecca528-d89f-4f1f-92c3-3f3f8a48171a instantiate=b2d36bd1-3a3c-4570-b7f3-649276dd7212 Deploy VCA 1.Traceback (most recent call last):
  File "/usr/lib/python3/dist-packages/n2vc/n2vc_juju_conn.py", line 1156, in _juju_get_model
    model_list = await self.controller.list_models()
  File "/usr/local/lib/python3.6/dist-packages/juju/controller.py", line 538, in list_models
    uuids = await self.model_uuids()
  File "/usr/local/lib/python3.6/dist-packages/juju/controller.py", line 523, in model_uuids
    response = await controller_facade.AllModels()
  File "/usr/local/lib/python3.6/dist-packages/juju/client/facade.py", line 471, in wrapper
    reply = await f(*args, **kwargs)
  File "/usr/local/lib/python3.6/dist-packages/juju/client/_client5.py", line 2579, in AllModels
    reply = await self.rpc(msg)
  File "/usr/local/lib/python3.6/dist-packages/juju/client/facade.py", line 607, in rpc
    result = await self.connection.rpc(msg, encoder=TypeEncoder)
  File "/usr/local/lib/python3.6/dist-packages/juju/client/connection.py", line 431, in rpc
    0, 'websocket closed')
websockets.exceptions.ConnectionClosed: WebSocket connection is closed: code = 0 (unknown), reason = websocket closed

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "/usr/lib/python3/dist-packages/n2vc/n2vc_juju_conn.py", line 246, in create_execution_environment
    total_timeout=total_timeout
  File "/usr/lib/python3/dist-packages/n2vc/n2vc_juju_conn.py", line 787, in _juju_create_machine
    model = await self._juju_get_model(model_name=model_name)
  File "/usr/lib/python3/dist-packages/n2vc/n2vc_juju_conn.py", line 1184, in _juju_get_model
    raise N2VCException(msg)
n2vc.exceptions.N2VCException: Cannot get model 4ecca528-d89f-4f1f-92c3-3f3f8a48171a. Exception: WebSocket connection is closed: code = 0 (unknown), reason = websocket closed

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "/usr/lib/python3/dist-packages/osm_lcm/ns.py", line 1117, in instantiate_N2VC
    db_dict=db_dict)
  File "/usr/lib/python3/dist-packages/n2vc/n2vc_juju_conn.py", line 251, in create_execution_environment
    raise N2VCException(message=message)
n2vc.exceptions.N2VCException: Error creating machine on juju: Cannot get model 4ecca528-d89f-4f1f-92c3-3f3f8a48171a. Exception: WebSocket connection is closed: code = 0 (unknown), reason = websocket closed

The above exception was the direct cause of the following exception:

Traceback (most recent call last):
  File "/usr/lib/python3/dist-packages/osm_lcm/ns.py", line 1291, in instantiate_N2VC
    raise Exception("{} {}".format(step, e)) from e
Exception: create execution environment Error creating machine on juju: Cannot get model 4ecca528-d89f-4f1f-92c3-3f3f8a48171a. Exception: WebSocket connection is closed: code = 0 (unknown), reason = websocket closed

2020-04-01T14:57:20 DEBUG lcm.ns ns.py:1747 Task ns=4ecca528-d89f-4f1f-92c3-3f3f8a48171a instantiate=b2d36bd1-3a3c-4570-b7f3-649276dd7212 Deploy at VIM: Done
2020-04-01T14:57:20 DEBUG lcm.ns ns.py:1747 Task ns=4ecca528-d89f-4f1f-92c3-3f3f8a48171a instantiate=b2d36bd1-3a3c-4570-b7f3-649276dd7212 Deploy KDUs: Done
2020-04-01T14:57:20 DEBUG lcm.ns ns.py:1814 Task ns=4ecca528-d89f-4f1f-92c3-3f3f8a48171a instantiate=b2d36bd1-3a3c-4570-b7f3-649276dd7212 End of instantiation: False
2020-04-01T14:57:20 DEBUG lcm.ns ns.py:1827 Task ns=4ecca528-d89f-4f1f-92c3-3f3f8a48171a instantiate=b2d36bd1-3a3c-4570-b7f3-649276dd7212 Exit
2020-04-01T14:57:20 DEBUG lcm lcm.py:261 Task kafka_read receives ns instantiated: {'nslcmop_id': 'b2d36bd1-3a3c-4570-b7f3-649276dd7212', 'nsr_id': '4ecca528-d89f-4f1f-92c3-3f3f8a48171a',
 'operationState': 'FAILED'}

```

## Day 2 invocations with restart of proxy charm

Works properly. The operations fails and is signalled as failed. Subsequent operations do not block.

```
2020-04-01T15:58:00 DEBUG lcm lcm.py:261 Task kafka_read receives ns action: {'_admin': {'created': 1585756680.116574, 'modified': 1585756680.116574, 'projects_read': ['e1d6c3ae-7834-44bd-9c55-556b19c863df'], 'projects_write': ['e1d6c3ae-7834-44bd-9c55-556b19c863df']}, '_id': 'f0aec393-95b8-4992-9dfb-5c24c4874d76', 'detailedStatus': None, 'errorMessage': None, 'id': 'f0aec393-95b8-4992-9dfb-5c24c4874d76', 'isAutomaticInvocation': False, 'isCancelPending': False, 'lcmOperationType': 'action', 'links': {'nsInstance': '/osm/nslcm/v1/ns_instances/1bc0166e-8d3a-4c2c-a1c5-bf1a1d7d0f7a', 'self': '/osm/nslcm/v1/ns_lcm_op_occs/f0aec393-95b8-4992-9dfb-5c24c4874d76'}, 'nsInstanceId': '1bc0166e-8d3a-4c2c-a1c5-bf1a1d7d0f7a', 'operationParams': {'lcmOperationType': 'action', 'member_vnf_index': '1', 'nsInstanceId': '1bc0166e-8d3a-4c2c-a1c5-bf1a1d7d0f7a', 'primitive': 'touch', 'primitive_params': {'filename': '/tmp/day2-scripted'}}, 'operationState': 'PROCESSING', 'queuePosition': None, 'stage': None, 'startTime': 1585756680.1164885, 'statusEnteredTime': 1585756680.1164885}
2020-04-01T15:58:00 DEBUG lcm.ns ns.py:2891 Task ns=1bc0166e-8d3a-4c2c-a1c5-bf1a1d7d0f7a action=f0aec393-95b8-4992-9dfb-5c24c4874d76 Enter
2020-04-01T15:58:35 DEBUG lcm.ns ns.py:3080 Task ns=1bc0166e-8d3a-4c2c-a1c5-bf1a1d7d0f7a action=f0aec393-95b8-4992-9dfb-5c24c4874d76  task Done with result FAILED Cannot execute action touch on 1bc0166e-8d3a-4c2c-a1c5-bf1a1d7d0f7a.app-vnf-946af5d26b27.0: <<class 'n2vc.exceptions.N2VCExecutionException'>> Error executing primitive touch failed: Error executing primitive touch into ee=1bc0166e-8d3a-4c2c-a1c5-bf1a1d7d0f7a.app-vnf-946af5d26b27.0 : status is not completed: failed
2020-04-01T15:58:35 DEBUG lcm.ns ns.py:3120 Task ns=1bc0166e-8d3a-4c2c-a1c5-bf1a1d7d0f7a action=f0aec393-95b8-4992-9dfb-5c24c4874d76 Exit
2020-04-01T15:58:35 DEBUG lcm lcm.py:261 Task kafka_read receives ns actioned: {'nslcmop_id': 'f0aec393-95b8-4992-9dfb-5c24c4874d76', 'nsr_id': '1bc0166e-8d3a-4c2c-a1c5-bf1a1d7d0f7a', 'operationState': 'FAILED'}
2020-04-01T15:58:35 DEBUG lcm.ns ns.py:3128 Task ns=1bc0166e-8d3a-4c2c-a1c5-bf1a1d7d0f7a action=f0aec393-95b8-4992-9dfb-5c24c4874d76 Exit
```



