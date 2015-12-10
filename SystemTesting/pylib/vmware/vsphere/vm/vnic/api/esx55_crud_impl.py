import vmware.common.global_config as global_config
import vmware.interfaces.crud_interface as crud_interface
import vmware.vsphere.vm.vnic.api.esx55_adapter_impl as esx55_adapter_impl

pylogger = global_config.pylogger
ESX55AdapterImpl = esx55_adapter_impl.ESX55AdapterImpl


class ESX55CRUDImpl(crud_interface.CRUDInterface):

    @classmethod
    def _get_device_spec(cls, client_object):
        vm_mor = client_object.parent.get_api()
        mac_address = client_object.adapter_mac
        if not mac_address:
            raise Exception("Can not get device spec, mac address is None")
        devices = vm_mor.config.hardware.device
        for device in devices:
            if hasattr(device, 'macAddress'):
                if device.macAddress == mac_address:
                    return device
        raise Exception("No device found matching mac: %r" % mac_address)

    @classmethod
    def get_uuid(cls, client_object):
        device = cls._get_device_spec(client_object)
        # ESX_6.0 : In esx6.0 externalId is an attribute
        # of device and since we have not ported
        # pylib for esx 6.0 this check needs to be in place
        # bug 1438170
        if hasattr(device, 'externalId'):
            pylogger.debug("(XXX) Returning device.externalId %s (meant for "
                           "esx6.0) from esx55_crud_impl." % device.externalId)
            if device.externalId is not None:
                return device.externalId
        for item in device.dynamicProperty:
            if item.name == '__externalId__':
                return item.val

    @classmethod
    def read(cls, client_object, id_=None, read=None):
        _ = read
        response_data = {'status_code': 404}
        ret = {'response_data': response_data}
        mac = ESX55AdapterImpl.get_adapter_mac(client_object)
        if not mac:
            pylogger.warning("No MAC address found for vnic %r" % id_)
            return ret
        ip = ESX55AdapterImpl.get_adapter_ip(client_object)
        ret['response_data']['status_code'] = 201
        ret['mac'] = mac
        ret['ip'] = ip
        return ret
