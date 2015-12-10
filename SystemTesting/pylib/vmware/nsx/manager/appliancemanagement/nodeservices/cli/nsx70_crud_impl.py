import schema.list_services_schema as list_services_schema
import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.interfaces.service_interface as service_interface

pylogger = global_config.pylogger


class NSX70CRUDImpl(service_interface.ServiceInterface):

    @classmethod
    def read(cls, client_object, **kwargs):
        endpoint = "show services"
        parser = "raw/listServices"
        expect_prompt = ['bytes*', '>']
        mapped_pydict = utilities.get_mapped_pydict_for_expect(
            client_object.connection, endpoint, parser, expect_prompt, ':')

        if 'failure' in mapped_pydict:
            raise Exception(mapped_pydict['failure'])

        schema_object = list_services_schema.ListServicesSchema(mapped_pydict)
        return schema_object