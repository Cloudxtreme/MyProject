import vmware.interfaces.crud_interface as crud_interface
import vmware.common.global_config as global_config
import vmware.schema.network_schema as network_schema

pylogger = global_config.pylogger
NetworkSchema = network_schema.NetworkSchema


class ESX55CRUDImpl(crud_interface.CRUDInterface):

    @classmethod
    def read(cls, client_object):
        """
        Returns the properties for the given portgroup.

        @type client_object: client instance
        @param client_object: Portgroup client instance

        @rtype: Portgroup Schema instance
        @return: Returns a Portgroup instance with attributes name,
            vswitchName, vlan_id.

        """
        network_sys = client_object.parent.parent.get_network_system()
        try:
            for pg in network_sys.networkInfo.portgroup:
                if ((pg.spec.name == client_object.name and
                     pg.spec.vswitchName == client_object.parent.name)):
                    return NetworkSchema(name=client_object.name,
                                         vlan=pg.spec.vlanId,
                                         switch=pg.spec.vswitchName)
            raise Exception("Could not find portgroup %s on vswitch %s"
                            % (client_object.name, client_object.parent.name))
        except Exception as e:
            raise Exception(
                "Could not retrieve properties of portgroup", e)

    @classmethod
    def update(cls, client_object, vlan=None):
        """
        Updates the portgroup.

        @type client_object: client instance
        @param client_object: portgroup instance

        @type vlan: int
        @param vlan: Vlan ID

        @rtype: NoneType
        @return: None
        """
        network_sys = client_object.parent.parent.get_network_system()
        for pg in network_sys.networkInfo.portgroup:
            if pg.spec.name == client_object.name:
                pg_spec = pg.spec
                pg_spec.vlanId = vlan
                try:
                    network_sys.UpdatePortGroup(client_object.name, pg_spec)
                    return
                except Exception as e:
                    raise Exception(
                        "Could not set VLAN ID %d on portgroup %s" %
                        (vlan, client_object.name), e)
                pylogger.info(
                    "Successfully set VLAN ID %d on portgroup %s" %
                    (vlan, client_object.name))
        raise Exception("Could not find specified portgroup")
