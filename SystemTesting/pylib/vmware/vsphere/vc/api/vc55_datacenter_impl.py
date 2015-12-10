import vmware.interfaces.datacenter_interface as datacenter_interface
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import pyVmomi as pyVmomi

vim = pyVmomi.vim
pylogger = global_config.pylogger


class VC55DatacenterImpl(datacenter_interface.DatacenterInterface):

    @classmethod
    def _recurse(cls, entity):
        """Helper to recurse through nested folders"""
        for child in entity.childEntity:
            if isinstance(child, vim.Folder):
                child = cls._recurse(child)
                return child
            elif isinstance(child, vim.Datacenter):
                return child

    # TODO: Negative test a nested hierarchy of folders
    @classmethod
    def check_datacenter_exists(cls, client_object, name=None):
        """
        Checks if a given datacenter exists.

        @type client_object: VCAPIClient instance
        @param client_object: VCAPIClient instance
        @type datacenter: str
        @param datacenter: Name of the datacenter

        @rtype: str
        @return: Success or Failure
        """
        root_folder = client_object.get_root_folder()
        for folder in root_folder.childEntity:
            if isinstance(folder, vim.Datacenter):
                if folder.name == name:
                    return constants.Result.SUCCESS
            elif isinstance(folder, vim.Folder):
                child = cls._recurse(folder)
                if isinstance(child, vim.Datacenter):
                    if child.name == name:
                        return constants.Result.SUCCESS
        return constants.Result.FAILURE
