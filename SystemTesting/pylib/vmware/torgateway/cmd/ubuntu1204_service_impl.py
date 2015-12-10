import vmware.linux.cmd.linux_service_impl as linux_service_impl


class Ubuntu1204ServiceImpl(linux_service_impl.LinuxServiceImpl):
    OVS_VTEP_BIN = '/usr/share/openvswitch/scripts/ovs-vtep'

    @classmethod
    def start_service(cls, client_object, service_name=None, tor_entries=None):
        """
        Starts ovs vtep service on torgateway.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type service_name: string
        @param service_name: name of service to be started
        @type tor_entries: list
        @param tor_entries: List of torswitch ids
        @rtype: NonType
        @return: None
        """
        if type(tor_entries) is not list:
            raise ValueError('tor_entries has to be an array')
        for tor_entry in tor_entries:
            if 'node_id' not in tor_entry:
                raise ValueError('tor_entries instances must have node_id')
            id = str(tor_entry['node_id'])
            vtep_cmd = cls.OVS_VTEP_BIN
            vtep_cmd = vtep_cmd + " --log-file=/var/log/openvswitch/ovs-vtep-"
            vtep_cmd = vtep_cmd + id + ".log"
            vtep_cmd = vtep_cmd + " --pidfile=/var/run/openvswitch/ovs-vtep-"
            vtep_cmd = vtep_cmd + id + ".pid --detach " + id
            client_object.connection.request(vtep_cmd)

    @classmethod
    def stop_service(cls, client_object, service_name=None, tor_entries=None):
        """
        Stops ovs vtep service on torgateway.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type service_name: string
        @param service_name: name of service to be stopped
        @type tor_entries: list
        @param tor_entries: List of torswitch ids
        @rtype: NonType
        @return: None
        """
        if type(tor_entries) is not list:
            raise ValueError('tor_entries has to be an array')
        for tor_entry in tor_entries:
            if 'node_id' not in tor_entry:
                raise ValueError('tor_entries instances must have node_id')
            id = str(tor_entry['node_id'])
            vtep_cmd = "cat /var/run/openvswitch/ovs-vtep-" + id + ".pid"
            result = client_object.connection.request(vtep_cmd)
            pid = result.response_data
            vtep_cmd = "kill -9 " + str(pid)
            client_object.connection.request(vtep_cmd)
