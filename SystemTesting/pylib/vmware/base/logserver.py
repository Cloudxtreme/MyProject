import vmware.base.base as base
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


class Logserver (base.Base):
    # This is a base class for
    # all external log collectors

    display_name = None
    description = None

    def __init__(self, parent=None):
        super(Logserver, self).__init__()
        self.parent = parent
