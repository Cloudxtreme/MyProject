import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.interfaces.crud_interface as crud_interface

pylogger = global_config.pylogger


class NSX70CRUDImpl(crud_interface.CRUDInterface):

    @classmethod
    def query(cls, client_obj, **kwargs):
        endpoint = "show interfaces"
        parser = "raw/listInterfaces"
        expect_prompt = ['bytes*', '>']

        pydict = utilities.\
            get_mapped_pydict_for_expect(client_obj.connection,
                                         endpoint,
                                         parser,
                                         expect_prompt,
                                         ' ')

        return pydict
