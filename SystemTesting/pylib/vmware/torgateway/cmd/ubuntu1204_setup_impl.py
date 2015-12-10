import vmware.common as common
import vmware.common.errors as errors
import vmware.common.global_config as global_config
import vmware.interfaces.setup_interface as setup_interface

pylogger = global_config.pylogger


class Ubuntu1204SetupImpl(setup_interface.SetupInterface):

    @classmethod
    def set_nsx_controller(cls, client_object, controller_ip=None,
                           port=None):

        if controller_ip is None:
            raise ValueError('controller_ip cannot be None')

        if port is None:
            raise ValueError('port cannot be None')

        vtep_cmd = "vtep-ctl  set-manager ssl:" + str(controller_ip)
        vtep_cmd = vtep_cmd + ":" + str(port)
        pylogger.info("Set controller command: %s" % vtep_cmd)
        result = client_object.connection.request(vtep_cmd).response_data
        pylogger.info("result for set-controller: %s" % result)

    @classmethod
    def remove_nsx_controller(cls, client_object, status=None):

        vtep_cmd = "vtep-ctl del-manager 2>&1"
        pylogger.info("Remove controller command: %s" % vtep_cmd)
        result = client_object.connection.request(vtep_cmd).response_data
        pylogger.info("result for remove-controller: %s" % result)
        if result.strip():
            raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                  reason=result)
        else:
            return common.status_codes.SUCCESS
