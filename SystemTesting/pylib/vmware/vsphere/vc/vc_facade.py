import argparse

import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.vsphere.vc.api.vc_api_client as vc_api_client
import vmware.vsphere.vc.cli.vc_cli_client as vc_cli_client
import vmware.vsphere.vc.vc as vc


class VCFacade(vc.VC, base_facade.BaseFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, ip=None, username=None, password=None, parent=None):
        super(VCFacade, self).__init__(ip=ip,
                                       username=username,
                                       password=password,
                                       parent=parent)

        api_client = vc_api_client.VCAPIClient(ip=self.ip,
                                               username=self.username,
                                               password=self.password)

        cli_client = vc_cli_client.VCCLIClient(ip=self.ip,
                                               username=self.username,
                                               password=self.password)

        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}


def GetArgs():
    """
    Supports the command-line arguments listed below.
    """

    parser = argparse.ArgumentParser(description='Arguments for VC Client')
    parser.add_argument('-s', '--vc', required=True,
                        action='store', help='Remote vc to connect to')
    parser.add_argument('-u', '--username', required=True,
                        action='store', help='Username for vc')
    parser.add_argument('-p', '--password', required=False,
                        action='store', help='Password for vc')
    args = parser.parse_args()
    return args


if __name__ == "__main__":

    import vmware.vsphere.vc.vc_facade as vc_facade
    import vmware.common.global_config as global_config

    pylogger = global_config.pylogger

    args = GetArgs()
    password = args.password
    vc = args.vc
    username = args.username

    v_c = vc_facade.VCFacade(vc, username, password)
    # v_c = vc_facade.VCFacade("10.144.138.57", "root", "vmware")

    result = v_c.check_DVS_exists(datacenter="Datacenter2", name="DSwitch4")
    # pprint(vars(result))
    pylogger.info("Operation result= %r" % result)
