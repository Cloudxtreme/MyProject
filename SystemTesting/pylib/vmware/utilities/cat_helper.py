import httplib
import json
import argparse

import vmware.common.constants as constants
import vmware.common.global_config as global_config

pylogger = global_config.pylogger
CAT_API_SERVER = 'cat-api.eng.vmware.com'


def retry_testrun(workunit_id=None, deliverable_id=None, api_key=None,
                  username=None):
    # Use this method only when absolutely necessary.
    # CAT team is not willing to allow more frequent reruns until the new UI
    # is ready. Also, this is not recommended due to limited resources on cloud
    connection = httplib.HTTPSConnection(CAT_API_SERVER)
    headers = {'content-type': 'application/json'}
    url = 'http://%s/api/v2.0/testrun/?api_key=%s&username=%s' % (
        CAT_API_SERVER, api_key, username)
    deliverable_endpoint = '/api/v2.0/deliverable'
    deliverables = []
    for id_ in deliverable_id:
        deliverables.append('%s/%s/' % (deliverable_endpoint, id_))
    pylogger.info('deliverable list %s' % deliverables)
    body = {"deliverables": deliverables,
            "workunit": "/api/v2.0/workunit/%s/" % workunit_id}
    body = json.dumps(body)
    connection.request(constants.HTTPVerb.POST, url, body, headers)
    response = connection.getresponse()

    status = response.status
    raw_data = response.read()
    if status != httplib.CREATED:
        pylogger.error("Retry testrun for workunit %s failed: %s" % (
            workunit_id, status))
        raise RuntimeError(raw_data)
    data = json.loads(raw_data)
    testrun_url = 'https://%s/testrun/%s' % (
        CAT_API_SERVER,  data['id'])
    pylogger.info("Testrun started %s" % testrun_url)

if __name__ == '__main__':
    # Parse commandline arguments.
    parser = argparse.ArgumentParser()
    parser.add_argument("--deliverable", dest="deliverable", action="append",
                        help="Deliverable ID")
    parser.add_argument("--workunit", dest="workunit", action="store",
                        help="Workunit ID")
    # To get apikey, click on the username on cat.eng.vmware.com and
    # follow instructions given there
    parser.add_argument("--apikey", dest="api_key", action="store",
                        help="API key for write access")
    parser.add_argument("--username", dest="username", action="store",
                        help="CAT user name")
    options = parser.parse_args()

    retry_testrun(
        workunit_id=options.workunit, deliverable_id=options.deliverable,
        api_key=options.api_key, username=options.username)
