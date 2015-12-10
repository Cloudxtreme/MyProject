import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.common.global_config as global_config

auto_resolve = base_facade.auto_resolve
pylogger = global_config.pylogger


class Zone(base.Base):
    #
    #This is base class for all components of Zone type.
    #

    display_name = None
    description = None

    def __init__(self, parent=None):
        super(Zone, self).__init__()
        self.parent = parent

    def get_transport_zone_id(self):
        return self.id_
