import vmware.interfaces.router_interface as router_interface


class UbuntuRouterImpl(router_interface.RouterInterface):
    """Router implementation class for linux."""
    QUAGGA_DIR = '/etc/quagga/'
    QUAGGA_DAEMON = '/etc/init.d/quagga'
    DAEMONS = 'daemons'
    DEBIAN = 'debian'
    ZEBRA_DAEMON = 'zebra'
    BGP_DAEMON = 'bgpd'
    OSPF_DAEMON = 'ospfd'
    OSPF6_DAEMON = 'ospf6d'
    RIP_DAEMON = 'ripd'
    RIPNG_DAEMON = 'ripngd'
    BABEL_DAEMON = 'babeld'
    ISIS_DAEMON = 'isisd'
    CONF_FILE_SUFFIX = '.conf'
    # All configuration file names follow the format:
    # "<quagga_dir>/<daemonname>.conf"
    DAEMONS_FILE = '%s%s' % (QUAGGA_DIR, DAEMONS)
    ZEBRA_CONF_FILE = '%s%s%s' % (QUAGGA_DIR, ZEBRA_DAEMON, CONF_FILE_SUFFIX)
    BGP_CONF_FILE = '%s%s%s' % (QUAGGA_DIR, ZEBRA_DAEMON, CONF_FILE_SUFFIX)
    DAEMON_FILE_DICT = {ZEBRA_DAEMON: ZEBRA_CONF_FILE,
                        BGP_DAEMON: BGP_CONF_FILE}
    ENABLE = 'yes'
    DISABLE = 'no'
    START = 'start'
    STOP = 'stop'
    RESTART = 'restart'
    DEFAULT_HOSTNAME = 'quagga'
    DEFAULT_PASSWORD = 'default'
    DEFAULT_EN_PASSWORD = 'default'

    # TODO(dbadiani): Use restart_service method implemented in
    # pylib/vmware/linux/cmd/linux_service_impl.py
    @classmethod
    def _restart_quagga(cls, client_object):
        cmd = '%s %s' % (cls.QUAGGA_DAEMON, cls.RESTART)
        return client_object.connection.request(cmd)

    @classmethod
    def _enable_daemon(cls, client_object, daemon=None, content=None):
        """
        Enable a daemon on quagga based router.
        Steps to enable:
            1. Set '<daemonname>=yes' in /etc/quagga/daemons
            2. Create a '<daemonname>.conf' config file in /etc/quagga/
            3. Restart quagga daemon using '/etc/init.d/quagga restart'
        """
        if daemon is None:
            raise ValueError("Must provide a daemon to enable. Provided: %r" %
                             daemon)
        if content is None:
            content = ('hostname %s\npassword %s\nenable password %s' %
                       (cls.DEFAULT_HOSTNAME, cls.DEFAULT_PASSWORD,
                        cls.DEFAULT_EN_PASSWORD))
        # TODO(dbadiani): Need to handle the scenario where an enable request
        # is made on an already 'enabled' daemon.
        daemon_regex = "%s=%s" % (daemon, cls.DISABLE)
        enable_daemon = "%s=%s" % (daemon, cls.ENABLE)
        client_object.replace_regex_in_file(path=cls.DAEMONS_FILE,
                                            find=daemon_regex,
                                            replace=enable_daemon)
        client_object.append_file(content=content,
                                  path=cls.DAEMON_FILE_DICT[daemon])
        # TODO(dbadiani): Add status checking here.
        cls._restart_quagga(client_object)

    @classmethod
    def _disable_daemon(cls, client_object, daemon=None, clear_config=False):
        """ Disable the daemon in Quagga system """
        if daemon is None:
            raise ValueError("Must provide a daemon to disable. Provided: %r" %
                             daemon)
        # TODO(dbadiani): Need to handle the scenario where a disable request
        # is made on an already 'disabled' daemon.
        daemon_regex = "%s=%s" % (daemon, cls.ENABLE)
        disable_daemon = "%s=%s" % (daemon, cls.DISABLE)
        client_object.replace_regex_in_file(path=cls.DAEMONS_FILE,
                                            find=daemon_regex,
                                            replace=disable_daemon)
        if clear_config:
            path = cls.DAEMON_FILE_DICT[daemon]
            client_object.empty_file_contents(path=path)
        # TODO(dbadiani): Add status checking here.
        cls._restart_quagga(client_object)

    @classmethod
    def _configure_interface(cls, client_object, interface_name=None,
                             ip_address=None, cidr=None, update=False):
        """
        Configure IP address on the given interface of the router
        """
        if None in (interface_name, ip_address, cidr):
            raise ValueError("Must provide valid values for interface name, IP"
                             "and CIDR. Received: [%r, %r, %r]" %
                             (interface_name, ip_address, cidr))
        interface_ip = "%s/%s" % (ip_address, cidr)
        ip_content = ("interface %s\n  ip address %s" % (interface_name,
                                                         interface_ip))
        client_object.append_file(content=ip_content, path=cls.ZEBRA_CONF_FILE)

    @classmethod
    def enable_routing(cls, client_object, hostname=None, password=None,
                       en_password=None):
        """
        Enable the 'zebra' daemon which is the core routing daemon for quagga
        """
        cls._enable_daemon(client_object, daemon=cls.ZEBRA_DAEMON)

    @classmethod
    def enable_bgp(cls, client_object):
        """
        Enable the 'bgpd' daemon to configure bgp
        """
        cls._enable_daemon(client_object, daemon=cls.BGP_DAEMON)

    @classmethod
    def disable_routing(cls, client_object, clear_config=False):
        """
        Disable the 'zebra' daemon which is the core routing daemon for quagga
        """
        cls._disable_daemon(client_object, daemon=cls.ZEBRA_DAEMON,
                            clear_config=clear_config)

    @classmethod
    def disable_bgp(cls, client_object, clear_config=False):
        """
        Disable the 'bgpd' daemon to configure bgp
        """
        cls._disable_daemon(client_object, cls.BGP_DAEMON,
                            clear_config=clear_config)
