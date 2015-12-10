import mh.lib.netutils as netutils
import vmware.base.port as port
import vmware.nsx.manager.nsxbase as nsxbase


class LogicalRouterPort(nsxbase.NSXBase, port.Port):

    def get_id_(self):
        return self.id_

    def get_lr_port_id(self):
        return self.id_

    def get_ipcidr(self):
        data = self.read(id_=self.id_)
        subnets = data.get('subnets', [])
        if not subnets:
            return
        subnet = subnets[0]
        if 'prefixlen' not in subnet:
            return
        if 'ip_addresses' not in subnet:
            return
        if subnet['ip_addresses']:
            ipcidr = "{}/{}".format(subnet['ip_addresses'][0],
                                    subnet['prefixlen'])
            return ipcidr

    def get_ip(self):
        ipcidr = self.get_ipcidr()
        if ipcidr:
            return netutils.get_ip_net_mask(ipcidr)[0]

    def get_network(self):
        ipcidr = self.get_ipcidr()
        if ipcidr:
            return netutils.get_ip_net_mask(ipcidr)[1]

    def get_netmask(self):
        ipcidr = self.get_ipcidr()
        if ipcidr:
            return netutils.get_ip_net_mask(ipcidr)[2]

    def get_netcidr(self):
        ipcidr = self.get_ipcidr()
        if ipcidr:
            return netutils.ipcidr_to_netcidr(ipcidr)

    def get_mac(self):
        data = self.read(id_=self.id_)
        return data.get('macaddress')
