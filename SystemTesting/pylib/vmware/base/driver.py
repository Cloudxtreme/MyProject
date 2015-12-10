import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.interfaces.labels as labels

auto_resolve = base_facade.auto_resolve


class Driver(base.Base):

    display_name = None
    description = None

    def __init__(self, parent=None):
        super(Driver, self).__init__()
        self.parent = parent

    @auto_resolve(labels.TEST)
    def verify_ui_component(self, test_name=None, **kwargs):
        """
        Verify the UI operation through UAS
        """
        pass
