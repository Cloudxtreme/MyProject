import re
import time
import vmware.interfaces.service_interface as service_interface
import vmware.common as common
import vmware.common.errors as errors
import vmware.common.global_config as global_config
import vmware.schema.service_status_schema as service_status_schema
import vmware.workarounds as workarounds

pylogger = global_config.pylogger
START = 'running'
STOP = 'stopped'
NOTFOUND = 'notfound'
EXPECT_PROMPT = ['bytes*', '>']
SERVICE_CONFIGURATION_RETRY = 3


class NSX70ServiceImpl(service_interface.ServiceInterface):
    """Service related operations."""

    @classmethod
    def configure_service_state(cls, client_object, service_name=None,
                                state=None):
        retry = 0
        while retry < SERVICE_CONFIGURATION_RETRY:
            retry = retry + 1
            pylogger.info("Trial #%s out of %s: %s service %s"
                          % (retry, SERVICE_CONFIGURATION_RETRY,
                             state, service_name))
            status = cls._configure_service_state(
                client_object, service_name=service_name, state=state)
            pylogger.info("Trial #%s out of %s: %s service %s return result %s"
                          % (retry, SERVICE_CONFIGURATION_RETRY,
                             state, service_name, status))
            if status == common.status_codes.SUCCESS:
                return status
        pylogger.error("Failed to %s service %s after %s retries." %
                       (state, service_name, SERVICE_CONFIGURATION_RETRY))
        return status

    @classmethod
    def _configure_service_state(cls, client_object, service_name=None,
                                 state=None):
        if workarounds.nsxcontroller_activate_cluster_workaround.enabled:
            time.sleep(60)

        pylogger.info('Service Name: %s,Operation: %s'
                      % (service_name, state))
        if state == 'start':
            result = cls._start_service(client_object, key=service_name)
        elif state == 'stop':
            result = cls._stop_service(client_object, key=service_name)
        elif state == 'restart':
            result = cls._restart_service(client_object, key=service_name)
        elif state == 'activate' or state == 'deactivate'\
                or state == 'initialize':
            result = cls._control_cluster_service(client_object,
                                                  key=service_name,
                                                  operation=state)
        else:
            raise ValueError("Received incorrect service state")
        return result

    @classmethod
    def _get_service_state(cls, client_object, expect, service_name=None):
        command = 'get service %s' % service_name
        out = client_object.connection.\
            request(command, expect).response_data
        pylogger.debug('Command: %s,output: %s' % (command, out))

        if 'stopped' in out:
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
            command = 'stop service %s' % key
            try:
                out = client_object.connection.\
                    request(command, EXPECT_PROMPT).response_data
            except Exception as e:
                pylogger.warning('%s stop failed due to exception: %s' %
                                 (key, e))
                return common.status_codes.FAILURE
            pylogger.debug('Command: %s,output: %s' % (command, out))
            current_state = cls._get_service_state(
                client_object, EXPECT_PROMPT, service_name=key)
            if not current_state == STOP:
                pylogger.warning("%s is not stopped, its current state is %s" %
                                 (key, current_state))
                return common.status_codes.FAILURE
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
            command = 'start service %s' % key
            try:
                out = client_object.connection.\
                    request(command, EXPECT_PROMPT).response_data
            except Exception as e:
                pylogger.warning('%s start failed due to exception: %s' %
                                 (key, e))
                return common.status_codes.FAILURE
            pylogger.debug('Command: %s,output: %s' % (command, out))
            current_state = cls._get_service_state(
                client_object, EXPECT_PROMPT, service_name=key)
            if not current_state == START:
                pylogger.warning("%s is not started, its current state is %s" %
                                 (key, current_state))
                return common.status_codes.FAILURE
        return common.status_codes.SUCCESS

    @classmethod
    def _restart_service(cls, client_object, key=None):
        current_state = cls._get_service_state(client_object, EXPECT_PROMPT,
                                               service_name=key)
        if current_state == NOTFOUND:
            raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                  reason=current_state)
        command = 'restart service %s' % key
        try:
            out = client_object.connection.\
                request(command, EXPECT_PROMPT).response_data
        except Exception as e:
            pylogger.warning('%s restart failed due to exception: %s' %
                             (key, e))
            return common.status_codes.FAILURE
        pylogger.debug('Command: %s,output: %s' % (command, out))
        current_state = cls._get_service_state(client_object, EXPECT_PROMPT,
                                               service_name=key)
        if not current_state == START:
            pylogger.warning('%s is not restarted, its currect state is' %
                             (key, current_state))
            return common.status_codes.FAILURE
        pylogger.info('%s is restarted' % key)
        return common.status_codes.SUCCESS

    @classmethod
    def _control_cluster_service(cls, client_object, key=None, operation=None):
        """TODO(yanxuez): check service state before operation"""
        command = '%s %s' % (operation, key)
        try:
            out = client_object.connection.\
                request(command, EXPECT_PROMPT).response_data
        except Exception as e:
            pylogger.warning('%s %s failed due to exception: %s' %
                             (operation, key, e))
            return common.status_codes.FAILURE
        pylogger.debug('Command: %s,output: %s' % (command, out))
        """TODO(yanxuez): verify service state after operation"""
        if (re.findall(common.status_codes.FAILURE, out, re.I)):
            pylogger.warning('%s %s failed due to %s' % (operation, key, out))
            return common.status_codes.FAILURE.upper()
        else:
            pylogger.info('%s %s successfully' % (operation, key))
            return common.status_codes.SUCCESS.upper()

    @classmethod
    def get_service_status(cls, client_object, service_names=None, **kwargs):
        """
        Returns the status of the given services.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type service_names: list
        @param service_names: List of service names for which the status is
            queried.
        @rtype: service_status_schema.ServiceStatusTableSchema
        @return: Returns the ServiceStatusTableSchema object.
        """
        table = []
        for service in service_names:
            pylogger.debug('Getting service status for service_name %s :'
                           % service)
            py_dict = {'service_name': service,
                       'service_status': cls._get_service_state(
                           client_object, EXPECT_PROMPT,
                           service_name=service)}
            table.append(py_dict)
        return service_status_schema.ServiceStatusTableSchema(
            py_dict={'table': table})
