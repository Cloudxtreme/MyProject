import vmware.common.constants as constants
import vmware.interfaces.crud_interface as crud_interface
import vmware.vsphere.vc.vc_soap_util as vc_soap_util
import vmware.common.global_config as global_config
import vmware.vsphere.vc.vdswitch.dvportgroup.api.dvportgroup_api_client as dvportgroup_api_client
import vmware
import pyVmomi as pyVmomi

vim = pyVmomi.vim
pylogger = global_config.pylogger

DVPGAPIClient = dvportgroup_api_client.DVPortgroupAPIClient


class VC55CRUDImpl(crud_interface.CRUDInterface):


    @classmethod
    def create(cls, client_object):
        """
        Creates a new port on the distributer virtual portgroup.

        @type client_object: DVPortAPIClient instance
        @param client_object: DVPGAPIClient instance

        @rtype: str
        @return: Status of the operation
        """
        # Parent of dvport is dvportgroup
        # The first port to get added is assumed to be the new port created
        new_ports = []
        if isinstance(client_object.parent, DVPGAPIClient) is True:
            dvpg_mor = client_object.parent.dvpg_mor
            existing_ports = dvpg_mor.portKeys
            dvpg_spec = vim.DistributedVirtualPortgroup.ConfigSpec()
            dvpg_spec.configVersion = client_object.parent.dvpg_mor.config.configVersion
            dvpg_spec.numPorts = client_object.parent.dvpg_mor.config.numPorts + 1
            task = client_object.parent.dvpg_mor.ReconfigureDVPortgroup_Task(
                dvpg_spec)
            result = vc_soap_util.get_task_state(task)
            if result == "success":
                new_ports = dvpg_mor.portKeys
                for port in list(set(new_ports)-set(existing_ports)):
                    client_object.name = port
                    break
                return result
            else:
                return constants.Result.FAILURE
