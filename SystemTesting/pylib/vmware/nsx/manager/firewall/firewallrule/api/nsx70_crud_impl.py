import vmware.nsx_api.manager.firewall.addruleinsection as \
    addruleinsection
import vmware.nsx_api.manager.firewall.schema.firewallrule_schema as \
    firewallrule_schema
import vmware.nsx_api.manager.firewall.schema.firewallrulelist_schema as \
    firewallrulelist_schema
import vmware.nsx_api.manager.firewall.schema.firewallrulelistresult_schema as \
    firewallrulelistresult_schema

import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'node_id': 'target_id',
        'logical_entity': 'target_type',
        'layer': 'section_type',
        'sectionname': 'display_name',
        'name': 'display_name',
        'service_affected': 'services',
        'protocolname': 'protocol_name',
        'destinationport': 'destination_port',
        'sourceport': 'source_port',
        'protocolnumber': 'protocol',
        'subprotocolname': 'sub_protocol_name',
        'subprotocol': 'sub_protocol',
        'source_object': 'sources',
        'destination_object': 'destinations',
        'dfw_rules': 'rules',
        'sourcenegate': 'sources_excluded',
        'destinationnegate': 'destinations_excluded',
        'logging_enabled': 'logged'
    }
    _client_class = addruleinsection.AddRuleInSection
    _schema_class = firewallrule_schema.FirewallRuleSchema
    _list_schema_class = firewallrulelistresult_schema. \
        FirewallRuleListResultSchema

    @classmethod
    def get_sdk_client_object(cls, client_object, parent_id=None,
                              client_class=None, schema_class=None,
                              id_=None):
        client_class = client_class if client_class else cls._client_class
        obj = client_class(
            connection_object=client_object.connection,
            url_prefix=cls._url_prefix,
            addsection_id=parent_id)
        response_schema_class = (
            schema_class if schema_class else cls._response_schema_class)
        if response_schema_class is not None:
            obj.schema_class = (
                response_schema_class.__module__ + '.' +
                response_schema_class.__name__)
        return obj

    @classmethod
    def get_id_from_schema(cls, client_obj, schema=None, **kwargs):
        section_id = schema.pop('section_id', None)
        return super(NSX70CRUDImpl, cls).get_id_from_schema(
            client_obj, parent_id=section_id, schema=schema,
            **kwargs)

    @classmethod
    def create(cls, client_obj, schema=None, **kwargs):
        query_params = {}
        if 'operation' in schema:
            query_params['operation'] = schema.pop('operation')
            if 'rule_id' in schema:
                query_params['id'] = schema.pop('rule_id')
        if 'dfw_rules' in schema and schema['dfw_rules']:
            query_params['action'] = 'create_multiple'
            return cls.create_multiple_rules(
                client_obj, schema=schema, query_params=query_params, **kwargs)
        else:
            section_id = schema.pop('section_id', None)
            return super(NSX70CRUDImpl, cls).create(
                client_obj, parent_id=section_id, schema=schema,
                query_params=query_params, **kwargs)

    @classmethod
    def update(cls, client_obj, schema=None, id_=None, **kwargs):
        section_id = schema.pop('section_id', None)
        return super(NSX70CRUDImpl, cls).update(
            client_obj, id_=client_obj.id_, parent_id=section_id,
            schema=schema, **kwargs)

    @classmethod
    def create_multiple_rules(cls, client_obj, schema=None, **kwargs):
        schema_class = firewallrulelist_schema. \
            FirewallRuleListSchema
        section_id = schema.pop('section_id', None)
        return super(NSX70CRUDImpl, cls).create(
            client_obj, parent_id=section_id, schema=schema,
            schema_class=schema_class, **kwargs)

    @classmethod
    def revise_rules(cls, client_obj, schema=None,
                     **kwargs):
        if isinstance(schema, list):
            schema = schema[0]
        query_params = {
            'action': 'revise'
        }
        if 'operation' in schema:
            query_params['operation'] = schema.pop('operation')
            if 'rule_id' in schema:
                query_params['id'] = schema.pop('rule_id')
        section_id = schema.pop('section_id', None)
        return super(NSX70CRUDImpl, cls).update(
            client_obj, id_=client_obj.id_, parent_id=section_id,
            schema=schema, query_params=query_params, **kwargs)

    @classmethod
    def delete(cls, client_obj, section_id=None, **kwargs):
        return super(NSX70CRUDImpl, cls).delete(
            client_obj, id_=client_obj.id_, parent_id=section_id,
            **kwargs)
