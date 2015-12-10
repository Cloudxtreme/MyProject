import vmware.nsx.manager.nsxbase as nsxbase
import vmware.common.versions as versions


class Redistribution(nsxbase.NSXBase):
    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.AVALANCHE
