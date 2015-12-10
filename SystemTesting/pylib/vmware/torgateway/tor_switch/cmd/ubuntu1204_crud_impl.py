import vmware.common.global_config as global_config
import vmware.interfaces.crud_interface as crud_interface
import vmware.torgateway.tor_switch.cmd.default_crud_impl as default_crud_impl

pylogger = global_config.pylogger
DefaultCRUDImpl = default_crud_impl.DefaultCRUDImpl


class DefaultCRUDImpl(crud_interface.CRUDInterface):

    @classmethod
    def create(cls, client_object, schema):
        """
        Creates an instance of tor switch.

        @type client_object: BaseClient
        @param client_object: A CMD client that is used to pass the calls to
            the relevant host.
        @type schema: dict
        @param schema: Dict containing the specifications of the swotch to be
            created. 'name' is a mandatory field for creating a switch on the
            parent tor gateway.
        """

        return DefaultCRUDImpl.create(client_object, schema)

    @classmethod
    def delete(cls, client_object, id=None):
        return DefaultCRUDImpl.delete(client_object, id)

    @classmethod
    def get_id(cls, client_object):
        return DefaultCRUDImpl.get_id(client_object)
