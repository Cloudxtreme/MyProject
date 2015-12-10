import vmware.kvm.cmd.default_service_impl as default_service_impl


class RHEL64ServiceImpl(default_service_impl.DefaultServiceImpl):
    """Command based service related operations"""
    NSX_SWITCH = 'openvswitch'

    @classmethod
    def get_nsx_switch_service_name(cls, client_object):
        return cls.NSX_SWITCH
