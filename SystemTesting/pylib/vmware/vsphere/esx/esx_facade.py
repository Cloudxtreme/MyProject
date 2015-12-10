import argparse

import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.vsphere.esx.api.esx_api_client as esx_api_client
import vmware.vsphere.esx.cli.esx_cli_client as esx_cli_client
import vmware.vsphere.esx.cmd.esx_cmd_client as esx_cmd_client
import vmware.vsphere.esx.esx as esx

pylogger = global_config.pylogger


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


def GetArgs():
    """
    Supports the command-line arguments listed below.
    """

    parser = argparse.ArgumentParser(description='ESX Client')
    parser.add_argument('-s', '--host', required=True,
                        action='store', help='Remote host to connect to')
    parser.add_argument('-u', '--username', required=True,
                        action='store', help='Username for host')
    parser.add_argument('-p', '--password', required=False,
                        action='store', help='Password for host')
    args = parser.parse_args()
    return args


if __name__ == "__main__":

    import vmware.vsphere.esx.esx_facade as esx_facade
    args = GetArgs()
    password = args.password
    host = args.host
    username = args.username

    # $ python esx_facade.py -s 10.144.138.189 -u root -p ca\$hc0w
    hv = esx_facade.ESXFacade(host, username, password)
    result = hv.list_networks()
    # hv = esx_facade.ESXFacade("10.24.20.59", "root", "ca$hc0w")

    pylogger.info("client object %s" % hv.get_client(
        constants.ExecutionType.CLI).connection)
    hv.set_nsx_registration(
        execution_type='cli',
        manager_ip='10.144.139.105',
        manager_thumbprint='435143a1b5fc8bb70a3aa9b15f9dd29e0f6673a8',
        manager_username='admin',
        manager_password='default')
