import vmware.base.switch as switch


class LogicalSwitch(switch.Switch):

    def __init__(self, parent=None):
        super(LogicalSwitch, self).__init__(parent)
        self.parent = parent
        self.id_ = None

    def get_switch_id(self):
        return self.id_

    def get_id(self):
        return self.id_
