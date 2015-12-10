import vmware.nsx_api.manager.firewall.addsection as addsection
import vmware.nsx_api.manager.firewall.getsectionwithrules as getsectionwithrules  # noqa
import vmware.nsx_api.manager.firewall.schema.firewallsection_schema as firewallsection_schema  # noqa
import vmware.nsx_api.manager.firewall.schema.firewallsectionlistresult_schema as firewallsectionlistresult_schema  # noqa
import vmware.nsx_api.manager.firewall.schema.firewallsectionrulelist_schema as firewallsectionrulelist_schema  # noqa

import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    """
    Mapping between the class methods and the corresponding HTTP Method
    create -> POST
    update -> PUT
    create_section_with_rules -> POST
    update_section_with_rules -> POST
    get_section_with_rules -> POST

    The class methods have been implemented to support following REST calls
    POST /api/v1/firewall/sections
    GET /api/v1/firewall/sections/<section-id>
    PUT /api/v1/firewall/sections/<section-id>
    DELETE /api/v1/firewall/sections/<section-id>
    POST /api/v1/firewall/sections/<section-id>?action=list_with_rules
    POST /api/v1/firewall/sections/<section-id>?action=revise
    POST /api/v1/firewall/sections/<section-id>?action=revise_with_rules
    POST /api/v1/firewall/sections?action=create_with_rules
    """
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
        'destinationnegate': 'destinations_excluded',
        'sourcenegate': 'sources_excluded',
        'logging_enabled': 'logged'
    }
    _client_class = addsection.AddSection
    _schema_class = firewallsection_schema.FirewallSectionSchema
    _list_schema_class = firewallsectionlistresult_schema. \
        FirewallSectionListResultSchema

    @classmethod
    def get_sdk_client_object(cls, client_object, parent_id=None,
                              client_class=None, schema_class=None, **kwargs):
        client_class = client_class if client_class else cls._client_class
        if parent_id:
            return client_class(
                connection_object=client_object.connection,
                url_prefix=cls._url_prefix,
                addsection_id=parent_id)
        else:
            obj = client_class(
                connection_object=client_object.connection,
                url_prefix=cls._url_prefix)
            response_schema_class = (
                schema_class if schema_class else cls._response_schema_class)
            if response_schema_class is not None:
                obj.schema_class = (
                    response_schema_class.__module__ + '.' +
                    response_schema_class.__name__)
            return obj

    @classmethod
    def create(cls, client_obj, schema=None, **kwargs):
        query_params = {}
        if 'operation' in schema:
            query_params['operation'] = schema.pop('operation')
            if 'section_id' in schema:
                query_params['id'] = schema.pop('section_id')
        if 'dfw_rules' in schema and schema['dfw_rules']:
            query_params['action'] = 'create_with_rules'
            return cls.create_section_with_rules(client_obj, schema=schema,
                                                 query_params=query_params,
                                                 **kwargs)
        else:
            return super(NSX70CRUDImpl, cls).create(
                client_obj, schema=schema, query_params=query_params, **kwargs)

    @classmethod
    def update(cls, client_obj, schema=None, id_=None, **kwargs):
        if isinstance(schema, list):
            schema = schema[0]
        if 'dfw_rules' in schema and schema['dfw_rules']:
            return cls.update_section_with_rules(client_obj, schema=schema,
                                                 id_=id_, **kwargs)
        else:
            return super(NSX70CRUDImpl, cls).update(
                client_obj, id_=id_, schema=schema, **kwargs)

    @classmethod
    def create_section_with_rules(cls, client_obj, schema=None, **kwargs):
        schema_class = firewallsectionrulelist_schema. \
            FirewallSectionRuleListSchema
        return super(NSX70CRUDImpl, cls).create(
            client_obj, schema=schema, schema_class=schema_class, **kwargs)

    @classmethod
    def update_section_with_rules(cls, client_obj, schema=None,
                                  id_=None, **kwargs):
        if isinstance(schema, list):
            schema = schema[0]
        schema_class = firewallsectionrulelist_schema. \
            FirewallSectionRuleListSchema
        query_params = {
            'action': 'update_with_rules'
        }
        return super(NSX70CRUDImpl, cls).update(
            client_obj, id_=id_, schema=schema, schema_class=schema_class,
            query_params=query_params, **kwargs)

    @classmethod
    def revise_section(cls, client_obj, schema=None,
                       **kwargs):
        if isinstance(schema, list):
            schema = schema[0]
        query_params = {
            'action': 'revise'
        }
        if 'operation' in schema:
            query_params['operation'] = schema.pop('operation')
            if 'section_id' in schema:
                query_params['id'] = schema.pop('section_id')
        return super(NSX70CRUDImpl, cls).update(
            client_obj, id_=client_obj.id_, schema=schema,
            query_params=query_params, **kwargs)

    @classmethod
    def revise_section_with_rules(cls, client_obj, schema=None,
                                  **kwargs):
        if isinstance(schema, list):
            schema = schema[0]
        schema_class = firewallsectionrulelist_schema. \
            FirewallSectionRuleListSchema
        query_params = {
            'action': 'revise_with_rules'
        }
        if 'operation' in schema:
            query_params['operation'] = schema.pop('operation')
            if 'section_id' in schema:
                query_params['id'] = schema.pop('section_id')
        return super(NSX70CRUDImpl, cls).update(
            client_obj, id_=client_obj.id_, schema=schema,
            query_params=query_params, schema_class=schema_class, **kwargs)

    @classmethod
    def get_section_with_rules(cls, client_obj, get_section_with_rules=None,
                               **kwargs):
        client_class = getsectionwithrules.GetSectionWithRules
        schema_class = firewallsectionrulelist_schema. \
            FirewallSectionRuleListSchema
        return super(NSX70CRUDImpl, cls).create(
            client_obj, parent_id=client_obj.id_, client_class=client_class,
            schema_class=schema_class, **kwargs)

    @classmethod
    def delete(cls, client_obj, **kwargs):
        query_params = {
            'cascade': 'true'
        }
        return super(NSX70CRUDImpl, cls).delete(
            client_obj, query_params=query_params, **kwargs)
