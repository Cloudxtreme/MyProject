class RouterInterface(object):

    @classmethod
    def get_logical_router_ports(
            cls, client_object, logical_router_id=None, **kwargs):
        """ Interface to get all logical router port data on logical router"""
        raise NotImplementedError

    @classmethod
    def get_logical_router_port_info(
            cls, client_object, logical_router_id=None, port_id=None,
            **kwargs):
        """ Interface to get data for a given port on logical router"""
        raise NotImplementedError

    @classmethod
    def get_logical_router_id(
            cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_logical_routers(
            cls, client_object, **kwargs):
        """ Interface to get all logical router data"""
        raise NotImplementedError

    @classmethod
    def get_route_table(
            cls, client_object, logical_router_id=None, **kwargs):
        """ Interface to get routing table of a logical router"""
        raise NotImplementedError

    @classmethod
    def get_dr_arp_table(
            cls, client_object, logical_router_id=None, port_id=None,
            **kwargs):
        """ Interface to get arp table for the DR of logical router"""
        raise NotImplementedError

    @classmethod
    def read_next_hop(
            cls, client_object, logical_router_id=None,
            source_ip=None, destination_ip=None, **kwargs):
        """ Interface to get next hop from DR for given src/dest ips """
        raise NotImplementedError

    @classmethod
    def is_master_for_lr(
            cls, client_object, logical_router_id=None, **kwargs):
        """ Interface to check if a controller is master for given lrouter """
        raise NotImplementedError

    @classmethod
    def get_ip(cls, client_object, **kwargs):
        """ Interface to get the table entries for (BGP/forwarding) """
        raise NotImplementedError

    @classmethod
    def get_configuration_bgp(cls, client_object, **kwargs):
        """ Interface to get bgp configuration"""
        raise NotImplementedError

    @classmethod
    def get_ip_route(cls, client_object, **kwargs):
        """ Interface to get ip route """
        raise NotImplementedError

    @classmethod
    def get_ip_bgp_neighbors(cls, client_object, **kwargs):
        """ Interface to get bgp neighbors information """
        raise NotImplementedError

    @classmethod
    def clear_ip_bgp(cls, client_object, **kwargs):
        """ Interface to clear bgp configuration """
        raise NotImplementedError

    @classmethod
    def get_nat_rules_statistics(cls, client_object, rule_id, **kwargs):
        """
        Interface to get router nat rule statistics """
        raise NotImplementedError

    @classmethod
    def get_status(cls, client_object, **kwargs):
        """
        Interface to get router status """
        raise NotImplementedError

    @classmethod
    def enable_routing(cls, client_object, hostname=None, password=None,
                       en_password=None, **kwargs):
        """
        Interface to enable the routing daemon, if any.
        """
        raise NotImplementedError

    @classmethod
    def disable_routing(cls, client_object, clear_config=False, **kwargs):
        """
        Interface to disable the routing daemon, if any.
        """
        raise NotImplementedError

    @classmethod
    def configure_interface(cls, client_object, interface_name=None,
                            ip_address=None, cidr=None, update=False,
                            **kwargs):
        """
        Interface to configure interface IP address and other parameters
        for the router
        """
        raise NotImplementedError

    @classmethod
    def enable_bgp(cls, client_object, **kwargs):
        """
        Interface to enable BGP on the router
        """
        raise NotImplementedError

    @classmethod
    def configure_bgp(cls, client_object, **kwargs):
        """
        Interface to configure BGP parameters on the router
        """
        raise NotImplementedError

    @classmethod
    def disable_bgp(cls, client_object, **kwargs):
        """
        Interface to disable BGP on the router
        """
        raise NotImplementedError
