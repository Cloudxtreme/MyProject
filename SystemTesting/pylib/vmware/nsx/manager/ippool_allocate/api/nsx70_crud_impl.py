import vmware.nsx_api.manager.ipam.allocateorreleasefromippool \
    as allocate_ippool
import vmware.nsx_api.manager.ipam.schema.allocationipaddress_schema \
    as allocate_ippool_schema
import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'allocation_id'
    }

    _client_class = allocate_ippool.AllocateOrReleaseFromIpPool
    _schema_class = allocate_ippool_schema.AllocationIpAddressSchema

    @classmethod
    def create(cls, client_obj, schema=None, **kwargs):
        cls.sanity_check()

        pylogger.info("%s.create(schema=%s, kwargs=%s)" %
                      (cls.__name__, schema, kwargs))

        payload = utilities.map_attributes(cls._attribute_map, schema)

        if kwargs['ippool_id'] is None:
            raise Exception('ippool_id parameter is missing')

        if kwargs['allocation_action'] is None:
            raise Exception('allocation_action parameter is missing')

        allocate_ippool_id = kwargs['ippool_id']
        allocation_action = kwargs['allocation_action']

        allocate_client_class_obj = cls._client_class(
            connection_object=client_obj.connection,
            ippool_id=allocate_ippool_id)

        allocate_schema_object = cls._schema_class(payload)
        allocate_schema_object = allocate_client_class_obj.create(
            allocate_schema_object,
            url_parameters={'action': allocation_action})

        #
        # For both operations - IP address Allocate and Release
        # create method is used.
        # While Allocation it returns schema with allocation id
        # While Release it does not return any schema
        #

        if allocate_schema_object is not None:
            schema_dict = allocate_schema_object.get_py_dict_from_object()
        else:
            schema_dict = {'id_': ''}

        verification_form = utilities.map_attributes(
            cls._attribute_map, schema_dict, reverse_attribute_map=True)

        result_dict = verification_form
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            allocate_client_class_obj.last_calls_status_code)
        return result_dict