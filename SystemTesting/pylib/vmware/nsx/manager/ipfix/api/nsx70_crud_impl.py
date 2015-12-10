import vmware.nsx_api.manager.ipfix.updateswitchipfixconfig as \
    updateswitchipfixconfig
import vmware.nsx_api.manager.ipfix.schema.ipfixobspointconfig_schema as \
    ipfixobspointconfig_schema

import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseRUImpl):

    _attribute_map = {
        'port': 'collector_port',
        'ip_address': 'collector_ip_address',
        'domain_id': 'observation_domain_id',
        'flow_timeout': 'active_timeout'
    }

    _client_class = updateswitchipfixconfig.UpdateSwitchIpfixConfig
    _schema_class = ipfixobspointconfig_schema.IpfixObsPointConfigSchema

    @classmethod
    def create(cls, client_obj, id_=None, schema=None, merge=False):
        result_dict = super(NSX70CRUDImpl, cls).update(
            client_obj, schema=schema, merge=merge)
        # Rest calls for IPFix need not be appended by uuids as it is a global
        # configuration.
        result_dict['id_'] = ""
        return result_dict
