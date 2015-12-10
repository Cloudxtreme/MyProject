import vmware.nsx.controller.cli.controller_cli_client as controller_cli_client
import vmware.interfaces.router_interface as router_interface


class NSX70RouterImpl(router_interface.RouterInterface):

    @classmethod
    def get_logical_router_ports(cls, client_object,
                                 get_logical_router_ports=None,
                                 get_dhcp_relay_info=None,
                                 logical_router_id=None, endpoints=None):
        """
        Get the information for all LR Ports (i.e DR LIFs) for the given LR
        instance

        @type client_object: LogicalRouterCLIClient
        @param client_object: Client object
        @type instance_name: String
        @param logical_router_id: VDR id.
        @type get_logical_router_ports: list
        @param get_logical_router_ports: A list of dicts. It is not used.
        @type endpoints: list
        @rtpe: LogicalRouterPortSchema
        """
        # The endpoints are used for querying the state on those
        # objects and logical router's CLI client is just a dummy client.
        _ = client_object
        # TODO (Mayur): Pass correct input_param to _get_query_object()
        # once is_master_for_lr() is implemented.
        queried_object = cls._get_query_object(endpoints)
        return queried_object.get_logical_router_ports(
            logical_router_id=logical_router_id,
            get_dhcp_relay_info=get_dhcp_relay_info)

    @classmethod
    def get_route_table(cls, client_object, logical_router_id=None,
                        get_route_table=None, endpoints=None):
        """
        Get the routing table for the given LR instance.

        @type client_object: LogicalRouterCLIClient
        @param client_object: Client object
        # XXX(Dhaval): on L17, type is instance_name. Shouldn't it be id ?
        @type logical_router_id: String
        @param logical_router_id: VDR id.
        @type get_route_table: list
        @param get_route_table: A list of dicts. It is not used.
        @type endpoints: list
        @rtpe: RouteTableSchema
        """
        # The endpoints are used for querying the state on those
        # objects and logical router's CLI client is just a dummy client.
        _, _ = client_object, get_route_table
        # TODO (Mayur): Pass correct input_param to _get_query_object()
        # once is_master_for_lr() is implemented.
        queried_object = cls._get_query_object(endpoints)
        return queried_object.get_route_table(
            logical_router_id=logical_router_id)

    @classmethod
    def read_next_hop(cls, client_object, logical_router_id=None,
                      source_ip=None, destination_ip=None, read_next_hop=None,
                      endpoints=None, **kwargs):
        """
        Get the next hop for given source and destination ip.

        @type client_object: LogicalRouterCLIClient
        @param client_object: Client object
        @type logical_router_id: String
        @param logical_router_id: VDR name.
        @type read_next_hop: list
        @param read_next_hop: A list of dicts. It is not used.
        @type endpoints: list
        @rtpe: RouteTableSchema
        """
        # The endpoints are used for querying the state on those
        # objects and logical router's CLI client is just a dummy client.
        _, _ = client_object, read_next_hop
        # TODO (Mayur): Pass correct input_param to _get_query_object()
        # once is_master_for_lr() is implemented.
        queried_object = cls._get_query_object(endpoints)
        return queried_object.read_next_hop(
            logical_router_id=logical_router_id, source_ip=source_ip,
            destination_ip=destination_ip, **kwargs)

    @classmethod
    def get_dr_arp_table(cls, client_object, logical_router_id=None,
                         lr_port_id=None, get_dr_arp_table=None,
                         endpoints=None):
        """
        Get the routing table for the given LR instance.

        @type client_object: LogicalRouterCLIClient
        @param client_object: Client object
        @type logical_router_id: String
        @param logical_router_id: VDR id.
        @type lr_port_id: String
        @param lr_port_id: VDR lif id.
        @type get_dr_arp_table: list
        @param get_dr_arp_table: A list of dicts. It is not used.
        @type endpoints: list
        @rtpe: RouteTableSchema
        """
        # The endpoints are used for querying the state on those
        # objects and logical router's CLI client is just a dummy client.
        _, _ = client_object, get_dr_arp_table
        # TODO (Mayur): Pass correct input_param to _get_query_object()
        # once is_master_for_lr() is implemented.
        queried_object = cls._get_query_object(endpoints)
        return queried_object.get_dr_arp_table(
            logical_router_id=logical_router_id,
            lr_port_id=lr_port_id)

    @classmethod
    def _get_query_object(cls, endpoints, input_param=None):
        """
        Helper method to return the right object to be queried for data.

        This method determines which host should be queried for getting the
        desired table. If endpoints list has more than 1 element, then method
        assumes that all passed in objects are controller objects and along
        with this if an input parameter is provided, it chooses the master
        controller based on the input else the method returns the first
        controller from the list.
        In all other cases it returns one and only element from the endpoints
        list.
        @param endpoints: List of objects on which the query needs
            to be made. If multiple entries are found and input_param is
            provided then logic to figure out master controller is triggered.
        @type verification_onjects: list
        @param input_param: Logical router Id.
        @type input_param: string.
        """
        queried_obj = None
        if len(endpoints) > 1:
            # Check that all objects are of type controller.
            all_controllers = [
                True for host_elem in endpoints if
                isinstance(host_elem,
                           controller_cli_client.ControllerCLIClient)]
            if not all(all_controllers):
                raise TypeError("Since the list contains more than 1 element, "
                                "all elements were expected to be of "
                                "controller cli clients, got %r" %
                                endpoints)
            if input_param:
                # XXX(Dhaval): If an input parameter is provided (i.e. LR Id)
                # then we need to decide if this controller is the master for
                # that LR and then return the master controller.
                master_controllers = []
                for controller in endpoints:
                    # TODO(Mayur, Dhaval): Implement is_master_for_lr() once
                    # the support for identifying the master controller of a
                    # LR based on LR Id is available.
                    if controller.is_master_for_lr(lr_id=input_param):
                        master_controllers.append(controller)
                if not master_controllers:
                    raise AssertionError('No controller is identified as the '
                                         'master controller for given LR %r. '
                                         'Expected at least one master '
                                         'controller.' % input_param)
                if len(master_controllers) > 1:
                    raise AssertionError('More than one controllers [%r] has '
                                         'been identified as master for the '
                                         'given LR %r. Expected only one to '
                                         'be the master controller' %
                                         (master_controllers, input_param))
                queried_obj = master_controllers[0]
            else:
                # XXX(Dhaval): If no input parameter is provided, we can use
                # any controller since all controllers in a cluster will have
                # all LR info.
                queried_obj = endpoints[0]
        else:
            queried_obj = endpoints[0]
        return queried_obj

    @classmethod
    def get_logical_routers(cls, client_object, get_logical_routers=None,
                            endpoints=None):
        """
        """
        _ = client_object
        # TODO (Mayur): Pass correct input_param to _get_query_object()
        # once is_master_for_lr() is implemented.
        queried_object = cls._get_query_object(endpoints)
        return queried_object.get_logical_routers()

    @classmethod
    def get_logical_router_port_info(cls, client_object,
                                     get_logical_router_port_info=None,
                                     logical_router_id=None, port_id=None,
                                     endpoints=None):
        """
        Get the information for a given LR Port (i.e DR LIF) for the given LR
        instance
        """
        _ = client_object
        # TODO (Mayur): Pass correct input_param to _get_query_object()
        # once is_master_for_lr() is implemented.
        queried_object = cls._get_query_object(endpoints)
        return queried_object.get_logical_router_port_info(
            logical_router_id=logical_router_id, port_id=port_id)
