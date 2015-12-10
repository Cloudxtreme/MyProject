import argparse

import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.vsphere.vc.profile.profile as profile
import vmware.vsphere.vc.profile.api.profile_api_client as profile_api_client


class ProfileFacade(profile.Profile, base_facade.BaseFacade):
    """Profile client class to initiate Profile operations."""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, name, parent):
        super(ProfileFacade, self).__init__(name, parent=parent)
        self.parent = parent
        # instantiate client objects
        api_client = profile_api_client.ProfileAPIClient(
            name, parent=parent.clients.get(constants.ExecutionType.API))
        # Maintain the dictionary of client objects.
        # This will later be used by initialize() to create
        # connection anchors
        self._clients = {constants.ExecutionType.API: api_client}

    def get_impl_version(self, execution_type=None, interface=None):
        return "VC55"


def GetArgs():
    """
    Supports the command-line arguments listed below.
    """

    parser = argparse.ArgumentParser(description='Profile Client')
    parser.add_argument('-s', '--vc', required=True,
                        action='store', help='Remote vc to connect to')
    parser.add_argument('-u', '--username', required=True,
                        action='store', help='Username for vc')
    parser.add_argument('-p', '--password', required=False,
                        action='store', help='Password for vc')
    parser.add_argument('-i', '--profile_name', required=True,
                        action='store', help='name of Profile')
    args = parser.parse_args()
    return args


def main():

    import vmware.vsphere.vc.vc_facade as vc_facade
    import vmware.vsphere.vc.profile.profile_facade as profile_facade
    import vmware.common.global_config as global_config

    pylogger = global_config.pylogger

    args = GetArgs()
    password = args.password
    vc = args.vc
    username = args.username
    id_ = args.profile_name

    v_c = vc_facade.VCFacade(vc, username, password)
    # v_c = vc_facade.VCFacade("10.144.138.57", "root", "vmware")

    pr = profile_facade.ProfileFacade(name=id_, parent=v_c)

    # To create schema_object for Profile, use profile_schema module

    # result = pr.get_network_policy_info(category="vswitch",
    #                                    network_device="vSwitch1")
    result = pr.check_compliance()
    pylogger.info("Operation result = %r" % result)

if __name__ == "__main__":
    main()
