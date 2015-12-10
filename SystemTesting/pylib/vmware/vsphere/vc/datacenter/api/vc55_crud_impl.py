import vmware.interfaces.crud_interface as crud_interface
import vmware.vsphere.vc.vc_soap_util as vc_soap_util
import vmware.common.global_config as global_config

import pyVmomi as pyVmomi

vim = pyVmomi.vim
pylogger = global_config.pylogger

SUCCESS = "Success"
FAILURE = "Failure"


class VC55CRUDImpl(crud_interface.CRUDInterface):

    @classmethod
    def create(cls, client_object, folder=None):
        """
        Creates a new datacenter.

        @type client_object: DatacenterAPIClient instance
        @param client_object: DatacenterAPIClient instance
        @type folder: vim.Folder instance
        @param folder: Folder object

        @rtype: NoneType
        @return: None
        """
        if folder:
            folder = client_object.parent.get_folder(name=folder)
        else:
            folder = client_object.parent.get_root_folder()
        datacenter = folder.CreateDatacenter(client_object.name)
        client_object.datacenter_mor = datacenter

    @classmethod
    def delete(cls, client_object):
        """
        Deletes the datacenter.

        @type client_object: DatacenterAPIClient instance
        @param client_object: DatacenterAPIClient instance

        @rtype: str
        @return: Status of the operation
        """
        datacenter = client_object.get_datacenter_mor()
        return vc_soap_util.get_task_state(datacenter.Destroy_Task())
