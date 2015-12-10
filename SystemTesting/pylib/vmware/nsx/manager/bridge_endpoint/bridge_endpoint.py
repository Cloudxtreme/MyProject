import vmware.base.bridge as bridge
import vmware.common.versions as versions


class BridgeEndpoint(bridge.Bridge):
    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.AVALANCHE

    def __init__(self, parent=None, id_=None):
        super(BridgeEndpoint, self).__init__(parent=parent)
        self.id_ = id_

    def get_id(self):
        return self.id_
