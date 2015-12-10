import argparse

import vmware.vsphere.esx.esx_facade as esx_facade
import vmware.vsphere.vm.vm_facade as vm_facade
import vmware.common.global_config as global_config


def GetArgs():
    """
    Supports the command-line arguments listed below.
    """

    parser = argparse.ArgumentParser(description='Arguments for VM Client')
    parser.add_argument('-s', '--host', required=True,
                        action='store', help='Remote host to connect to')
    parser.add_argument('-u', '--username', required=True,
                        action='store', help='Username for host')
    parser.add_argument('-p', '--password', required=False,
                        action='store', help='Password for host')
    parser.add_argument('-i', '--vm_id', required=True,
                        action='store', help='Name of VM to power on')
    args = parser.parse_args()
    return args


def main():

    pylogger = global_config.pylogger

    args = GetArgs()
    password = args.password
    host = args.host
    username = args.username
    id_ = args.vm_id

    # $ python vm_facade.py -s 10.144.138.189 -u root -p ca\$hc0w -i 3
    hc = esx_facade.ESXFacade(host, username, password)

    # hc = esx_facade.ESX("10.144.138.189", "root", "ca$hc0w")

    # XXX(Shashank): Since vm creation hasn't been implemented we are setting
    # id to an existing vm's name in the host inventory.
    vm = vm_facade.VMFacade(id_, parent=hc)
    result = vm.get_power_state()
    pylogger.info("Operation result= %r" % result)

if __name__ == "__main__":
    main()
