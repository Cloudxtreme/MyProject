import vmware.common.global_config as global_config
import vmware.interfaces.crud_interface as crud_interface


pylogger = global_config.pylogger


class ESX55CRUDImpl(crud_interface.CRUDInterface):

    @classmethod
    def get_id(cls, client_object):
        command = 'esxcli system uuid get'
        pylogger.info('Command to get UUID of Host %s' % command)
        out = client_object.connection.request(command)
        return out.response_data.replace("\n", "")
