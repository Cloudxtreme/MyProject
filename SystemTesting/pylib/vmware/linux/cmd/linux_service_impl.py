import vmware.common as common
import vmware.common.constants as constants
import vmware.common.errors as errors
import vmware.common.global_config as global_config
import vmware.interfaces.service_interface as service_interface
import vmware.schema.service_status_schema as service_status_schema


log = lambda: global_config.log()
pylogger = global_config.pylogger


class LinuxServiceImpl(service_interface.ServiceInterface):

    @classmethod
    def start_service(cls, client_object, service_name=None, strict=None):
        """
        Starts a service with the given name.

        @type name: str
        @param name: Name of the service to be started.
        @type strict: bool
        @param strict: If set to 1/True, then exception will
            be raised incase of errors. If set to
            0/False, then exception will be discarded. default
            value is set to enabled.
        @return: Any string from constants.Service.
        """
        if strict is None:
            strict = True
        current_state = cls.get_individual_service_status(
            client_object, service_name)
        if current_state == constants.Service.UNKNOWN:
            raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                  reason=current_state)
        if current_state == constants.Service.STARTED:
            pylogger.info("%s is already started" % service_name)
            error_reason = ("%s is found started before"
                            " starting the service." % service_name)
            if strict:
                raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                      reason=error_reason)
            else:
                return current_state
        else:
            command = constants.Service.SERVICE_CMD % (service_name,
                                                       constants.Service.START)
            out = client_object.connection.\
                request(command).response_data
            pylogger.debug(out)
            current_state = cls.get_individual_service_status(client_object,
                                                              service_name)
            if not current_state == constants.Service.STARTED:
                # To ensure that process is started state
                pylogger.error('%s is not started' % service_name)
                current_state = "% is in %s state, expected it to be in %s " \
                                % (service_name, current_state,
                                   constants.Service.STARTED)
                raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                      reason=current_state)

    @classmethod
    def restart_service(cls, client_object, service_name=None, strict=None):
        """
        Restarts the service with the given name.

        @type name: str
        @param name: Name of the service to be restarted.
        @type strict: bool
        @param strict: If set to 1/True, then exception will
            be raised incase of errors. If set to
            0/False, then exception will be discarded. default
            value is set to enabled.
        """
        current_state = cls.get_individual_service_status(
            client_object, service_name)
        if current_state == constants.Service.UNKNOWN:
            raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                  reason=current_state)
        command = constants.Service.SERVICE_CMD % (service_name,
                                                   constants.Service.RESTART)
        out = client_object.connection.\
            request(command).response_data
        pylogger.debug(out)
        current_state = cls.get_individual_service_status(client_object,
                                                          service_name)
        if not current_state == constants.Service.STARTED:
            # Final State is started
            current_state = "% is in %s state, expected it to be in %s "\
                            % (service_name, current_state,
                               constants.Service.STARTED)
            raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                  reason=current_state)
        pylogger.info('%s is restarted' % service_name)

    @classmethod
    def stop_service(cls, client_object, service_name=None, strict=None):
        """
        Stops the service with the given name.

        @type name: str
        @param name: Name of the service to be stopped.
        @type strict: bool
        @param strict: If set to 1/True, then exception will
            be raised incase of errors. If set to
            0/False, then exception will be discarded. default
            value is set to enabled.
        @return: Any string from constants.Service.
        """
        if strict is None:
            strict = True
        current_state = cls.get_individual_service_status(
            client_object, service_name)
        if current_state == constants.Service.UNKNOWN:
            raise errors.CLIError(status_code=-1, reason=current_state)
        if current_state == constants.Service.STOPPED:
            error_reason = "%s is found stopped before" \
                           " stopping the service." % service_name
            if strict:
                raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                      reason=error_reason)
            else:
                return current_state
        else:
            command = constants.Service.SERVICE_CMD % (service_name,
                                                       constants.Service.STOP)
            out = client_object.connection.\
                request(command).response_data
            pylogger.debug(out)
            current_state = cls.get_individual_service_status(client_object,
                                                              service_name)
            if not current_state == constants.Service.STOPPED:
                # To ensure that process is stopped state
                current_state = "% is in %s state, expected it to be in %s "\
                                % (service_name, current_state,
                                   constants.Service.STOPPED)
                raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                      reason=current_state)

    @classmethod
    def uninstall_service(cls, client_object, service_name=None):
        """Interface to uninstall the service."""
        raise NotImplementedError

    @classmethod
    def update_service_policy(cls, client_object, service_name=None,
                              policy=None):
        """Interface to update activation policy of the service."""
        raise NotImplementedError

    @classmethod
    def configure_service_state(cls, client_object, service_name=None,
                                state=None, strict=None):
        pylogger.info('Service Name: %s,Operation: %s'
                      % (service_name, state))
        if state == constants.Service.START:
            cls.start_service(client_object, service_name=service_name,
                              strict=strict)
        elif state == constants.Service.STOP:
            cls.stop_service(client_object, service_name=service_name,
                             strict=strict)
        elif state == constants.Service.RESTART:
            cls.restart_service(client_object, service_name=service_name,
                                strict=strict)
        elif state == constants.Service.KILL:
            cls.kill_service(client_object, service_name=service_name,
                             strict=strict)
        else:
            raise ValueError("Received incorrect service state")

    @classmethod
    def refresh_services(cls, client_object):
        """Interface to refresh service information and settings."""
        raise NotImplementedError

    @classmethod
    def is_service_running(cls, client_object, service_name=None):
        res = client_object.get_individual_service_status(
            service_name=service_name)
        return res

    @classmethod
    def kill_service(cls, client_object, service_name=None, strict=None):
        if strict is None:
            strict = True
        current_state = cls.get_individual_service_status(
            client_object, service_name)
        if current_state == constants.Service.UNKNOWN:
            current_state = "%s :current State %s"\
                            % (service_name, current_state)
            raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                  reason=current_state)
        if current_state == constants.Service.STOPPED:
            # assuming kill will be only used for
            # abrupt stop
            error_reason = "%s :current State %s"\
                           % (service_name, current_state)
            if strict:
                raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                      reason=error_reason)
            else:
                return current_state
        else:
            pid_before = client_object.connection.\
                request("pgrep %s" % service_name)
            command = 'pkill %s' % service_name
            out = client_object.connection.\
                request(command).response_data
            pylogger.debug(out)
            pid_after = client_object.connection.\
                request("pgrep %s" % service_name)
            # verifying whether process id is changed because
            # watchdog restarts the process for NSX services
            # post abrupt stop
            if pid_before == pid_after:
                raise errors.\
                    CLIError(status_code=common.status_codes.FAILURE,
                             reason=current_state)
            pylogger.info('%s is killed' % service_name)

    @classmethod
    def get_individual_service_status(cls, client_object, service_name=None,
                                      expected_state=None):
        """
        Returns the status of the given service.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type service_name: str
        @param service_name: Service name for which the status is queried.
        @rtype: string
        @return: Any string from constants.Service.
        """
        command = constants.Service.SERVICE_CMD % (service_name,
                                                   constants.Service.STATUS)
        # When we do get daemon status it doesn't return 1
        # as status code, it returns 3
        out = client_object.connection.\
            request(command, strict=False).response_data
        pylogger.debug(out)
        if (((constants.Service.STATUS_RUNNING in out) or
             (constants.Service.ALREADY_RUNNING in out)) and
           (constants.Service.STATUS_NOT_RUNNING not in out)):
            current_state = constants.Service.STARTED
        elif constants.Service.STATUS_NOT_RUNNING in out:
            current_state = constants.Service.STOPPED
        elif constants.Service.ALREADY_RUNNING in out:
            current_state = constants.Service.STARTED
        else:
            current_state = constants.Service.UNKNOWN
        if expected_state is not None and current_state != expected_state:
            pylogger.error("Service %s: expected_state=%s, current_state=%s" %
                           (service_name, expected_state, current_state))
            raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                  reason=current_state)
        pylogger.debug('%s status is %s' % (service_name, current_state))
        return current_state

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
            py_dict = {}
            py_dict['service_name'] = service
            py_dict['service_status'] = client_object.\
                get_individual_service_status(service_name=service)
            table.append(py_dict)
        return service_status_schema.ServiceStatusTableSchema(
            py_dict={'table': table})
