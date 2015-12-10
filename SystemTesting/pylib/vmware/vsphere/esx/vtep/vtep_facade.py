import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.vsphere.esx.vtep.cli.vtep_cli_client as vtep_cli_client
import vmware.vsphere.esx.vtep.vtep as vtep

auto_resolve = base_facade.auto_resolve


class VTEPFacade(vtep.VTEP, base_facade.BaseFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.CLI

    def __init__(self, parent=None, id_=None):
        super(VTEPFacade, self).__init__(parent=parent, id_=id_)
        # instantiate client objects
        cli_client = vtep_cli_client.VTEPCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI),
            id_=self.id_)
        self._clients = {constants.ExecutionType.CLI: cli_client}
