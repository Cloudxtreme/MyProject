import vmware.nsx_api.manager.ipam.ippool as ippool
import vmware.nsx_api.manager.ipam.listippoolallocations as listallocations
import vmware.nsx_api.manager.ipam.schema.\
    allocationipaddresslistresult_schema as allocation_schema
import vmware.nsx_api.manager.ipam.schema.ippool_schema as ippool_schema
import vmware.nsx_api.manager.ipam.schema.ippoollistresult_schema\
    as ippoollistresult_schema

import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'summary': 'description',
        'begin': 'start',
        'servers': 'dns_nameservers'
    }

    _client_class = ippool.IpPool
    _schema_class = ippool_schema.IpPoolSchema
    _list_schema_class = ippoollistresult_schema.IpPoolListResultSchema

    @classmethod
    def get_allocations(cls, client_obj, schema=None, **kwargs):
        cls.sanity_check()

        cls._allocate_client_class = listallocations.ListIpPoolAllocations
        cls._allocate_schema_class = allocation_schema.\
            AllocationIpAddressListResultSchema

        pylogger.info("%s.get_allocations(schema=%s, kwargs=%s)" %
                      (cls.__name__, schema, kwargs))

        payload = utilities.map_attributes(cls._attribute_map, schema)

        allocate_client_class_obj = cls._allocate_client_class(
            connection_object=client_obj.connection,
            ippool_id=client_obj.id_)

        allocate_schema_object = cls._allocate_schema_class(payload)
        allocate_schema_object = allocate_client_class_obj.query(
            allocate_schema_object)

        schema_dict = allocate_schema_object.get_py_dict_from_object()
        verification_form = utilities.map_attributes(
            cls._attribute_map, schema_dict, reverse_attribute_map=True)

        result_dict = verification_form
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            allocate_client_class_obj.last_calls_status_code)
        return result_dict
