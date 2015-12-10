import vmware.common as common
import vmware.common.errors as errors
import vmware.common.global_config as global_config
import vmware.interfaces.service_interface as service_interface

pylogger = global_config.pylogger
START = 'running'
STOP = 'stopped'
NOTFOUND = 'notfound'
EXPECT_PROMPT = ['bytes*', '#']


class NSX70ServiceImpl(service_interface.ServiceInterface):
    """Service related operations."""

    @classmethod
    def configure_service_state(cls, client_object, service_name=None,
                                state=None):
        pylogger.info('Service Name: %s,Operation: %s'
                      % (service_name, state))
        if state == 'start':
            return cls._start_service(client_object, key=service_name)
        elif state == 'stop':
            return cls._stop_service(client_object, key=service_name)
        else:
            raise ValueError("Received incorrect service state")

    @classmethod
    def _get_service_state(cls, client_object, expect, service_name=None):
        command = '/etc/init.d/%s status' % service_name
        out = client_object.connection.\
            request(command, expect).response_data
        pylogger.debug('Command: %s,output: %s' % (command, out))

        if 'stopped' in out or 'not running' in out:
            return STOP
        elif 'running' in out:
            return START
        else:
            return NOTFOUND

    @classmethod
    def _stop_service(cls, client_object, key=None):
        current_state = cls._get_service_state(client_object, EXPECT_PROMPT,
                                               service_name=key)
        if current_state == NOTFOUND:
            raise errors.CLIError(status_code=-1, reason=current_state)
        if current_state == 'STOP':
            pylogger.info("%s is already stopped" % key)
        else:
            command = '/etc/init.d/%s stop' % key
            out = client_object.connection.\
                request(command, EXPECT_PROMPT).response_data
            pylogger.debug('Command: %s,output: %s' % (command, out))
            current_state = cls._get_service_state(
                client_object, EXPECT_PROMPT, service_name=key)
            if not current_state == STOP:
                current_state = "%s :current State %s" % (key, current_state)
                raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                      reason=current_state)
        return common.status_codes.SUCCESS

    @classmethod
    def _start_service(cls, client_object, key=None):
        current_state = cls._get_service_state(client_object, EXPECT_PROMPT,
                                               service_name=key)
        if current_state == NOTFOUND:
            raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                  reason=current_state)
        if current_state == START:
            pylogger.info("%s is already started" % key)
        else:
            command = '/etc/init.d/%s start' % key
            out = client_object.connection.\
                request(command, EXPECT_PROMPT).response_data
            pylogger.debug('Command: %s,output: %s' % (command, out))
            current_state = cls._get_service_state(
                client_object, EXPECT_PROMPT, service_name=key)
            if not current_state == START:
                pylogger.error('%s is not started' % key)
                current_state = "%s :current State %s" % (key, current_state)
                raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                      reason=current_state)
        return common.status_codes.SUCCESS
