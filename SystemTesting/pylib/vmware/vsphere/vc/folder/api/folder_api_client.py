import vmware.vsphere.vsphere_client as vsphere_client
import vmware.vsphere.vc.folder.folder as folder
import vmware.common.global_config as global_config
import pyVmomi as pyVmomi

vim = pyVmomi.vim
pylogger = global_config.pylogger


class FolderAPIClient(folder.Folder, vsphere_client.VSphereAPIClient):

    def __init__(self, name, parent=None):
        super(FolderAPIClient, self).__init__(parent=parent)
        self.name = name
        self.parent = parent
        self.folder_mor = None
