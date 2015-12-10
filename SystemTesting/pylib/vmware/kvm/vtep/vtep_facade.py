import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.kvm.vtep.cli.vtep_cli_client as vtep_cli_client
import vmware.kvm.vtep.vtep as vtep


class VTEPFacade(vtep.VTEP, base_facade.BaseFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.CLI

    def __init__(self, parent=None, name=None):
        super(VTEPFacade, self).__init__(parent=parent, name=name)
        # instantiate client objects
        cli_client = vtep_cli_client.VTEPCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI),
            name=self.name)
        self._clients = {constants.ExecutionType.CLI: cli_client}
