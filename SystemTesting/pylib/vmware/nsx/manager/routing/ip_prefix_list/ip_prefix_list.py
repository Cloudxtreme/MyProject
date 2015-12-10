import vmware.common.versions as versions
import vmware.nsx.manager.nsxbase as nsxbase


class IPPrefixList(nsxbase.NSXBase):
    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.BUMBLEBEE