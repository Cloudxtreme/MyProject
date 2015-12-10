import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.interfaces.labels as labels

auto_resolve = base_facade.auto_resolve


class Verification(base.Base):

    def __init__(self, parent=None):
        self.parent = parent

    @auto_resolve(labels.VERIFICATION)
    def generate_capture_file_name(self, tool=None, **kwargs):
        pass

    @auto_resolve(labels.VERIFICATION)
    def start_capture(self, tool=None, **kwargs):
        pass

    @auto_resolve(labels.VERIFICATION)
    def stop_capture(self, tool=None, **kwargs):
        pass

    @auto_resolve(labels.VERIFICATION)
    def extract_capture_results(self, tool=None, **kwargs):
        pass

    @auto_resolve(labels.VERIFICATION)
    def delete_capture_file(self, tool=None, **kwargs):
        pass
