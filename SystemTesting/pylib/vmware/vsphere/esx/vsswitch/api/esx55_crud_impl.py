import vmware.interfaces.crud_interface as crud_interface
import vmware.schema.switch.switch_schema as switch_schema
import vmware.common.global_config as global_config

pylogger = global_config.pylogger
SwitchSchema = switch_schema.SwitchSchema


class ESX55CRUDImpl(crud_interface.CRUDInterface):

    @classmethod
    def read(cls, client_object):
        """
        Reads the properties of a switch.

        @type client_object: VSSwitchAPIClient instance
        @param client_object: VSSwitchAPIClient instance

        @rtype: SwitchSchema instance
        @return: Schema object of type SwitchSchema
        """
        network_sys = client_object.parent.get_network_system()
        for switch in network_sys.networkInfo.vswitch:
            if switch.name == client_object.name:
                nics = []
                if switch.spec.bridge is not None:
                    for nic in switch.spec.bridge.nicDevice:
                        nics.append(nic)
                return SwitchSchema(
                    switch=switch.name,
                    numports=switch.numPorts,
                    numports_available=switch.numPortsAvailable,
                    confports=switch.spec.numPorts,
                    mtu=switch.mtu,
                    uplink=nics)
        raise Exception("Could not read properties of %r"
                        % (client_object.name))
