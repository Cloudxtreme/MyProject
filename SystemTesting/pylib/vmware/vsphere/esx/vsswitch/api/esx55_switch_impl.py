import vmware.interfaces.switch_interface as switch_interface
import vmware.common.global_config as global_config

import pyVmomi as pyVmomi

vim = pyVmomi.vim
pylogger = global_config.pylogger


class ESX55SwitchImpl(switch_interface.SwitchInterface):

    @classmethod
    def remove_uplink(cls, client_object, uplink=None):
        """
        Removes the uplink from the vswitch.

        @type client_object: VSSwitchAPIClient instance
        @param client_object: VSSwitchAPIClient instance

        @type uplink: str
        @param uplink: Name of the uplink to be removed

        @rtype: NoneType
        @return: None
        """
        network_sys = client_object.parent.get_network_system()
        for switch in network_sys.networkInfo.vswitch:
            if switch.name == client_object.name:
                host_spec = switch.spec
                # bridge has to be Bond bridge or Simple bridge
                bridge_spec = switch.spec.bridge
                pnic = []
                if(isinstance(bridge_spec, vim.host.VirtualSwitch.AutoBridge)):
                    pnic.append(uplink)
                    bridge_spec.excludedNicDevice = pnic
                else:
                    for nic in bridge_spec.nicDevice:
                        pnic.append(nic)
                    pnic.remove(uplink)
                    bridge_spec.nicDevice = pnic
                host_spec.bridge = bridge_spec
                network_sys.UpdateVirtualSwitch(
                    client_object.name,
                    host_spec)
