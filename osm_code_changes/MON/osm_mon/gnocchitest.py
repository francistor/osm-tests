# Test speed of different ways to access the Gnocchi API

from gnocchiclient.v1 import client as gnocchi_client
from keystoneauth1 import session
from keystoneauth1.identity import v3
from keystoneclient.v3 import client as keystone_client
import time

auth = v3.Password(auth_url='http://192.168.122.203/identity',
                   username='test-user',
                   password='test',
                   project_name='test-project',
                   project_domain_name='default',
                   user_domain_name='default')

mySession = session.Session(auth=auth, verify=False, timeout=10)
keystone = keystone_client.Client(session=mySession, include_metadata=True)

# print(keystone.projects.list().data)

# Instance e3eda237-c3df-44ef-ab64-e8372a75ca6c
# Interface 1f79b9f4-d95c-5675-99ca-1482e047426b
# Disk 2ff4068b-b567-57fa-a04f-820c90e2867f
gnocchi = gnocchi_client.Client(mySession)

def do_measures(times: int, this_session: session, resource_id: str):
    start_time = time.time()
    for _ in range(times):
        gnocchi = gnocchi_client.Client(this_session)
        res = gnocchi.metric.get_measures(
            metric="cpu",
            aggregation="mean",
            start=time.time() - 1200,
            resource_id=resource_id
        )
        # print(res)
    end_time = time.time()
    print("%s measures in %s seconds " % (times, end_time - start_time))

def do_fetch(times, this_session: session, resource_id: str):
    start_time = time.time()
    for _ in range(times):
        gnocchi = gnocchi_client.Client(this_session)
        res = gnocchi.aggregates.fetch(
            operations="(aggregate rate:mean (metric cpu mean))",
            search={"=": {"id": resource_id}},
            start=time.time() - 1200)
        # print(res)
    end_time = time.time()
    print("%s fetches in %s seconds " % (times, end_time - start_time))

do_measures(100, mySession, "e72b30cd-b534-4228-82fc-1b595e54d00f")
do_fetch(100, mySession, "e72b30cd-b534-4228-82fc-1b595e54d00f")
