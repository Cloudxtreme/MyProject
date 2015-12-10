import vmware.common as common
import vmware.common.constants as constants
import vmware.common.errors as errors
import vmware.common.global_config as global_config
import vmware.common.timeouts as timeouts
import vmware.interfaces.setup_interface as setup_interface

pylogger = global_config.pylogger
NODE_REGISTRATION_SUCESSS = "Node successfully registered"
NODE_DEREGISTRATION_SUCESSS = "Node successfully deregistered"


class ESX55SetupImpl(setup_interface.SetupInterface):

    @classmethod
    def set_nsx_manager(cls, client_object, manager_ip=None,
                        manager_thumbprint=None, username=None, password=None):
        pylogger.info("STUB: nsxcli:\n  config terminal\n"
                      "  registernode IP username thumbprint password")
        client_object.set_connection(
            connection_type=constants.ConnectionType.EXPECT)
        connection = client_object.connection
        result = connection.request(
            command='/opt/vmware/nsx-cli/bin/scripts/nsxcli',
            expect=['bytes*', '.>'])
        result = connection.request(command='config terminal',
                                    expect=['bytes*', '#'])
        if username is None:
            username = constants.ManagerCredential.USERNAME
        if password is None:
            password = constants.ManagerCredential.PASSWORD
        register_command = "register-node %s %s %s %s" % (
            manager_ip, username, manager_thumbprint, password)

        pylogger.info("Executing fabric registration command: %s" %
                      register_command)
        result = connection.request(command=register_command,
                                    expect=['bytes*', '#'])
        pylogger.info("Register Host Node result: %s"
                      % result.response_data)
        ret = result.response_data
        result = connection.request(command='exit',
                                    expect=['bytes*', '.>'])
        result = connection.request(command='exit',
                                    expect=['bytes*', '#', '$'])
        client_object.restore_connection()
        if NODE_REGISTRATION_SUCESSS not in ret:
            pylogger.error("Host Node Registration Failed!")
            message = [line for line in ret.splitlines() if "%" in line]
            if not message:
                message = [ret]
            raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                  reason=message[0][2:])
        else:
            cls.wait_for_nsx_services_running(client_object)

    @classmethod
    def wait_for_nsx_services_running(cls, client_object):
        pylogger.debug("Checking for nsx services to be running ...")
        kwargs = {'service_name': 'nsx-mpa'}
        if not timeouts.nsx_mpa_start_delay.wait_until(
                client_object.is_service_running, kwargs=kwargs,
                exc_handler=False, logger=pylogger):
            raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                  reason='nsx-mpa service is not running')
        kwargs = {'service_name': 'nsxa'}
        if not timeouts.nsxa_start_delay.wait_until(
                client_object.is_service_running, kwargs=kwargs,
                exc_handler=False, logger=pylogger):
            raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                  reason='nsxa service is not running')

    @classmethod
    def remove_nsx_manager(cls, client_object, manager_ip=None,
                           manager_thumbprint=None, username=None,
                           password=None):
        client_object.set_connection(
            connection_type=constants.ConnectionType.EXPECT)
        connection = client_object.connection
        connection.request(
            command='/opt/vmware/nsx-cli/bin/scripts/nsxcli',
            expect=['bytes*', '.>'])
        connection.request(command='config terminal', expect=['bytes*', '#'])
        if username is None:
            username = constants.ManagerCredential.USERNAME
        if password is None:
            password = constants.ManagerCredential.PASSWORD
        deregister_command = "deregister-node %s %s %s %s" % (
            manager_ip, username, manager_thumbprint, password)

        result = connection.request(command=deregister_command,
                                    expect=['bytes*', '#'])
        pylogger.info("Deregister Host Node result: %s"
                      % result.response_data)

        ret = result.response_data
        connection.request(command='exit', expect=['bytes*', '.>'])
        connection.request(command='exit', expect=['bytes*', '#', '$'])
        client_object.restore_connection()
        if NODE_DEREGISTRATION_SUCESSS not in ret:
            pylogger.error("Host Node Deregistration Failed!")
            message = [line for line in ret.splitlines() if "%" in line]
            if not message:
                message = [ret]
            raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                  reason=message[0][2:])

    @classmethod
    def set_nsx_controller(cls, client_object, controller_ip=None,
                           node_id=None):
        # WORKAROUND(gjayavelu): PR1294145
        # This steps configures hypervisor to connect with the given
        # controller. This should be automatically taken care by manager
        vsm_path = '/etc/vmware/nsx/config-by-vsm.xml'
        command = '/automation/scripts/set-controller %s %s %s ESX' % (
            controller_ip, node_id, vsm_path)
        pylogger.info("Set controller command: %s" % command)
        result = client_object.connection.request(command).response_data
        pylogger.info("result for set-controller: %s" % result)

    @classmethod
    def clear_nsx_manager(cls, client_object):
        raise NotImplementedError("STUB")

    @classmethod
    def configure_nsx_manager(cls, client_object,
                              operation=None, manager_ip=None,
                              manager_thumbprint=None):
        raise NotImplementedError("STUB")

    @classmethod
    def set_nsx_registration(cls, client_object, manager_ip=None,
                             manager_thumbprint=None,
                             manager_port=443,
                             manager_username=None,
                             manager_password=None):
        """
        Method to register ESX on NSX manager

        @client_object resource: list
        @param resource: List of name(s)/regex of packages to find.
        @rtype: list
        @return: List of matching packages.
        """
        command = 'nsxcli join %s:%s %s %s %s' % (manager_ip, manager_port,
                                                  manager_username,
                                                  manager_thumbprint,
                                                  manager_password)
        pylogger.info("Executing NSX registration command: %s" % command)
        try:
            client_object.connection.request(command)
        except Exception, error:
            pylogger.error("Error thrown during nsx registration %s" % error)
            raise Exception

    @classmethod
    def clear_nsx_registration(cls, client_object):
        raise NotImplementedError("STUB")

    @classmethod
    def configure_nsx_registration(cls, client_object,
                                   operation=None,
                                   manager_ip=None,
                                   manager_thumbprint=None):
        raise NotImplementedError("STUB")
