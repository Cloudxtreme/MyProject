import re
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.interfaces.setup_interface as setup_interface

pylogger = global_config.pylogger


class NSX70SetupImpl(setup_interface.SetupInterface):
    SECURITY_TYPE_PASSWORD = "password"
    SECURITY_TYPE_CERT = "cert"

    @classmethod
    def set_nsx_registration(cls, client_obj, manager_ip=None,
                             manager_thumbprint=None):
        """Register a Controller with Manager."""
        pylogger.info("Registering with NSX Manager: controller=%s, "
                      "manager=%r, thumbprint=%r" %
                      (client_obj.ip, manager_ip, manager_thumbprint))
        pylogger.debug("STUB: nsxcli:\n"
                       "  manager <manager-ip> <rmq-broker-thumbprint>")
        connection = client_obj.connection
        result = connection.request(command='join management-plane %s username'
                                    ' %s password %s thumbprint %s'
                                    % (manager_ip, 'admin',
                                       'default', manager_thumbprint),
                                    expect=['bytes*', '>'])
        if (re.findall('success', result.response_data)):
            pylogger.info("Join result is: %s" % result.response_data)
            return constants.Result.SUCCESS.upper()
        else:
            pylogger.error("Join result is: %s" % result.response_data)
            return constants.Result.FAILURE.upper()

    @classmethod
    def clear_nsx_registration(cls, client_obj):
        """Clear a Controller's Manager registration."""
        pylogger.debug("Clearing NSX Manager registration: controller=%s" %
                       client_obj.ip)
        raise NotImplementedError("STUB")

    @classmethod
    def remove_ccp_cluster_node(cls, client_obj, controller_ip=None, **kwargs):
        """Remove CCP cluster node."""
        msg = ("Removing ccp cluster node %s at node %s" %
               (controller_ip, client_obj.ip))
        pylogger.debug(msg)
        connection = client_obj.connection
        command = 'detach control-cluster %s' % controller_ip
        result = connection.request(command=command, expect=['bytes*', '>'])
        if (re.findall('Success', result.response_data)):
            pylogger.info("%s succeeded: %s" % (msg, result.response_data))
            return constants.Result.SUCCESS.upper()
        else:
            pylogger.error("%s failed: %s" % (msg, result.response_data))
            return constants.Result.FAILURE.upper()

    @classmethod
    def set_security(cls, client_obj, security_type=None, value=None):
        """Set security on CCP cluster node."""
        pylogger.info("Set security %s on ccp cluster node %s " %
                      (security_type, client_obj.ip))
        connection = client_obj.connection
        command = 'set control-cluster security-model'
        if (security_type == cls.SECURITY_TYPE_PASSWORD):
            command = '%s shared-secret secret %s' % (command, value)
            result = connection.request(command, expect=['bytes*', '>'])
            pylogger.debug("stdout from %s %s" %
                           (command, result.response_data))
        elif (security_type == cls.SECURITY_TYPE_CERT):
            pylogger.debug("This type isn't supported in product currently")
            raise ValueError("Received incorrect security type")

        if (re.findall(constants.Result.SUCCESS, result.response_data, re.I)):
            pylogger.info("Successfully set security %s on ccp %s " %
                          (security_type, client_obj.ip))
            return constants.Result.SUCCESS.upper()
        else:
            pylogger.error("Failed to set security %s on ccp %s " %
                           (security_type, client_obj.ip))
            return constants.Result.FAILURE.upper()

    @classmethod
    def get_control_cluster_thumbprint(cls, client_object):
        """
        Method to NSX controller cluster thumbprint

        Sample output of the command 'get control-cluster certificate thumbprint':  # noqa

        prme-vmkqa-net3003-dhcp194> get control-cluster certificate thumbprint
        f71250ab638c9939a91b0db1b89619a43a9cda44a2c8628167ce5327d44bd16f

        prme-vmkqa-net3003-dhcp194>
        """
        connection = client_object.connection
        command = 'get control-cluster certificate thumbprint'
        pylogger.debug('Command to get controller thumbprint %s' % command)
        # bytes* is used to skip/avoid any pagination information dumped
        # on the screen
        expect_prompt = ['bytes*', '>']
        result = connection.request(command, expect_prompt)
        stdout_lines = result.response_data.splitlines()
        thumbprint_index_in_output = 0
        thumbprint = stdout_lines[thumbprint_index_in_output]
        thumbprint = thumbprint.strip()
        if re.match(constants.Regex.ALPHA_NUMBERIC, thumbprint):
            return thumbprint
        else:
            raise ValueError("Unexpected data for thumbprint %s" %
                             result.response_data)
