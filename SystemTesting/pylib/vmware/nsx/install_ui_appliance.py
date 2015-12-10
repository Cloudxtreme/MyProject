import vmware.nsx_api.base.http_connection as http_connection
import vmware.common.global_config as global_config
import httplib
import json
from vmware.nsx_api.base.exceptions import RESTCallException

pylogger = global_config.pylogger


def install_uas_war(ip, build):
    """
    Install UAS WAR file with specified build.

    @param ip:    server to be upgraded.
    @param build: build number from build web.
    """
    pylogger.debug("Update UAS server %s with build %s..." %
                   (ip, build))
    method = 'POST'
    endpoint = '/autoserv/v1/update-uas'
    headers = {"Content-type": "application/json"}
    payload = {"build_number": build}
    conn = http_connection.HTTPConnection(ip)
    conn.create_connection()
    response = conn.request(method, endpoint, json.dumps(payload), headers)
    if response.status not in [httplib.OK,
                               httplib.CREATED]:
        response_data = response.read()
        pylogger.error('REST call failed: Details: %s', response_data)
        pylogger.error('ErrorCode: %s', response.status)
        pylogger.error('Reason: %s', response.reason)
        raise RESTCallException(status_code=response.status,
                                reason=response.reason,
                                detail_string=response_data)
