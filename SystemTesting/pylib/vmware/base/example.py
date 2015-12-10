import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.common.global_config as global_config
import vmware.interfaces.labels as labels

pylogger = global_config.pylogger
auto_resolve = base_facade.auto_resolve


class BaseExample(base.Base):

    @auto_resolve(labels.EXAMPLE)
    def method01(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.EXAMPLE)
    def method02(self, execution_type=None, component=None, **kwargs):
        pass
