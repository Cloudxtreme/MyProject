import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.linux.cmd.linux_os_impl as linux_os_impl

pylogger = global_config.pylogger


class DefaultOSImpl(linux_os_impl.LinuxOSImpl):

    # NOTE: Different netcat versions have different flags/usage. Choosing this
    # as the default version. In case some templates have a different version,
    # they should override this method in corresponding impl file for that OS.
    @classmethod
    def start_netcat_server(cls, client_object, ip=None, port=None, udp=None,
                            wait=None):
        """
        Starts a listening process for inbound connections using netcat.

        @type client_object: VMCMDClient
        @param client_object: Client object
        @type ip: string
        @param ip: IP address to bind the listening process.
        @type port: integer
        @param port: port to start the listening on.
        @type udp: boolean
        @param udp: Use UDP instead of the default option of TCP
        @type wait: boolean
        @param wait: If True, run cmd as blocking call, else as non-blocking
        @rtype: vmware.common.result.Result object
        @return: result object.
        """
        if not port:
            raise ValueError("Missing port number to listen using netcat")
        # Set default behavior to blocking call.
        wait = utilities.get_default(wait, True)
        cmd = 'nc -l'
        if ip:
            cmd = '%s %s' % (cmd, ip)
        cmd = '%s %s' % (cmd, int(port))
        if udp:
            cmd = '%s -u' % cmd
        if not wait:
            cmd = "%s >> /dev/null 2>&1 &" % cmd
        return client_object.connection.request(cmd)
