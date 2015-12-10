import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.common.global_config as global_config

pylogger = global_config.pylogger
auto_resolve = base_facade.auto_resolve


class Server(base.Base):

    def __init__(self, ip=None, username=None, password=None, parent=None):
        super(Server, self).__init__()
        self.ip = ip
        self.username = username
        self.password = password
        self.parent = parent
