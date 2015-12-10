import argparse
import vmware.common.global_config as global_config
import vmware.vsphere.esx.esx_facade as esx_facade

pylogger = global_config.pylogger


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

def main():

    args = GetArgs()
    password = args.password
    host = args.host
    username = args.username

    # $ python esx_facade.t -s 10.144.138.189 -u root -p ca\$hc0w
    hv = esx_facade.ESXFacade(host, username, password)

    #######################################################################
    # Unit-tests for get_vm_list_by_attribute
    # This test requires a minimum of 1 host

    #Get vm objects given a list of vm names
    attribute = "name"
    attribute_list = ["1-vm_RHEL63_srv_64-local-470-669958c3-62ad-4aba-8e35-6c5002450ae3",
        "2-vm_RHEL63_srv_64-local-470-5b016491-c9d4-46b4-b207-34151cb82810"]
    result = hv.get_vm_list_by_attribute(attribute=attribute,
            attribute_list=attribute_list)
    pylogger.info("VM list by name = %r" % result)

    #Get vm objects given a list of vmx paths
    attribute = "vmx"
    attribute_list = ["[datastore1] vdtest-30470/VM-2-10.144.139.152/RHEL63_srv_64.vmx"]
    result = hv.get_vm_list_by_attribute(attribute=attribute,
            attribute_list=attribute_list)
    pylogger.info("VM list by vmx = %r" % result)

    #Get vm objects given an invalid attribute
    attribute = "invalid"
    attribute_list = ["[datastore1] vdtest-30470/VM-2-10.144.139.152/RHEL63_srv_64.vmx"]
    result = hv.get_vm_list_by_attribute(attribute=attribute,
            attribute_list=attribute_list)
    pylogger.info("VM list by vmx = %r" % result)
    ########################################################################

if __name__ == "__main__": main()
