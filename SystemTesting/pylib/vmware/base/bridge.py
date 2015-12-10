import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.common.global_config as global_config

pylogger = global_config.pylogger
auto_resolve = base_facade.auto_resolve


class Bridge(base.Base):
    # This is base class for all components of bridge type.

    display_name = None
    description = None

    def __init__(self, parent=None):
        super(Bridge, self).__init__()
        self.parent = parent
