import vmware.interfaces.crud_interface as crud_interface
import vmware.vsphere.vc.vc_soap_util as vc_soap_util
import vmware.common.global_config as global_config

import pyVmomi as pyVmomi

vim = pyVmomi.vim
pylogger = global_config.pylogger
SUCCESS = "success"


class VC55CRUDImpl(crud_interface.CRUDInterface):

    @classmethod
    def create(cls, client_object, schema_object=None):
        """
        Creates a distributed virtual portgroup on the switch.

        @type client_object: DVPortgroupAPIClient instance
        @param client_object: DVPortgroupAPIClient instance
        @type schema_object: NetworkSchema instance
        @param schema_object: Schema object contating portgroup attributes

        @rtype: str
        @return: Status of the operation
        """
        dvpg_spec = client_object.get_dvpg_config_spec(
            auto_expand=schema_object.auto_expand,
            description=schema_object.description,
            name=client_object.name,
            numports=schema_object.numports,
            portgroup_type=schema_object.portgroup_type,
            resource_pool=schema_object.resource_pool)
        task = client_object.parent.vds_mor.CreateDVPortgroup_Task(dvpg_spec)
        result = vc_soap_util.get_task_state(task)
        if result == SUCCESS:
            client_object.dvpg_mor = task.info.result
            client_object.dvpg_key = client_object.dvpg_mor.key
        return result
