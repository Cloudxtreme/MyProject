import vmware.nsx_api.manager.excludelist.updateexcludelist as \
    updateexcludelist
import vmware.nsx_api.manager.excludelist.schema.excludelist_schema as \
    excludelist_schema

import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'node_id': 'target_id',
        'nsxgroup': 'members',
        'logical_entity': 'target_type'
    }
    _client_class = updateexcludelist.UpdateExcludeList
    _schema_class = excludelist_schema.ExcludeListSchema

    @classmethod
    def create(cls, client_obj, schema=None, **kwargs):
        return cls.update(client_obj, schema=schema, **kwargs)

    @classmethod
    def update(cls, client_obj, schema=None, id_=None, query_params=None,
               **kwargs):
        if 'operation' in schema and schema['operation']:
            query_params = {
                'action': schema.pop('operation')
            }
            result_dict = super(NSX70CRUDImpl, cls).create(
                client_obj, schema=schema, query_params=query_params,
                **kwargs)
        else:
            result_dict = super(NSX70CRUDImpl, cls).update(
                client_obj, id_=id_, schema=schema, **kwargs)
        result_dict['id_'] = ""
        return result_dict
