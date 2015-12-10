import vmware.nsx_api.manager.nsgroup.nsgroup as nsgroup
import vmware.nsx_api.manager.nsgroup.schema.nsgroup_schema as nsgroup_schema

import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    """
    Below is a sample request to create a nsgroup.
    POST https://10.110.86.60/api/v1/ns-groups
    {
      "display_name":"testNSGroup",
        "members":[{"target_type":"IPSet",
                    "target_property":"id",
                    "op":"EQUALS",
                    "value":"183e372b-854c-4fcc-a24e-05721ce89a60"
                   }]
    }
    """
    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'operation': 'op',
        'logical_entity': 'target_type',
        'target_value': 'value'
    }
    _client_class = nsgroup.NSGroup
    _schema_class = nsgroup_schema.NSGroupSchema
