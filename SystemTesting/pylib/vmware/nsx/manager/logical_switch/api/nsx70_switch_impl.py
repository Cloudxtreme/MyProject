import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.manager.logicalswitch.logicalswitch as logicalswitch
import vmware.nsx_api.manager.logicalswitch.schema.logicalswitch_schema as \
    logicalswitch_schema
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


class NSX70SwitchImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'summary': 'description',
    }

    _client_class = logicalswitch.LogicalSwitch
    _schema_class = logicalswitch_schema.LogicalSwitchSchema

    @classmethod
    def get_switch_vni(cls, client_object, schema=None):
        # TODO(salmanm): Check status_code here.
        result_dict = cls.read(client_object, id_=client_object.id_)
        if 'vni' not in result_dict:
            pylogger.warning("VNI not found in the returned schema of logical "
                             "switch %r" % client_object.id_)
        return result_dict['vni']
