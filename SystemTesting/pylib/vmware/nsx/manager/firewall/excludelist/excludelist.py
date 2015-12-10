import vmware.common.versions as versions
import vmware.nsx.manager.firewall.firewall as firewall
import vmware.nsx.manager.nsxbase as nsxbase


class ExcludeList(nsxbase.NSXBase, firewall.Firewall):

    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.AVALANCHE
