import vmware.interfaces.crud_interface as crud_interface
import vmware.common.global_config as global_config
import vmware.schema.pool_schema as pool_schema

PoolSchema = pool_schema.PoolSchema
pylogger = global_config.pylogger


class VC55CRUDImpl(crud_interface.CRUDInterface):

    @classmethod
    def read(cls, client_object):
        """
        Reads the resource pool information.

        @type client_object: ResourcePoolAPIClient instance
        @param client_object: ResourcePoolAPIClient instance

        @rtype: PoolSchema instance
        @return: Schema object for resource pool
        """
        vds_mor = client_object.parent.vds_mor
        for pool in vds_mor.networkResourcePool:
            if pool.name == client_object.name:
                return PoolSchema(name=pool.name)

    @classmethod
    def delete(cls, client_object):
        """
        Removes the network resource pool.

        @type client_object: VDSwitchAPIClient instance
        @param client_object: VDSwitchAPIClient instance

        @rtype: NoneType
        @return: None
        """
        vds_mor = client_object.parent.vds_mor
        vds_mor.RemoveNetworkResourcePool([client_object.key])
