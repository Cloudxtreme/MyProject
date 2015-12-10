import mh.lib.netutils as netutils
import vmware.base.adapter as adapter


class Vnic(adapter.Adapter):

    def get_impl_version(self, execution_type=None, interface=None):
        return "ESX55"

    def read_adapter_info(self, **kwargs):
        result_dict = {'ip': self.adapter_ip, 'macaddress': self.adapter_mac}
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = 200
        return result_dict

    def get_ipcidr(self):
        return self.parent.get_ipcidr(mac=self.adapter_mac)

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
