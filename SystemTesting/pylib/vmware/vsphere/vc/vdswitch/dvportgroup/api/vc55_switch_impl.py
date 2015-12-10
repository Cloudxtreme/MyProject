import vmware.interfaces.switch_interface as switch_interface
import vmware.common.global_config as global_config
import vmware.vsphere.vc.vc_soap_util as vc_soap_util
import vmware.vsphere.vc.vdswitch.api.vc55_switch_impl as vc55_switch_impl

SwitchImpl = vc55_switch_impl.VC55SwitchImpl
pylogger = global_config.pylogger


class VC55SwitchImpl(switch_interface.SwitchInterface):

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
        return SwitchImpl.set_nic_teaming(
            client_object.parent, check_beacon=check_beacon,
            check_duplex=check_duplex, policy=policy,
            notify_switches=notify_switches,
            reverse_policy=reverse_policy, rolling_order=rolling_order,
            active_uplink_port=active_uplink_port,
            standby_uplink_port=standby_uplink_port)
