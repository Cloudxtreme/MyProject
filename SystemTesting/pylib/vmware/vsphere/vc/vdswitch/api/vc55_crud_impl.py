import vmware.interfaces.crud_interface as crud_interface
import vmware.vsphere.vc.vc_soap_util as vc_soap_util
import vmware.common.global_config as global_config

import pyVmomi as pyVmomi

vim = pyVmomi.vim
pylogger = global_config.pylogger


class VC55CRUDImpl(crud_interface.CRUDInterface):

    @classmethod
    def delete(cls, client_object):
        """
        Deletes the switch from the inventory.

        @type client_object: VDSwitchAPIClient instance
        @param client_object: VDSwitchAPIClient instance

        @rtype: str
        @return: Status of the operation
        """
        task = client_object.vds_mor.Destroy_Task()
        return vc_soap_util.get_task_state(task)
