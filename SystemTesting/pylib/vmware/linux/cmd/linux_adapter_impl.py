import pprint

import vmware.interfaces.adapter_interface as adapter_interface
import vmware.common.global_config as global_config
import vmware.common.timeouts as timeouts
import vmware.common.utilities as utilities

pylogger = global_config.pylogger


class LinuxAdapterImpl(adapter_interface.AdapterInterface):

    @classmethod
    def set_adapter_mtu(cls, client_object, adapter_name=None, value=None):
        mtu_cmd = "ifconfig %s mtu %s" % (adapter_name, value)
        return client_object.connection.request(mtu_cmd)

    # XXX(mbindal) change the method name to get_adapters_info.
    @classmethod
    def get_adapter_info(cls, client_object):
        """
        Returns parsed data as dictionary for all interfaces that exists on the
        host.
        """
        cmd = 'ifconfig -a'
        raw_data = client_object.connection.request(cmd).response_data
        parsed_data = {'table': utilities.parse_ifconfig_output(raw_data)}
        pylogger.debug('Parsed ifconfig data:\n%s' %
                       pprint.pformat(parsed_data))
        return parsed_data

    @classmethod
    def get_single_adapter_info(cls, client_object, adapter_ip=None,
                                adapter_name=None,
                                get_single_adapter_info=None,
                                timeout=None):
        """
        Discover an adapter based on adapter Name or adapter IP.
        The method will return a dictionary containing the IP, Name and Mac
        address of the discovered adapter in a format that could be consumed
        by the underlying VDNet framework for post processing.
        Return data will be:
        {
            'name': 'eth0',
            'ip': '192.168.9.1',
            'mac': '00:0C:29:92:73:42',
            'response_data': {'status_code': '201'}
        }
        @type client_object: BaseClient
        @param client_object: A Connection client that is used to pass the
            calls to the relevant host.
        @type adapter_ip: str
        @param adapter_ip: ip address of the adapter
        @type adapter_name: str
        @param adapter_name: name of the adapter
        @type get_single_adapter_info: list
        @param get_single_adapter_info: A list of dicts. It is not used.
        @type timeout: integer
        @param timeout: Time to wait for an adapter to acquire an IP.
        @rtype: dict
        @return: Dictionary containing information about the discovered
            adapter.
        """
        _ = get_single_adapter_info
        if timeout and not adapter_name:
            raise AssertionError('In order to wait for an adapter to obtain '
                                 'IP, adapter name is required, got name: %r '
                                 % adapter_name)

        def exc_handler(exc):
            pylogger.debug("IP on adapter checker returned "
                           "exception: %s" % exc)

        def ip_checker(result):
            if 'ip' in result and result['ip']:
                return True
            return False

        if timeout:
            pylogger.debug("Checking for ip address on interface %r ..." %
                           adapter_name)
            kwargs = {'adapter_name': adapter_name,
                      'adapter_ip': adapter_ip}
            timeouts.dhcp_ip_timeout = timeouts.Timeout(
                int(timeout), "Time to Wait for an adapter to get a DHCP IP ",
                "Delay for an adapter to obtain an IP from a DHCP Server")
            result = timeouts.dhcp_ip_timeout.wait_until(
                cls._discover_adapter, args=[client_object], kwargs=kwargs,
                checker=ip_checker, exc_handler=exc_handler,
                logger=pylogger)
            if 'ip' not in result or not result['ip']:
                raise AssertionError('Could not find IP on adapter %r on VM %r'
                                     % (adapter_name, client_object.ip))
            return result
        else:
            return cls._discover_adapter(client_object,
                                         adapter_name=adapter_name,
                                         adapter_ip=adapter_ip)

    @classmethod
    def _discover_adapter(cls, client_object, adapter_name=None,
                          adapter_ip=None):
        response_data = {'status_code': 404}
        ret = {'response_data': response_data}
        if not adapter_ip and not adapter_name:
            raise AssertionError('Adapter IP or Name must be specified to '
                                 'discover an adapter')
        if adapter_ip and adapter_name:
            raise AssertionError('Discovery of adapter requires adapter name '
                                 'or IP, got both: name: %r, IP: %r ' %
                                 (adapter_ip, adapter_name))
        # Get adapter information.
        result = cls.get_adapter_info(client_object)
        # Parse gathered data.
        for record in result['table']:
            if (record['dev'] == adapter_name) or (record['ip'] == adapter_ip):
                ret['name'] = record['dev']
                ret['ip'] = record['ip']
                ret['mac'] = record['mac']
                ret['response_data']['status_code'] = 201
                break
        else:
            pylogger.debug('Did not find any adapter with the name %r and IP '
                           '%r on %r' % (adapter_name, adapter_ip,
                                         client_object.ip))
        return ret
