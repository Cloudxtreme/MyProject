import mh.lib.netutils as netutils
import vmware.base.adapter as adapter
import vmware.common.base_facade as base_facade
import vmware.interfaces.labels as labels


class VIF(adapter.Adapter):

    def get_impl_version(self, execution_type=None, interface=None):
        return "Ubuntu1204"

    def read_adapter_info(self, **kwargs):
        result_dict = {'ip': self.get_ip(),
                       'macaddress': self.get_adapter_mac()}
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = 200
        return result_dict

    @base_facade.auto_resolve(labels.ADAPTER)
    def get_adapter_mac(self, execution_type=None, **kwargs):
        pass

    @base_facade.auto_resolve(labels.ADAPTER)
    def set_mac_address(self, execution_type=None, new_mac=None, **kwargs):
        pass

    @base_facade.auto_resolve(labels.ADAPTER)
    def get_ovs_port(self, execution_type=None, **kwargs):
        pass

    def get_adapter_name(self):
        """
        Returns the name of the vif on the host.
        """
        return self.name

    def get_ipcidr(self):
        return self.parent.get_ipcidr(mac=self.get_adapter_mac())

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
