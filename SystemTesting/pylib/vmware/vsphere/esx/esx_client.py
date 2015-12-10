import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.vsphere.esx.api.esx_api_client as esx_api_client
import vmware.vsphere.esx.cli.esx_cli_client as esx_cli_client
import vmware.vsphere.esx.cmd.esx_cmd_client as esx_cmd_client
import vmware.vsphere.esx.esx as esx


class ESXFacade(esx.ESX, base_facade.BaseFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, ip=None, username=None, password=None, parent=None):
        super(ESXFacade, self).__init__(ip=ip,
                                        username=username,
                                        password=password,
                                        parent=parent)

        api_client = esx_api_client.ESXAPIClient(ip=self.ip,
                                                 username=self.username,
                                                 password=self.password)

        cli_client = esx_cli_client.ESXCLIClient(ip=self.ip,
                                                 username=self.username,
                                                 password=self.password)

        cmd_client = esx_cmd_client.ESXCMDClient(ip=self.ip,
                                                 username=self.username,
                                                 password=self.password)

        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client,
                         constants.ExecutionType.CMD: cmd_client}

    def get_impl_version(self, execution_type=None, interface=None):
        return "ESX55"


if __name__ == "__main__":
    import vmware.common.global_config as global_config

    pylogger = global_config.pylogger

    hv = ESXFacade("10.144.139.194", "root", "ca$hc0w")

    result = hv.list_networks()
    pylogger.info("Operation result= %r" % result)
