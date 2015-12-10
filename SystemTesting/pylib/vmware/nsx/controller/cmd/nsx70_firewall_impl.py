import vmware.common.global_config as global_config
import vmware.linux.cmd.linux_firewall_impl as linux_firewall_impl

pylogger = global_config.pylogger


class NSX70FirewallImpl(linux_firewall_impl.LinuxFirewallImpl):

    @classmethod
    def network_partitioning(cls, client_object, ip_address=None,
                             protocol='tcp', port=None, operation=None):
        """
        Configure network partitioning by ip, port, protocol

        @type ip_address: String
        @param ip_address: ip address of target that you want isolation,
                           could be controller_ip, manager_ip... ip_address
                           can be an array or an scalar
        @type protocol: String
        @param protocol: tcp/udp
        @type port: String
        @param port: port number
        @type operation: String
        @param operation: set/reset
        @rtype: Boolean
        @return: True/False
        """
        endpoint = ''
        if operation == 'set':
            if port and ip_address:
                if type(ip_address) is list:
                    for ip in ip_address:
                        endpoint += "iptables -I INPUT -s %s -p %s --sport " \
                                    "%s -j DROP; iptables -I OUTPUT -d " \
                                    "%s -p %s --dport %s -j DROP; " \
                                    % (ip, protocol, port, ip, protocol, port)
                else:
                    endpoint = "iptables -I INPUT -s %s -p %s --sport %s " \
                               "-j DROP; iptables -I OUTPUT -d %s -p %s " \
                               "--dport %s -j DROP; " \
                               % (ip_address, protocol, port,
                                  ip_address, protocol, port)
            elif port and not ip_address:
                endpoint = "iptables -I INPUT -p %s --sport %s " \
                           "-j DROP; iptables -I OUTPUT -p %s " \
                           "--dport %s -j DROP" \
                           % (protocol, port, protocol, port)
            else:
                if type(ip_address) is list:
                    for ip in ip_address:
                        endpoint += "iptables -I INPUT -s %s -j DROP; " \
                                    "iptables -I OUTPUT -d %s -j DROP; " \
                                    % (ip, ip)
                else:
                    endpoint = "iptables -I INPUT -s %s -j DROP; " \
                               "iptables -I OUTPUT -d %s -j DROP; " \
                               % (ip_address, ip_address)
        elif operation == 'reset':
            if port and ip_address:
                if type(ip_address) is list:
                    for ip in ip_address:
                        endpoint += "iptables -D INPUT -s %s -p %s --sport " \
                                    "%s -j DROP; iptables -D OUTPUT -d " \
                                    "%s -p %s --dport %s -j DROP; " \
                                    % (ip, protocol, port, ip, protocol, port)
                else:
                    endpoint = "iptables -D INPUT -s %s -p %s --sport %s " \
                               "-j DROP; iptables -D OUTPUT -d %s -p %s " \
                               "--dport %s -j DROP; " \
                               % (ip_address, protocol, port,
                                  ip_address, protocol, port)
            elif port and not ip_address:
                endpoint = "iptables -D INPUT -p %s --sport %s " \
                           "-j DROP; iptables -D OUTPUT -p %s " \
                           "--dport %s -j DROP" \
                           % (protocol, port, protocol, port)
            else:
                if type(ip_address) is list:
                    for ip in ip_address:
                        endpoint += "iptables -D INPUT -s %s -j DROP; " \
                                    "iptables -D OUTPUT -d %s -j DROP; " \
                                    % (ip, ip)
                else:
                    endpoint = "iptables -D INPUT -s %s -j DROP; " \
                               "iptables -D OUTPUT -d %s -j DROP; " \
                               % (ip_address, ip_address)
        else:
            raise ValueError("Received unknown <%s> network "
                             "partitioning operation"
                             % operation)
            return False
        client_object.connection.request(endpoint)
        return True
