import vmware.interfaces.switch_interface as switch_interface
import vmware.vsphere.vc.vc_soap_util as vc_soap_util
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.vsphere.vc_objects as vc_objects
import vmware
import pyVmomi as pyVmomi

vim = pyVmomi.vim
pylogger = global_config.pylogger


class VC55SwitchImpl(switch_interface.SwitchInterface):

    @classmethod
    def _args_filter(cls, kwargs):
        args = dict()
        for key in kwargs:
            if key not in {"client_object", "cls"}:
                args[key] = kwargs.get(key)
        return args

    @classmethod
    def remove_component(cls, client_object, component=None):
        """
        Removes a component on the switch.

        @type client_object: VDSwitchAPIClient instance
        @param client_object: VDSwitchAPIClient instance
        @type component: str
        @param component: Name of the component to be removed

        @rtype: str
        @return: Status of the operation
        """
        vds_mor = client_object.vds_mor
        for portgroup in vds_mor.portgroup:
            if portgroup.name == component:
                return vc_soap_util.get_task_state(
                    portgroup.Destroy_Task())

    @classmethod
    def set_mtu(cls, client_object, mtu=None):
        """
        Sets the mtu for the switch.

        @type client_object: VDSwitchAPIClient instance
        @param client_object; VDSwitchAPIClient instance
        @type mtu: int
        @param mtu: Maximum transmission unit for the switch

        @rtype: str
        @return: Status of the operation
        """
        vmware_dvs_spec = vim.dvs.VmwareDistributedVirtualSwitch.ConfigSpec()
        vds_mor = client_object.vds_mor
        vmware_dvs_spec.configVersion = vds_mor.config.configVersion
        vmware_dvs_spec.maxMtu = mtu
        task = client_object.vds_mor.ReconfigureDvs_Task(vmware_dvs_spec)
        return vc_soap_util.get_task_state(task)

    @classmethod
    def configure_mirror_session(cls, client_object, description=None,
                                 enabled=None, encap_vlan_id=None,
                                 session_id=None, mirrored_packet_length=None,
                                 name=None, normal_traffic_allowed=None,
                                 sampling_rate=None, session_type=None,
                                 strip_original_vlan=None, dest_ip=None,
                                 dest_port_key=None, dest_vlans=None,
                                 dest_uplink_port_name=None,
                                 dest_wildcard_port_connected_type=None,
                                 src_ip_rx=None, src_port_key_rx=None,
                                 src_uplink_port_name_rx=None,
                                 src_vlans_rx=None,
                                 src_wildcard_port_connected_type_rx=None,
                                 src_ip_tx=None, src_port_key_tx=None,
                                 src_uplink_port_name_tx=None,
                                 src_vlans_tx=None, operation=None,
                                 src_wildcard_port_connected_type_tx=None):
        """
        Configures mirror session on the switch.

        @type client_object: client instance
        @param client_object: VDSwitch client instance
        @type description: str
        @param description: Description of the session
        @type enabled: bool
        @param enabled: Flag to specify if session is enabled
        @type encap_vlan_id: int
        @param encap_vlan_id: VLAN ID used to encapsulate mirrored traffic
        @type session_id: str
        @param session_id: Identifier of the session
        @type mirrored_packet_length: int
        @param mirrored_packet_length: Size of each frame to mirror
        @type name: str
        @param name: Display name of the session
        @type normal_traffic_allowed: bool
        @param normal_traffic_allowed: Flag to specify if destination ports
            can send and receive normal traffic.
        @type sampling_rate: int
        @param sampling_rate: Sampling rate of the session
        @type session_type: str
        @param session_type: Type of the session
        @type strip_original_vlan: bool
        @param strip_original_vlan: Flag to specifiy if original VLAN tag is
            to be stripped.
        @type dest_ip: list
        @param dest_ip: IP address for the destination of encapsulated remote
            mirror source session
        @type dest_port_key: list
        @param dest_port_key: Individual ports to participate in the
            Distributed Port Mirroring session
        @type dest_vlans: list
        @param dest_vlans: Vlan Ids for ingress source of Remote Mirror
            destination session
        @type dest_uplink_port_name: list
        @param dest_uplink_port_name: Uplink ports used as destination ports
            to participate in the Distributed Port Mirroring session
        @type dest_wildcard_port_connected_type: list
        @param dest_wildcard_port_connected_type: Wild card specification
            for source ports participating in the Distributed Port Mirroring
            session
        @type src_ip_rx: list
        @param src_ip_rx: IP address for the destination of encapsulated
            remote mirror source session
        @type src_port_key_rx: list
        @param src_port_key_rx: Individual ports to participate in the
            Distributed Port Mirroring session
        @type src_uplink_port_name_rx: list
        @param src_uplink_port_name_rx: Uplink ports used as destination
            ports to participate in the Distributed Port Mirroring session
        @type src_vlans_rx: list
        @param src_vlans_rx: Vlan Ids for ingress source of Remote Mirror
            destination session
        @type src_wildcard_port_connected_type_rx: list
        @param src_wildcard_port_connected_type_rx: Wild card specification
            for source ports participating in the Distributed Port Mirroring
            session
        @type src_ip_tx: list
        @param src_ip_tx: IP address for the destination of encapsulated
            remote mirror source session
        @type src_port_key_tx: list
        @param src_port_key_tx: Individual ports to participate in the
        Distributed Port Mirroring session
        @type src_uplink_port_name_tx: list
        @param src_uplink_port_name_tx: Uplink ports used as destination ports
            to participate in the Distributed Port Mirroring session
        @type src_vlans_tx: list
        @param src_vlans_tx: Vlan Ids for ingress source of Remote Mirror
            destination session
        @type src_wildcard_port_connected_type_tx: list
        param src_wildcard_port_connected_type_tx: Wild card specification for
            source ports participating in the Distributed Port Mirroring
            session

        @rtype: str
        @return: Status of the operation.
        """
        param = cls._args_filter(locals())
        dvs = client_object.get_vmware_dvs_config_spec(**param)
        dvs.configVersion = client_object.vds_mor.config.configVersion
        task = client_object.vds_mor.ReconfigureDvs_Task(dvs)
        return vc_soap_util.get_task_state(task)

    @classmethod
    def configure_discovery_protocol(cls, client_object,
                                     mode=None, protocol=None):
        """
        Configures the discovery protocol on the switch.

        @type client_object: client instance
        @param client_object: VDSwitch client instance
        @type mode: str
        @param mode: Whether to advertise or listen
        @type protocol: str
        @param protocol: cdp or lldp

        @rtype: str
        @return: Status of the operation.
        """
        dvs = client_object.get_vmware_dvs_config_spec()
        dvs.configVersion = client_object.vds_mor.config.configVersion
        dvs.linkDiscoveryProtocolConfig = client_object.get_ldp_config_spec(
            mode=mode, protocol=protocol)
        task = client_object.vds_mor.ReconfigureDvs_Task(dvs)
        return vc_soap_util.get_task_state(task)

    @classmethod
    def get_discovery_protocol(cls, client_object):
        """
        Returns the discovery protocol currently running on the switch.

        @type client_object: client instance
        @param client_object: VDSwitch client instance

        @rype: str
        @return: Type of discovery protocol
        """
        vds_mor = client_object.vds_mor
        return vds_mor.config.linkDiscoveryProtocolConfig.protocol

    @classmethod
    def configure_ipfix(cls, client_object, active_flow_timeout=None,
                        collector_ip=None, collector_port=None,
                        idle_flow_timeout=None, internal_flows_only=None,
                        observation_domain_id=None, sampling_rate=None):
        """
        Configures ipfix on the switch.

        @type client_object: client instance
        @param client_object: VDSwitchAPIClient instance
        @type active_flow_timeout: int
        @param active_flow_timeout: Number of seconds after which "active"
            flows are forced to be exported to the collector. Legal value
            range is 60-3600. Default 60.
        @type collector_ip: str
        @param collector_ip: IP address for the ipfix collector, using IPv4
            or IPv6
        @type collector_port: int
        @param collector_port: Port for the ipfix collector
        @type idle_flow_timeout: int
        @param idle_flow_timeout: The number of seconds after which "idle"
            flows are forced to be exported to the collector
        @type internal_flows_only: bool
        @param internal_flows_only: Whether to limit analysis to traffic
            that has both source and destination served by the same host.
            Default false
        @type observation_domain_id: long
        @param observation_domain_id: Observation Domain Id for the ipfix
            collector.
        @type sampling_rate: int
        @param sampling_rate: The ratio of total number of packets to the
            number of packets analyzed. Set to 0 to disable sampling.
            Legal value range is 0-1000. Default 0.

        @rtype: str
        @return: Status of the operation.
        """
        dvs = client_object.get_vmware_dvs_config_spec()
        dvs.configVersion = client_object.vds_mor.config.configVersion
        ipfix = client_object.get_ipfix_config(
            active_flow_timeout=active_flow_timeout, collector_ip=collector_ip,
            collector_port=collector_port, idle_flow_timeout=idle_flow_timeout,
            internal_flows_only=internal_flows_only,
            observation_domain_id=observation_domain_id,
            sampling_rate=sampling_rate)
        dvs.ipfixConfig = ipfix
        task = client_object.vds_mor.ReconfigureDvs_Task(dvs)
        return vc_soap_util.get_task_state(task)

    @classmethod
    def add_pvlan_map(cls, client_object, operation=None,
                      primary_vlan_id=None, pvlan_type=None,
                      secondary_vlan_id=None):
        """
        Adds a pvlan map on the switch.

        @type client_object: VDSwitchAPIClient instance
        @param client_object: VDSwitchAPIClient instance
        @type operation: str
        @param operation: edit, add, or remove
        @type primary_vlan_id: int
        @param primary_vlan_id: The primary VLAN ID. The VLAN IDs of 0 and 4095
            are reserved and cannot be used in this property.
        @type secondary_vlan_id: int
        @param secondary_vlan_id: The secondary VLAN ID. The VLAN IDs of 0 and
            4095 are reserved and cannot be used in this property.
        @type pvlan_type: str
        @param pvlan_type: community, isolated, or promiscuous

        @rtype: str
        @return: status of the operation.
        """
        dvs = client_object.get_vmware_dvs_config_spec()
        dvs.configVersion = client_object.vds_mor.config.configVersion
        pvlan = client_object.get_pvlan_config_spec(
            operation=operation, primary_vlan_id=primary_vlan_id,
            secondary_vlan_id=secondary_vlan_id, pvlan_type=pvlan_type)
        dvs.pvlanConfigSpec = pvlan
        task = client_object.vds_mor.ReconfigureDvs_Task(dvs)
        return vc_soap_util.get_task_state(task)

    @classmethod
    def enable_network_resource_mgmt(cls, client_object, enable=None):
        """
        Enables/Disables Network I/O Resource Management.

        @type: VDSwitchAPIClient instance
        @param: VDSwitchAPIClient instance
        @type enable: bool
        @param enable: Flag to specify if network I/O RM is to be enabled.

        @rtype: NoneType
        @return: None
        """
        client_object.vds_mor.EnableNetworkResourceManagement(
            enable)

    @classmethod
    def edit_max_proxy_switchports(cls, client_object,
                                   hostname=None, maxports=None):
        """
        Edit the maximum proxy ports for a host.

        @type client_object: VDSwitchAPIClient instance
        @param client_object: VDSwitchAPIClient instance
        @type hostname: str
        @param hostname: Hostname
        @type maxports: int
        @param maxports: Specifies the number of proxy ports.

        @rtype: str
        @return: Status of the operation.
        """
        vds_mor = client_object.vds_mor
        for member in vds_mor.config.host:
            if member.config.host.name == hostname:
                host_mor = member.config.host
                break
        host_member_config = client_object.get_host_member_config(
            host_mor=host_mor, maxports=maxports)
        dvs = client_object.get_dvs_config_spec()
        dvs.configVersion = client_object.vds_mor.config.configVersion
        dvs.host = [host_member_config]
        task = client_object.vds_mor.ReconfigureDvs_Task(dvs)
        return vc_soap_util.get_task_state(task)

    @classmethod
    def set_nic_teaming(cls, client_object, check_beacon=None,
                        check_duplex=None, notify_switches=None,
                        policy=None, reverse_policy=None,
                        rolling_order=None, active_uplink_port=None,
                        standby_uplink_port=None):
        """
        Configure nic teaming policy on the switch.

        @type client_object: VDSwitchAPIClient instance
        @param client_object: VDSwitchAPIClient instance
        @type check_beacon: bool
        @param check_beacon: The flag to indicate whether or not to enable this
            property to enable beacon probing as a method to validate the link
            status of a physical network adapter
        @type check_duplex: bool
        @param check_duplex: The flag to indicate whether or not to use the
            link duplex reported by the driver as link selection criteria
        @type notify_switches: bool
        @param notify_switches: Flag to specify whether or not to notify the
            physical switch if a link fails
        @type policy: str
        @param policy: failover_explicit, loadbalance_ip, loadbalance_loadbased
            ,loadbalance_srcid, loadbalance_srcmac
        @type reverse_policy: bool
        @param reverse_policy: The flag to indicate whether or not the teaming
            policy is applied to inbound frames as well
        @type rolling_order: bool
        @param rolling_order: The flag to indicate whether or not to use a
            rolling policy when restoring links
        @type active_uplink_port: str
        @param active_uplink_port: List of active uplink ports used for load
            balancing
        @type standby_uplink_port: str
        @param standby_uplink_port: Standby uplink ports used for failover

        @rtype: str
        @return: Status of the operation.
        """
        failure = client_object.get_dvs_failure_criteria(
            check_beacon=check_beacon, check_duplex=check_duplex)
        notify = client_object.get_notify_switches(
            notify_switches)
        policy = client_object.get_uplink_port_policy(policy)
        reverse = client_object.get_reverse_policy(reverse_policy)
        rolling = client_object.get_rolling_policy(rolling_order)
        uplink_port_order = client_object.get_vmware_uplink_port_order_policy(
            active_uplink_port=active_uplink_port,
            standby_uplink_port=standby_uplink_port)
        port_config = client_object.get_vmware_port_config_policy()
        uplink_teaming = client_object.get_uplink_port_teaming_policy(
            failure=failure, notify=notify, policy=policy,
            reverse=reverse, rolling=rolling,
            uplink_port_order=uplink_port_order)
        port_config.uplinkTeamingPolicy = uplink_teaming
        dvs = client_object.get_dvs_config_spec()
        dvs.defaultPortConfig = port_config
        dvs.configVersion = client_object.vds_mor.config.configVersion
        task = client_object.vds_mor.ReconfigureDvs_Task(dvs)
        return vc_soap_util.get_task_state(task)

    @classmethod
    def bind_pnic(cls, client_object, pnic=None, hostname=None,
                  uplink_portgroup=None, uplink_port=None, operation=None):
        """
        @type client_object: VDSwitchAPIClient instance
        @param client_object: VDSwitchAPIClient instance
        @type pnic: str
        @param pnic: Name of the pnic
        @type hostname: str
        @param hostname: Host name
        @type uplink_portgroup: str
        @param uplink_portgroup: Uplink portgroup to bind to
        @type uplink_port: str
        @param uplink_port: Uplink port to bind to
        @type operation: str
        @param operation: add, remove, edit

        @rtype: str
        @return: Status of the operation
        """
        vds_mor = client_object.vds_mor
        for member in vds_mor.config.host:
            if member.config.host.name == hostname:
                host_mor = member.config.host
                break
            else:
                host_mor = None
        if host_mor is None:
            raise Exception("Host not found on %s" % (client_object.name))
        pnic_spec = client_object.get_dvs_host_pnic_spec(
            pnic=pnic, uplink_portgroup=uplink_portgroup,
            uplink_port=uplink_port)
        backing = client_object.get_dvs_host_pnic_backing(pnic_spec)
        host_member_config = client_object.get_host_member_config(
            host_mor=host_mor, backing=backing)
        dvs = client_object.get_dvs_config_spec()
        dvs.host = [host_member_config]
        dvs.configVersion = client_object.vds_mor.config.configVersion
        task = client_object.vds_mor.ReconfigureDvs_Task(dvs)
        return vc_soap_util.get_task_state(task)

    @classmethod
    def remove_host(cls, client_object, hostname=None):
        """
        Removes a host from the switch.

        @type client_object: VDSwitchAPIClient instance
        @param client_object: VDSwitchAPIClient instance
        @type hostname: str
        @param hostname: Name of the host

        @rtype: str
        @return: Status of the operation
        """
        host_mor = None
        vds_mor = client_object.vds_mor
        for member in vds_mor.config.host:
            if member.config.host.name == hostname:
                host_mor = member.config.host
                break
            else:
                host_mor = None
        if host_mor is None:
            raise Exception("Host not found on %s" % (client_object.name))
        dvs = client_object.get_dvs_config_spec()
        host_member_config = client_object.get_host_member_config(
            host_mor=host_mor, operation="remove")
        dvs.host = [host_member_config]
        dvs.configVersion = client_object.vds_mor.config.configVersion
        task = client_object.vds_mor.ReconfigureDvs_Task(dvs)
        return vc_soap_util.get_task_state(task)

    @classmethod
    def remove_vspan_session(cls, client_object, session_id=None):
        """
        Removes the specified mirror session.

        @type client_object: VDSwitchAPIClient instance
        @param client_object: VDSwitchAPIClient instance
        @type session_id: str
        @param session_id: ID of the mirrored session

        @rtype: str
        @return: Status of the operation
        """
        dvs = client_object.get_vmware_dvs_config_spec()
        dvs.configVersion = client_object.vds_mor.config.configVersion
        vspan_spec = vim.dvs.VmwareDistributedVirtualSwitch.VspanConfigSpec()
        vspan_session = vim.dvs.VmwareDistributedVirtualSwitch.VspanSession()
        vspan_session.key = session_id
        vspan_spec.vspanSession = vspan_session
        vspan_spec.operation = "remove"
        dvs.vspanConfigSpec = [vspan_spec]
        task = client_object.vds_mor.ReconfigureDvs_Task(dvs)
        return vc_soap_util.get_task_state(task)

    @classmethod
    def list_mirror_sessions(cls, client_object):
        """
        Lists the mirror sessions on the switch.

        @type client_object: VDSwitchAPIClient instance
        @param client_object: VDSwitchAPIClient instance

        @rtype: list
        @return: List keys of mirror sessions
        """
        vds_mor = client_object.vds_mor
        sessions = []
        for session in vds_mor.config.vspanSession:
            sessions.append(session.key)
        return sessions

    #TODO: Once design has been fixed for bulk operation
    @classmethod
    def remove_hosts(cls, client_object, hosts=None):
        """
        Removes hosts from the switch.

        @type client_object: VDSwitchAPIClient instance
        @param client_object: VDSwitchAPIClient instance
        @type hosts: list
        @param hosts: Name of the hosts

        @rtype: str
        @return: Status of the operation
        """
        host_config = []
        host_mor = None
        vds_mor = client_object.vds_mor
        members_name = []
        for member in vds_mor.config.host:
            members_name.append(member.config.host.name)
        for host in hosts:
            if host in members_name:
                host_member_config = client_object.get_host_member_config(
                    host_mor=host_mor, operation="remove")
                host_config.append(host_member_config)
            else:
                pylogger.error("%r not found" % host)
        if len(host_config) == 0:
            pylogger.error("No hosts found on the switch")
            return constants.Result.FAILURE
        dvs = client_object.get_dvs_config_spec()
        dvs.host = host_config
        dvs.configVersion = client_object.vds_mor.config.configVersion
        task = client_object.vds_mor.ReconfigureDvs_Task(dvs)
        vc_soap_util.get_task_state(task)
