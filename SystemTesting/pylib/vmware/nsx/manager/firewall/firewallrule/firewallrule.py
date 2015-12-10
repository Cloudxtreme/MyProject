import vmware.common.versions as versions
import vmware.nsx.manager.firewall.firewall as firewall
import vmware.nsx.manager.nsxbase as nsxbase


class FirewallRule(nsxbase.NSXBase, firewall.Firewall):

    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.AVALANCHE

    def __init__(self, parent=None, id_=None):
        if id_:
            id_ = str(id_)
        super(FirewallRule, self).__init__(parent=parent, id_=id_)
