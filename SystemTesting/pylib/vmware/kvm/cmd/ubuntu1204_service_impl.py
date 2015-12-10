import vmware.kvm.cmd.default_service_impl as default_service_impl


class Ubuntu1204ServiceImpl(default_service_impl.DefaultServiceImpl):
    NSX_SWITCH = 'openvswitch-switch'

    @classmethod
    def get_nsx_switch_service_name(cls, client_object):
        return cls.NSX_SWITCH
