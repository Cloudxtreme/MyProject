import vmware.nsx.manager.nsxbase as nsxbase
import vmware.common.versions as versions


class RoutingConfig(nsxbase.NSXBase):
    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.AVALANCHE
