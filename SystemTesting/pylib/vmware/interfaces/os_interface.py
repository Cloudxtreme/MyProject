"""Interface class to implement OS filesystem related operations."""


class OSInterface(object):

    @classmethod
    def empty_file_contents(cls, client_object, path=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def append_file(cls, client_object, path=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def replace_regex_in_file(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def ip_route(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def configure_arp_entry(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_tcp_connection_count(cls, client_object, ip_address=None,
                                 port=None, connection_states=None,
                                 keywords=None, **kwargs):
        """
        Returns the tcp connection count using netstat command matching the
        given parameters.

        @type ip_address: string
        @param ip_address: Check connection to this IP address.
        @type port: integer
        @param port: Check connection state to this port number.
        @type connection_states: list
        @param connection_states: Any list of states from
            constants.TCPConnectionState.STATES.
        @type keywords: list
        @param keywords: List of keywords to grep.
        @rtype: dictionary
        @return: {'result_count': <Number of matching connections>}
        """
        raise NotImplementedError

    @classmethod
    def get_os_info(cls, client_object, **kwargs):
        """
        Interface to fetch all OS related information of any
        virtual machine
        """
        raise NotImplementedError

    @classmethod
    def get_license_string(cls, client_object, **kwargs):
        """
        Interface to fetch the License agreement information from NSXEdge
        """
        raise NotImplementedError

    @classmethod
    def get_all_supported_commands_enable_mode(
            cls, client_object, **kwargs):
        """
        Interface to login to NSXEdge in admin mode and fetch the list
        of all supported commands
        """
        raise NotImplementedError

    @classmethod
    def get_all_supported_commands_admin_mode(
            cls, client_object, **kwargs):
        """
        Interface to login to NSXEdge in admin mode and fetch the list
        of all supported commands
        """
        raise NotImplementedError

    @classmethod
    def get_all_supported_commands_configure_mode(
            cls, client_object, **kwargs):
        """
        Interface to login to NSXEdge in configure terminal mode and
        fetch the list of all supported commands
        """
        raise NotImplementedError

    @classmethod
    def start_ncat_server(cls, client_object, **kwargs):
        """Starts an ncat listening process"""
        raise NotImplementedError

    @classmethod
    def start_netcat_server(cls, client_object, **kwargs):
        """Starts a netcat listening process"""
        raise NotImplementedError

    @classmethod
    def set_hostname(cls, client_object, hostname=None, **kwargs):
        """Interface to set hostname"""
        raise NotImplementedError

    @classmethod
    def read_hostname(cls, client_object, **kwargs):
        """Interface to get hostname"""
        raise NotImplementedError
