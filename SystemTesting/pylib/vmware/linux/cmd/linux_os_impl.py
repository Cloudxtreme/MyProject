import mh.lib.netutils as netutils
import vmware.common as common
import vmware.common.constants as constants
import vmware.common.errors as errors
import vmware.common.global_config as global_config
import vmware.interfaces.os_interface as os_interface
import vmware.utilities.iface as iface

pylogger = global_config.pylogger


class LinuxOSImpl(os_interface.OSInterface):

    @classmethod
    def empty_file_contents(cls, client_object, path=None):
        empty_file_cmd = "> %r" % path
        return client_object.connection.request(empty_file_cmd)

    @classmethod
    def append_file(cls, client_object, content=None, path=None,
                    enable_interpretation=False):
        cmd = ['echo']
        if enable_interpretation:
            cmd.append('-e')
        cmd.append("'%s' >> '%s'" % (content, path))
        echo_cmd = ' '.join(cmd)
        return client_object.connection.request(echo_cmd)

    @classmethod
    def replace_regex_in_file(cls, client_object, path=None,
                              find=None, replace=None, first=False):
        """
        Searches a file and replaces a patten with another pattern.

        @type path: string
        @param path: Path to file to conduct operations on
        @type find: string
        @param find: String to be replaced
        @type replace: string
        @param replace: String to substitute in
        @type first: boolean
        @param first: Determines whether to replace first (true) or all
            occurances
        @rtype: client_object.connection.request
        @return : Command success or failure
        """
        # TODO: mihaid: Remove first and use line_num to be more generic
        out_ops = "-i %s" % path
        if first is False:
            cmd = "sed 's/%s/%s/' -r %s" % (find, replace, out_ops)
            return client_object.connection.request(cmd)
        elif first is True:
            cmd = "sed 0,/%s{s/%s/%s/} %s" % (find, find, replace, out_ops)
            return client_object.connection.request(cmd)

    @classmethod
    def ip_route(cls, client_object, conf_type=None, dst_ip_addr=None,
                 netmask=None, gateway=None, dev=None, src=None, table=None,
                 preference=None):
        if dst_ip_addr is None:
            dst_ip_addr = "default"
        elif "/" not in dst_ip_addr:
            if netmask is None:
                netmask = "255.255.255.0"
            dst_ip_addr = netutils.ip_mask_to_cidr(dst_ip_addr, netmask)
        cmd_parts = ["ip route %s %s" % (conf_type, dst_ip_addr)]
        if gateway:
            if "/" in gateway:
                # Strip /24 from the ipaddr in cidr notation
                gateway = gateway.split("/")[0]
            cmd_parts.append("via %s" % gateway)
        if dev is not None:
            cmd_parts.append("dev %s" % dev)
        if src is not None:
            cmd_parts.append("src %s" % src)
        if table is not None:
            cmd_parts.append("table %s" % table)
        if preference is not None:
            cmd_parts.append("preference %s" % preference)
        cmd = ' '.join(cmd_parts)
        return client_object.connection.request(cmd)

    @classmethod
    def get_tcp_connection_count(cls, client_object, ip_address=None,
                                 port=None, connection_states=None,
                                 keywords=None, **kwargs):
        """
        Returns the tcp connection count using netstat command matching the
        given parameters.

        @type ip_address: string
        @param ip_address: Check connection on this IP address.
        @type port: integer
        @param port: Check connection state on this port number.
        @type connection_states: list
        @param connection_states: Any list of states from
            constants.TCPConnectionState.STATES.
        @type keywords: list
        @param keywords: List of keywords to grep.
        @rtype: dictionary
        @return: {'result_count': <Number of matching connections>}
        """
        for state in connection_states:
            if state not in constants.TCPConnectionState.STATES:
                raise ValueError("Expected connection state not defined: %s" %
                                 state)
        ip_address = ip_address or ""
        port = port or ""
        cmd = 'netstat -anpt | grep %s:%s' % (ip_address, port)
        if keywords:
            cmd = "%s | grep %s" % (cmd, " | grep ".join(keywords))
        cmd = "%s | grep -c -e %s" % (cmd, " -e ".join(connection_states))
        result = client_object.connection.request(cmd, strict=False)
        return {'result_count': int(result.response_data.rstrip())}

    @classmethod
    def add_arp_entry(cls, client_object, destination_ip=None,
                      destination_mac=None):
        """
        Adds static ARP entry on the host.

        @param destination_ip: IP address that would be looked up by the
            system for resolution to hardware address mapping.
        @type destination_ip: str
        @param destination_mac: MAC address for the given static ARP entry.
        @type destination_mac: str
        """
        return client_object.connection.request(
            "arp -s %s %s" % (destination_ip, destination_mac))

    @classmethod
    def delete_arp_entry(cls, client_object, destination_ip=None):
        """
        Removes the specified ARP entry on the host.

        @param destination_ip: IP address or host name for which the ARP entry
            needs to be deleted.
        @type destination_ip: str
        """
        return client_object.connection.request("arp -d %s" % destination_ip)

    @classmethod
    def configure_arp_entry(cls, client_object, operation=None,
                            destination_ip=None, destination_mac=None):
        """
        Configures ARP entry on the host.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type operation: str
        @param operation: Specifies whether to add/delete an ARP entry
        @param destination_ip: IP address or host name for which the ARP entry
            needs to be added/deleted.
        @type destination_ip: str
        @param destination_mac: MAC address for the given ARP entry.
        @type destination_mac: str
        """
        if operation.lower() == 'add':
            return cls.add_arp_entry(
                client_object, destination_ip=destination_ip,
                destination_mac=destination_mac)
        elif operation.lower() == 'delete':
            return cls.delete_arp_entry(
                client_object, destination_ip=destination_ip)
        else:
            raise RuntimeError("Operation %r is not supported for ARP "
                               "entries" % operation)

    @classmethod
    def get_ipcidr(cls, client_object, **iface_kwargs):
        intf = cls.get_iface(client_object, **iface_kwargs)
        if intf and intf.ips:
            return intf.ips[0]

    @classmethod
    def get_iface(cls, client_object, mac=None):
        ipaddr_info = client_object.connection.request(
            "ip addr show").response_data
        ifaces = iface.Iface.from_ip_addr(ipaddr_info)
        for intf in ifaces:
            if intf.mac.lower() == mac.lower():
                return intf
        else:
            pylogger.debug("Interface not found for mac=%s: %s" %
                           (mac, ipaddr_info))

    @classmethod
    def set_hostname(cls, client_object, hostname=None, set_hostname=None):
        """
        Method to set hostname of given host.

        @type hostname: str
        @param hostname: hostname to be modify
        @rtype: status code
        @return: command status code
        """
        _ = set_hostname

        command = 'hostname ' + hostname
        try:
            client_object.connection.request(command)
        except Exception:
            error_msg = (
                "Command [%s] threw exception during execution" % command)
            pylogger.exception(error_msg)
            raise errors.CLIError(status_code=common.status_codes.FAILURE)
        finally:
            client_object.connection.close()

        return common.status_codes.SUCCESS

    @classmethod
    def read_hostname(cls, client_object, read_hostname=None):
        """
        Method returns hostname of given host.

        @rtype: dict
        @return: dictionary having hostname
        """
        _ = read_hostname

        command = 'hostname'
        try:
            raw_payload = client_object.connection.request(
                command).response_data
        except Exception:
            error_msg = (
                "Command [%s] threw exception during execution" % command)
            pylogger.exception(error_msg)
            raise errors.CLIError(status_code=common.status_codes.FAILURE)
        finally:
            client_object.connection.close()

        return {'hostname': raw_payload.strip()}
