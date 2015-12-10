import vmware.interfaces.adapter_interface as adapter_interface
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


class ESX55AdapterImpl(adapter_interface.AdapterInterface):

    @classmethod
    def enable_vmotion(cls, client_object, enable=None):
        """
        Enables or disables vmotion

        @type client_object: VmknicAPIClient instance
        @param client_object: VmknicAPIClient instance
        @type enable: bool
        @param enable: Flag to specify if vmotion is enabled

        @rtype: NoneType
        @return: None
        """
        host_mor = client_object.parent.get_host_mor()
        vmotion_sys = host_mor.configManager.vmotionSystem
        if enable is True:
            try:
                vmotion_sys.SelectVnic(client_object.name)
            except Exception as e:
                raise Exception("Could not select vnic for vmotion")
        elif enable is False:
            try:
                vmotion_sys.DeselectVnic()
            except Exception as e:
                raise Exception("Could not deselect vnic", e)
        else:
            raise Exception("Unexpected data for param enable = %r, "
                            "boolean expected" % enable)

    @classmethod
    def get_external_id(cls, client_object):
        host_mor = client_object.parent.get_host_mor()
        if not host_mor:
            raise RuntimeError(
                "Failed to get host's managed object reference of %r" %
                client_object.parent.ip)
        vnics = host_mor.configManager.networkSystem.networkInfo.vnic
        for vnic in vnics:
            if vnic.device == client_object.name:
                external_id = vnic.spec.externalId
                if not external_id:
                    pylogger.warn("External Id for %r is not set on %r" %
                                  (client_object.name,
                                   client_object.parent.ip))
                return external_id
        raise RuntimeError("%r not found on %r" %
                           (client_object.name, client_object.ip))
