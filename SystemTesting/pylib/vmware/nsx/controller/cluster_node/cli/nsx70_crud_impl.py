import re
import time
import vmware.common.global_config as global_config
import vmware.interfaces.crud_interface as crud_interface
import vmware.common.constants as constants

pylogger = global_config.pylogger
CLUSTER_JOIN_RETRY = 5


class NSX70CRUDImpl(crud_interface.CRUDInterface):

    @classmethod
    def create(cls, client_obj, schema=None, **kwargs):
        """Create CCP cluster and return the UUID for joined CCP."""
        control_cluster_thumbprint = schema.get('control_cluster_thumbprint')
        controller_ip = schema['controller_ip']
        pylogger.info("ip is: %s" % controller_ip)
        pylogger.info("Join controller node %s "
                      "to master node %s" %
                      (controller_ip, client_obj.parent.ip))

        connection = client_obj.connection
        timeout = constants.Timeout.FORM_CCP_CLUSTER
        response_data = {'status_code': 404}
        ret = {'response_data': response_data}

        retries = 0
        if (client_obj.parent.ip != controller_ip):
            while retries < CLUSTER_JOIN_RETRY:
                retries = retries + 1
                try:
                    result = connection.request(
                        command='join control-cluster %s thumbprint %s'
                        % (controller_ip, control_cluster_thumbprint),
                        expect=['bytes*', '>'],
                        timeout=timeout)
                except:
                    pylogger.warning("Join controller node %s to master "
                                     "node %s failed retry %s" %
                                     (controller_ip, client_obj.parent.ip,
                                      retries))
                    time.sleep(10)
                    continue

                pylogger.debug("stdout from join control-cluster %s" %
                               result.response_data)
                if (re.findall('error', result.response_data)):
                    time.sleep(10)
                    pylogger.warning("Join controller node %s "
                                     "to master node %s failed retry %s" %
                                     (controller_ip, client_obj.parent.ip,
                                      retries))
                else:
                    pylogger.info("Join controller node %s "
                                  "to master node %s success" %
                                  (controller_ip, client_obj.parent.ip))
                    break

        """Add sleep before get in case the ccp is still joining"""
        time.sleep(10)
        """Get UUID for joined CCP."""
        retries = 0
        done = 0
        uuid = None
        while done == 0:
            result = connection.request(command='get control-cluster status',
                                        expect=['bytes*', '>'])
            pylogger.debug("stdout from controller status %s" %
                           result.response_data)
            outputLines = result.response_data.split('\n')
            outputLines = outputLines[3:-2]
            pylogger.debug("The outputLines are %s" % outputLines)
            for line in outputLines:
                ip = line.strip().split()[1]
                if (controller_ip == ip):
                    uuid = line.strip().split()[0]
                    ret['response_data']['status_code'] = 201
                    done = 1
                    break
            if (not uuid):
                retries = retries + 1
                if retries > 5:
                    break
                time.sleep(30)

        if (not uuid):
            raise Exception("Failed to find ID for NSX controller %s "
                            % controller_ip)
        ret['id_'] = uuid
        return ret
