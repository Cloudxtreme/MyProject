import vmware.nsx.controller.cmd.controller_cmd_client as controller_cmd_client
import vmware.interfaces.switch_interface as switch_interface


class NSX70SwitchImpl(switch_interface.SwitchInterface):

    @classmethod
    def get_arp_table(cls, client_object, get_arp_table=None,
                      switch_vni=None, endpoints=None):
        """
        Gets the ARP entries related to a VNI from either the master controller
        or the transport nodes based on the endpoints passed in.

        For controller objects, we expect that there will be only one master
        controller responsible for ARP entries and if product reflects that
        more than one controller is responsible for VNI, then that is raised as
        an error since that is a product bug.

        @type client_object: LogicalSwitchCMDClient
        @param client_object: Client object (TBD: might be unused here).
        @type switch_vni: int
        @param switch_vni: VNI for the switch.
        @type get_arp_table: list
        @param get_arp_table: A list of dicts where each dict contains mac
            and ip information. It is not used. It is here just to maintain the
            old vdnet semantics where the user provided hash is relayed to the
            query method as well.
        @type endpoints: list
        @rtpe: ARPTableSchema
        """
        # The endpoints are used for querying the state on those
        # objects and logical switch's CMD client is just a dummy client.
        _ = client_object
        queried_object = cls._get_query_object(endpoints,
                                               switch_vni)
        return queried_object.get_arp_table(switch_vni=switch_vni)

    @classmethod
    def _get_query_object(cls, endpoints, switch_vni):
        """
        Helper method to return the right object to be queried for data.

        This method determines which host should be queried for getting MAC/ARP
        table. If endpoints length is greater than 1, then method
        assumes that all passed in objects are controller objects and then
        determines the master controller for that vni, otherwise it returns the
        one and only element in the verification objects list.
        @param endpoints: List of objects on which the query needs
            to be made. If multiple entries are found in the list then logic to
            figure out master controller is triggered.
        @type verification_onjects: list
        @param switch_vni: VNI of the logical switch.
        @type switch_vni: int
        """
        queried_obj = None
        if len(endpoints) > 1:
            # Check that all objects are of type controller.
            all_controllers = [
                True for host_elem in endpoints if
                isinstance(host_elem,
                           controller_cmd_client.ControllerCMDClient)]
            if not all(all_controllers):
                raise TypeError("Since the list contains more than 1 element, "
                                "all elements were expected to be of "
                                "controller cli clients, got %r" %
                                endpoints)
            # Controller verification invloves determing which controller is
            # the master controller.
            master_controllers = []
            for controller in endpoints:
                if controller.is_master_for_vni(switch_vni=switch_vni):
                    master_controllers.append(controller)
            if not master_controllers:
                raise AssertionError('No controller is identified as the '
                                     'master controller for vni %r. Expected '
                                     'at least one master controller.' %
                                     switch_vni)
            if len(master_controllers) > 1:
                raise AssertionError('More than one controllers [%r] have '
                                     'been identified as master controllers '
                                     'for vni %r. Expected only one '
                                     'controller to be the master controller' %
                                     (master_controllers, switch_vni))
            queried_obj = master_controllers[0]
        else:
            queried_obj = endpoints[0]
        return queried_obj

    @classmethod
    def get_mac_table(cls, client_object, get_mac_table=None,
                      switch_vni=None, endpoints=None):
        """
        Gets the MAC entries related to a VNI from either the master controller
        or the transport nodes based on the endpoints passed in.

        @type client_object: LogicalSwitchCMDClient
        @param client_object: Client object (TBD: might be unused here).
        @type switch_vni: int
        @param switch_vni: VNI for the switch.
        @type get_mac_table: list
        @param get_mac_table: A list of dicts where each dict contains
            inner_mac and outer_ip information. It is not used in this method.
            It is here just to maintain the old vdnet semantics where the user
            provided hash is relayed to the query method as well.
        @type endpoints: list
        @param endpoints: Host object(s) which implement the
            interface for retrieving the ARP table.
        @rtpe: MACTableSchema
        """
        # The endpoints are used for querying the state on those
        # objects and logical switch's CMD client is just a dummy client.
        _ = client_object
        queried_object = cls._get_query_object(endpoints,
                                               switch_vni)
        return queried_object.get_mac_table(switch_vni=switch_vni)

    @classmethod
    def get_vtep_table(cls, client_object, get_vtep_table=None,
                       switch_vni=None, endpoints=None, host_switch_name=None):
        """
        Gets the Vtep entries related to a VNI from either the controller
        or the transport nodes based on the endpoints passed in.

        @type client_object: LogicalSwitchCMDClient
        @param client_object: Client object (TBD: might be unused here).
        @type switch_vni: int
        @param switch_vni: VNI for the switch.
        @type get_vtep_table: list
        @param get_vtep_table: A list of dicts where each dict contains
            vtep_ip information. It is not used in this method.
            It is here just to maintain the old vdnet semantics where the user
            provided hash is relayed to the query method as well.
        @type endpoints: list
        @param endpoints: Host object(s) which implement the
            interface for retrieving the ARP table.
        @rtpe: MACTableSchema
        """
        # The endpoints are used for querying the state on those
        # objects and logical switch's CMD client is just a dummy client.
        _ = client_object
        queried_object = cls._get_query_object(endpoints,
                                               switch_vni)
        return queried_object.get_vtep_table(switch_vni=switch_vni,
                                             host_switch_name=host_switch_name)

    @classmethod
    def get_stats_table(cls, client_object, get_stats_table=None,
                        switch_vni=None, endpoints=None):
        """
        Gets the stats entries related to a VNI from either the controller
        or the transport nodes based on the endpoints passed in.

        @type client_object: LogicalSwitchCMDClient
        @param client_object: Client object (TBD: might be unused here).
        @type switch_vni: int
        @param switch_vni: VNI for the switch.
        @type get_vtep_table: list
        @param get_stats_table: A list of one dict with each key contains
            stats information. It is not used in this method.
            It is here just to maintain the old vdnet semantics where the user
            provided hash is relayed to the query method as well.
        @type endpoints: list
        @param endpoints: CCP/Host object(s) which implement the
            interface for retrieving the stats table.
        @rtpe: MACTableSchema
        """
        # The endpoints are used for querying the state on those
        # objects and logical switch's CMD client is just a dummy client.
        _ = client_object
        queried_object = cls._get_query_object(endpoints,
                                               switch_vni)
        return queried_object.get_stats_table(switch_vni=switch_vni)
