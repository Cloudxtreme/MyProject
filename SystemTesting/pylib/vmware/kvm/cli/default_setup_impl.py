import re
import vmware.common as common
import vmware.common.constants as constants
import vmware.common.errors as errors
import vmware.common.global_config as global_config
import vmware.interfaces.setup_interface as setup_interface


pylogger = global_config.pylogger
NODE_REGISTRATION_SUCESSS = "Node successfully registered"
NODE_DEREGISTRATION_SUCESSS = "Node successfully deregistered"


class DefaultSetupImpl(setup_interface.SetupInterface):

    # TODO(salmanm): Devise a better way to share platform agnostic code
    # between the platforms.
    @classmethod
    def set_nsx_manager(cls, client_object, manager_ip=None,
                        manager_thumbprint=None, username=None, password=None):
        client_object.set_connection(
            connection_type=constants.ConnectionType.EXPECT)
        connection = client_object.connection
        result = connection.request(
            command='/opt/vmware/nsx-cli/bin/scripts/nsxcli',
            expect=['bytes*', '.>'])
        result = connection.request(command='config terminal',
                                    expect=['bytes*', '.#'])
        if username is None:
            username = constants.ManagerCredential.USERNAME
        if password is None:
            password = constants.ManagerCredential.PASSWORD
        register_command = "register-node %s %s %s %s" % (
            manager_ip, username, manager_thumbprint, password)
        pylogger.info("Executing fabric host registration command: %s" %
                      register_command)
        result = connection.request(command=register_command,
                                    expect=['bytes*', '#'])
        pylogger.info("Register Host Node result: %s"
                      % result.response_data)
        ret = result.response_data.splitlines()
        # Exit from the config terminal of the CLI.
        result = connection.request(command='exit',
                                    expect=['bytes*', '.>'])
        # Exit from the CLI itself.
        result = connection.request(command='exit',
                                    expect=['bytes*', '.#'])

        if not any(NODE_REGISTRATION_SUCESSS in line for line in ret):
            pylogger.error("Host Node Registration Failed!")
            message = [line for line in ret if "%" in line]
            if len(message) < 1:
                message[0] = ret
            raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                  reason=message[0][2:])
        else:
            pylogger.info("Verifiying that MPA is up ...")
            result = connection.request(command='/etc/init.d/nsx-mpa status',
                                        expect=['bytes*', '#'])
            if not re.search("is running", result.response_data):
                pylogger.error("NSX-MPA is not running!")
                raise RuntimeError("NSX-MPA is not running!")
            pylogger.info("Verifying nsxa status ...")
            # TODO(salmanm): Call helpers for verifying the service status.
            result = connection.request(command='/etc/init.d/nsxa status',
                                        expect=['bytes*', '#'])
            if not re.search("is running", result.response_data):
                pylogger.error("NSXA not started successfully")
                raise RuntimeError("NSXA is not running")
            client_object.restore_connection()

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
        connection.request(command='exit', expect=['bytes*', '.>'])
        connection.request(command='exit', expect=['bytes*', '#'])
        client_object.restore_connection()
        ret = result.response_data.splitlines()
        if not any(NODE_DEREGISTRATION_SUCESSS in line for line in ret):
            pylogger.error("Host Node Deregistration Failed!")
            message = [line for line in ret if "%" in line]
            if len(message) < 1:
                message[0] = ret
            raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                  reason=message[0][2:])
