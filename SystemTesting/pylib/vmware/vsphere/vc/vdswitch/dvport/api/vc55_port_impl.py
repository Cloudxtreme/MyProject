import vmware.interfaces.port_interface as port_interface
import vmware.vsphere.vc.vc_soap_util as vc_soap_util
import vmware.common.global_config as global_config
import vmware.vsphere.vc.vdswitch.api.vdswitch_api_client as vdswitch_api_client
import vmware.vsphere.vc.vdswitch.dvportgroup.api.dvportgroup_api_client as dvportgroup_api_client
import vmware
import pyVmomi as pyVmomi

DVPGAPIClient = dvportgroup_api_client.DVPortgroupAPIClient
VDSwitchAPIClient = vdswitch_api_client.VDSwitchAPIClient
vim = pyVmomi.vim
pylogger = global_config.pylogger

SUCCESS = "success"


class VC55PortImpl(port_interface.PortInterface):

    @classmethod
    def block(cls, client_object):
        """
        Blocks the port on the vdswitch.

        @type client_object: DVPortAPIClient instance
        @param client_object: DVPortgroupAPIClient instance

        @rtype: str
        @return: Status of the operation
        """
        dvp = vim.dvs.DistributedVirtualPort.ConfigSpec()
        dvp.operation = "edit"
        setting = vim.dvs.DistributedVirtualPort.Setting()
        bool_policy = vim.BoolPolicy()
        bool_policy.value = True
        setting.blocked = bool_policy
        dvp.setting = setting
        dvp.key = client_object.name
        if isinstance(client_object.parent, DVPGAPIClient):
            policy = vim.dvs.DistributedVirtualPortgroup.PortgroupPolicy()
            policy.blockOverrideAllowed = True
            dvpg_config = vim.dvs.DistributedVirtualPortgroup.ConfigSpec()
            dvpg_config.policy = policy
            dvpg_mor = client_object.parent.dvpg_mor
            dvpg_config.configVersion = dvpg_mor.config.configVersion
            task_check = dvpg_mor.ReconfigureDVPortgroup_Task(
                dvpg_config)
            if vc_soap_util.get_task_state(task_check) == SUCCESS:
                vds_mor = client_object.parent.parent.vds_mor
                task = vds_mor.ReconfigureDVPort_Task([dvp])
        elif isinstance(client_object.parent, VDSwitchAPIClient):
            task = client_object.parent.vds_mor.ReconfigureDVPort_Task([dvp])
        return vc_soap_util.get_task_state(task)
