import vmware.common.global_config as global_config
import vmware.interfaces.power_interface as power_interface

import vmware.nsx_api.appliance.node.restartorshutdownnode as \
    restartorshutdownnode

pylogger = global_config.pylogger


class NSX70PowerImpl(power_interface.PowerInterface):

    @classmethod
    def configure_power_state(cls, client_object, state=None):
        if state == 'shutdown':
            cls._power_state(client_object,
                             url_parameters={'action': 'shutdown'})
        elif state == 'restart':
            cls._power_state(client_object,
                             url_parameters={'action': 'restart'})
        else:
            raise ValueError("Received power configuration for unknown state"
                             % state)

    @classmethod
    def _power_state(cls, client_object, url_parameters):
        client_class_obj = restartorshutdownnode.RestartOrShutdownNode(
            connection_object=client_object.connection)
        client_class_obj.create(
            schema_object=None, url_parameters=url_parameters)
        result_dict = dict()
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = \
            client_class_obj.last_calls_status_code
        return result_dict
