import vmware.interfaces.switch_interface as switch_interface
import vmware.common.constants as constants
import vmware.common.global_config as global_config

import pyVmomi as pyVmomi

vim = pyVmomi.vim
pylogger = global_config.pylogger


class VC55SwitchImpl(switch_interface.SwitchInterface):

    @classmethod
    def check_DVS_exists(cls, client_object, name=None, datacenter=None):
        """
        Checks if a distributed virtual switch exists.

        @type client_object: VCAPIClient instance
        @param client_object: VCAPIClient instance
        @type name: str
        @param name: DVS name
        @type datacenter: str
        @param datacenter: Datacenter name

        @rtype: str
        @return: Success or Failure
        """
        if datacenter is None:
            pylogger.error("Datacenter name is required")
        root_folder = client_object.get_root_folder()
        for folder in root_folder.childEntity:
            if isinstance(folder, vim.Datacenter):
                if folder.name == datacenter:
                    for component in folder.networkFolder.childEntity:
                        if(
                                isinstance(component,
                                           vim.DistributedVirtualSwitch) or
                                isinstance(
                                    component,
                                    vim.dvs.VmwareDistributedVirtualSwitch)):
                            if component.name == name:
                                return constants.Result.SUCCESS
            elif isinstance(folder, vim.Folder):
                child = cls._recurse(folder)
                if isinstance(child, vim.Datacenter):
                    if child.name == datacenter:
                        for component in child.networkFolder.childEntity:
                            if(
                                    isinstance(
                                        component,
                                        vim.DistributedVirtualSwitch) or
                                    isinstance(
                                        component,
                                        vim.dvs.VmwareDistributedVirtualSwitch)
                                    ):
                                if component.name == name:
                                    return constants.Result.SUCCESS
        return constants.Result.FAILURE

    @classmethod
    def _recurse(cls, entity):
        """Helper to recurse through nested folders"""
        for child in entity.childEntity:
            if isinstance(child, vim.Folder):
                child = cls._recurse(child)
                return child
            elif isinstance(child, vim.Datacenter):
                return child
