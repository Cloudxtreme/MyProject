import vmware.common.global_config as global_config
import vmware.interfaces.crud_interface as crud_interface
import vmware.kvm.vif.api.ubuntu1204_adapter_impl as ubuntu1204_adapter_impl

pylogger = global_config.pylogger
Ubuntu1204AdapterImpl = ubuntu1204_adapter_impl.Ubuntu1204AdapterImpl


class Ubuntu1204CRUDImpl(crud_interface.CRUDInterface):
    """Impl class for VIF related CRUD operations."""

    @classmethod
    def create(cls, client_object, backing=None):
        """
        Method to create a VIF on the vm.

        @param backing: network_label to be used for this vif
        @rtype vif_obj: obj of the newly created vif
        """
        vm = client_object.parent.vm
        pylogger.debug("Calling create on %s with network_label %s" % (vm.name,
                       backing.name))
        bridge = backing.get_bridge()
        return vm.create_vif(bridge)

    @classmethod
    def read(cls, client_object, id_=None, read=None):
        _ = read
        response_data = {'status_code': 404}
        ret = {'response_data': response_data}
        mac = Ubuntu1204AdapterImpl.get_adapter_mac(client_object)
        if not mac:
            pylogger.warning("No MAC address found for vif %r" % id_)
            return ret
        ip = Ubuntu1204AdapterImpl.get_adapter_ip(client_object)
        ret['response_data']['status_code'] = 201
        ret['mac'] = mac
        ret['ip'] = ip
        return ret

    @classmethod
    def update(cls, client_object, schema=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def delete(cls, client_object, permanent=None, unplug=None):
        """
        Deletes this VIF.

        @type permanent: bool
        @param permanent: Flag to permanently remove the VIF.
        @type unplug: bool
        @param unplug: Flag to unplug the VIF from the VM (No underlying
            support as of now)
        """
        return client_object.vif.destroy(permanent=permanent,
                                         unplug=unplug)

    @classmethod
    def get_uuid(cls, client_object):
        return str(client_object.vif.uuid)
