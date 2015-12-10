import vmware.common as common
import vmware.common.global_config as global_config
import vmware.interfaces.processes_interface as processes_interface

pylogger = global_config.pylogger


class LinuxProcessesImpl(processes_interface.ProcessesInterface):
    RUNNING = 'Running'
    NOT_RUNNING = 'Not running'

    @classmethod
    def kill_processes_by_name(cls, client_object, options=None,
                               process_name=None):
        """
        Kill all processes by name
        This uses the 'pkill' command, so as long as that is available this
        should work

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host
        @type options: string
        @param options: options for the pkill command
        @type process_name: string
        @param process_name: The name of the process to be killed
        @rtype: status_code
        @return: SUCCESS or FAILURE
        """
        if options:
            command = 'pkill %s %s' % (options, process_name)
        else:
            command = 'pkill %s' % process_name

        try:
            result = client_object.connection.request(command)
        except Exception, error:
            pylogger.exception(error)
            return common.status_codes.FAILURE

        rows = result.response_data.splitlines()

        if len(rows) == 0:
            pylogger.debug("No commands killed")
        else:
            pylogger.debug("%s commands killed" % len(rows))

        return common.status_codes.SUCCESS

    @classmethod
    def get_pid(cls, client_object, process_name=None, get_pid=None,
                strict=None):
        """
        Returns the process id of the process.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type process_name: str
        @param process_name: Name of the process whose PID is to be determined.
        @type get_pid: dict
        @param get_pid: VDNet artifact, passed in by the perl layer but not
            being used here.
        @type strict: bool
        @param strict: Flag to indicate whether an exception should be raised
            or not if the process does not exist.
        @rtype: dict
        """
        _ = get_pid
        cmd = 'pidof %s' % process_name
        return {'pid': client_object.connection.request(
            cmd, strict=strict).response_data.strip()}

    @classmethod
    def get_process_status(cls, client_object, process_name=None,
                           get_process_status=None):
        """
        Returns the status of the process.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type process_name: str
        @param process_name: Name of the process whose PID is to be determined.
        @type get_process_status: dict
        @param get_process_status: VDNet artifact, passed in by the perl
            layer but not being used here.
        @rtype: dict
        """
        _ = get_process_status
        pid = cls.get_pid(
            client_object, process_name=process_name,
            strict=False)['pid']
        if not pid:
            return {'status': cls.NOT_RUNNING}
        return {'status': cls.RUNNING}
