import vmware.base.switch as switch


class VSSwitch(switch.Switch):

    def get_impl_version(self, execution_type=None, interface=None):
        return "ESX55"
