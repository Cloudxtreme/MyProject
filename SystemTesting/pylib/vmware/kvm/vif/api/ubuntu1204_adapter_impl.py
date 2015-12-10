import vmware.common.global_config as global_config
import vmware.interfaces.adapter_interface as adapter_interface

pylogger = global_config.pylogger


class Ubuntu1204AdapterImpl(adapter_interface.AdapterInterface):

    @classmethod
    def get_ovs_port(cls, client_object):
        return client_object.vif.ovs_port_name

    @classmethod
    def get_adapter_mac(cls, client_object):
        return str(client_object.vif.MAC)

    @classmethod
    def get_adapter_ip(cls, client_object):
        vm = client_object.parent.vm
        vif = client_object.vif
        ip = vm.get_ip(iface=vif)
        if not ip:
            pylogger.warning('No IP found for iface %r on VM %r on host %r' %
                             (client_object.vif.linux_device, vm.unique_name,
                              client_object.parent.kvm.ip))
        return ip

    @classmethod
    def get_adapter_interface(cls, client_object):
        """
        Returns the name of the Linux interface on the guest VM.
        """
        return client_object.vif.linux_device

    @classmethod
    def set_mac_address(cls, client_object, new_mac=None):
        vif = client_object.vif
        vm = client_object.parent.vm
        old_mac = vif.MAC
        iface = vif.linux_device
        ovs_iface = vif.get_kvm_device()
        kvm_client = client_object.parent.parent
        vm_name = vm.unique_name
        vm_update_cmd = ("ifconfig %s down && ifconfig %s hw ether %s && "
                         "ifconfig %s up" % (iface, iface, new_mac, iface))
        virsh_update_cmd = ("EDITOR='ex' virsh edit %s <<< '%%s/%s/%s/g|"
                            "wq'" % (vm_name, old_mac, new_mac))
        ovs_ext_id_update_cmd = (
            "ovs-vsctl set interface %s external-ids:attached-mac=%s" %
            (ovs_iface, new_mac))
        escaped_new_mac = "'%s'" % "\:".join(new_mac.split(":"))
        ovs_mac_in_use_update_cmd = (
            "ovs-vsctl set interface %s mac_in_use=%s" %
            (ovs_iface, escaped_new_mac))
        if iface == vif.vm.management_vif.linux_device:
            # XXX(salmanm): Changing the management vif's mac address causes
            # VM to lose connectivity. This seems to be a DHCP issue since test
            # VIFs with static IP do not have this problem.
            raise AssertionError("Can not change the management VIF's MAC "
                                 "address of a VM")
        vif_index = vm.VIFs.index(vif)
        try:
            pylogger.debug("Changing MAC address from %r to %r of %r on %r" %
                           (old_mac, new_mac, iface, vm.unique_name))
            client_object.parent.vm.VIFs.remove(vif)
            vm.host.req_call(vm_update_cmd)
            kvm_client.connection.request(virsh_update_cmd)
            kvm_client.connection.request(ovs_ext_id_update_cmd)
            kvm_client.connection.request(ovs_mac_in_use_update_cmd)
            # XXX(salmanm): Right now reconnection to the hosts is causing the
            # VM objects to be recreated every time and so the following is not
            # very helpful.
            vif._mac = new_mac
        finally:
            client_object.parent.vm.VIFs.insert(vif_index, vif)
