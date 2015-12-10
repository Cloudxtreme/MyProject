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
        Creates a folder.

        @type client_object: FolderAPIClient instance
        @param client_object: FolderAPIClient instance
        @type folder: vim.Folder instance
        @param folder: Folder instance

        @rtype: NoneType
        @return: None
        """
        if folder:
            folder = client_object.parent.get_folder(name=folder)
        else:
            folder = client_object.parent.get_root_folder()
        client_object.folder_mor = folder.CreateFolder(client_object.name)

    @classmethod
    def delete(cls, client_object):
        """
        Deletes a folder.

        @type client_object: FolderAPIClient instance
        @param client_object: FolderAPIClient instance

        @rtype: NoneType
        @return: None
        """
        folder = client_object.parent.get_folder(name=client_object.name)
        return vc_soap_util.get_task_state(folder.Destroy_Task())
