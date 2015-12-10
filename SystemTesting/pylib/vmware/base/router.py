import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.common.global_config as global_config
import vmware.interfaces.labels as labels

pylogger = global_config.pylogger
auto_resolve = base_facade.auto_resolve


class Router(base.Base):

    @auto_resolve(labels.ROUTER)
    def get_ospf_config_table(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.ROUTER)
    def get_logical_router_ports(self, execution_type=None,
                                 logical_router_id=None, **kwargs):
        pass

    @auto_resolve(labels.ROUTER)
    def get_logical_router_port_info(self, execution_type=None,
                                     logical_router_id=None,
                                     port_id=None, **kwargs):
        pass

    @auto_resolve(labels.ROUTER)
    def get_logical_router_id(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.ROUTER)
    def get_route_table(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.ROUTER)
    def get_dr_arp_table(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.ROUTER)
    def get_logical_routers(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.ROUTER)
    def read_next_hop(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.ROUTER)
    def get_nat_rules_statistics(self, execution_type=None, rule_id=None,
                                 **kwargs):
        pass

    @auto_resolve(labels.ROUTER)
    def get_status(self, execution_type=None, **kwargs):
        pass
