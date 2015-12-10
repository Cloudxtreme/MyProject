import vmware.common.global_config as global_config
import vmware.interfaces.service_interface as service_interface

pylogger = global_config.pylogger


class NSX70ServiceImpl(service_interface.ServiceInterface):

    @classmethod
    def configure_service_state(cls, client_obj, service_name=None,
                                state=None, **kwargs):
        if state == 'start' or state == 'stop' or state == 'restart':
            endpoint = state + " service " + service_name
            pylogger.debug('CLI Command to be executed: [%s]' % endpoint)
            expect_prompt = ['bytes*', '#']

            # Execute the command
            client_obj.connection.request('configure terminal', expect_prompt)
            client_obj.connection.request(endpoint, expect_prompt)
        else:
            raise ValueError("Received incorrect state value")

        return True