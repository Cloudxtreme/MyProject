import vmware.common.global_config as global_config
import vmware.interfaces.crud_interface as crud_interface
import vmware.torgateway.tor_port.cmd.default_crud_impl as default_crud_impl

pylogger = global_config.pylogger
DefaultCRUDImpl = default_crud_impl.DefaultCRUDImpl


class Ubuntu1204CRUDImpl(crud_interface.CRUDInterface):

    @classmethod
    def create(cls, client_object, schema):
        """
        Creates an instance of tor switch port.

        @type client_object: BaseClient
        @param client_object: A CMD client that is used to pass the calls to
            the relevant host.
        @type schema: dict
        @param schema: Dict containing the specifications of the port to be
            created. 'name' is a mandatory field for creating a port on the
            parent tor switch.
        """

        return DefaultCRUDImpl.create(client_object, schema)

    @classmethod
    def delete(cls, client_object, name=None):

        return DefaultCRUDImpl.delete(client_object, name)
