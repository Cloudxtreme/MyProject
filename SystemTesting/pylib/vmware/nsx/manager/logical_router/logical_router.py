import vmware.base.router as router
import vmware.nsx.manager.nsxbase as nsxbase


class LogicalRouter(nsxbase.NSXBase, router.Router):
    def get_logical_router_id(self):
        return self.id_
