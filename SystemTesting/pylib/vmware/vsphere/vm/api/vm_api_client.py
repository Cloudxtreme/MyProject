import vmware.vsphere.vsphere_client as vsphere_client
import vmware.vsphere.vm.vm as vm


class VMAPIClient(vm.VM, vsphere_client.VSphereAPIClient):

    def __init__(self, id_, parent=None, host_ip=None):
        super(VMAPIClient, self).__init__(parent=parent)
        self.id_ = id_
        self.name = self.get_vm_name(id_, host_ip=host_ip)

    def get_vm_name(self, id_, host_ip=None):
        if host_ip:
            host_mor = self.parent.get_mor(host_ip)
        else:
            host_mor = self.parent.host_mor
        for vm in host_mor.vm:
            if vm._moId == id_:
                return vm.name
        raise Exception("%s vm name not found" % id_)
