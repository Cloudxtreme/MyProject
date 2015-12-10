import argparse

import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.vsphere.vc.folder.folder as folder
import vmware.vsphere.vc.folder.api.folder_api_client as folder_api_client


class FolderFacade(folder.Folder, base_facade.BaseFacade):
    """Folder client class to initiate Folder operations."""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, parent=None, name=None):
        super(FolderFacade, self).__init__(name, parent=parent)
        self.parent = parent
        # instantiate client objects
        api_client = folder_api_client.FolderAPIClient(
            name, parent=parent.clients.get(constants.ExecutionType.API))
        # Maintain the dictionary of client objects.
        # This will later be used by initialize() to create
        # connection anchors
        self._clients = {constants.ExecutionType.API: api_client}


def GetArgs():
    """
    Supports the command-line arguments listed below.
    """

    parser = argparse.ArgumentParser(description='Arguments for Folder Client')
    parser.add_argument('-s', '--vc', required=True,
                        action='store', help='Remote vc to connect to')
    parser.add_argument('-u', '--username', required=True,
                        action='store', help='Username for vc')
    parser.add_argument('-p', '--password', required=False,
                        action='store', help='Password for vc')
    parser.add_argument('-i', '--folder_name', required=True,
                        action='store', help='id_ of Folder name')
    args = parser.parse_args()
    return args


def main():

    import vmware.vsphere.vc.vc_facade as vc_facade
    import vmware.vsphere.vc.folder.folder_facade as folder_facade
    import vmware.common.global_config as global_config

    args = GetArgs()
    password = args.password
    vc = args.vc
    username = args.username
    id_ = args.folder_name

    pylogger = global_config.pylogger

    # v_c = vc_facade.VCFacade("10.144.138.57", "root", "vmware")
    v_c = vc_facade.VCFacade(vc, username, password)
    dc = folder_facade.FolderFacade(name=id_, parent=v_c)

    result = dc.delete()
    pylogger.info("Operation result = %r" % result)

if __name__ == "__main__":
    main()
