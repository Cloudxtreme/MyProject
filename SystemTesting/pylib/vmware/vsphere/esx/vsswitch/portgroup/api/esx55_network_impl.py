import vmware.interfaces.network_interface as network_interface
import vmware.common.global_config as global_config

import pyVmomi as pyVmomi

pylogger = global_config.pylogger
vim = pyVmomi.vim


class ESX55NetworkImpl(network_interface.NetworkInterface):

    @classmethod
    def edit_traffic_shaping(cls, client_object, avg_bandwidth=None,
                             burst_size=None, enabled=None,
                             peak_bandwidth=None):
        """
        Edits the traffic shaping policy for the portgroup.

        @type client_object: PortgroupAPIClient instance
        @param client_object: PortgroupAPIClient instance
        @type avg_bandwidth: long
        @param avg_bandwidth: The average bandwidth in bits per second if
            shaping is enabled on the port.
        @type burst_size: long
        @param burst_size: The maximum burst size allowed in bytes if
            shaping is enabled on the port.
        @type enabled: bool
        @param enabled: The flag to indicate whether or not traffic shaper is
            enabled on the port.
        @type peak_bandwidth: long
        @param peak_bandwidth: The peak bandwidth during bursts in bits per
            second if traffic shaping is enabled on the port.

        @rtype: NoneType
        @return: None
        """
        # While enabling, all params are mandatory
        network_sys = client_object.parent.parent.get_network_system()
        for pg in network_sys.networkInfo.portgroup:
            if pg.spec.name == client_object.name:
                pg_spec = pg.spec
                if enabled is not None:
                    pg_spec.policy.shapingPolicy.enabled = enabled
                if avg_bandwidth is not None:
                    pg_spec.policy.shapingPolicy.averageBandwidth = \
                        avg_bandwidth
                if burst_size is not None:
                    pg_spec.policy.shapingPolicy.burstSize = burst_size
                if peak_bandwidth is not None:
                    pg_spec.policy.shapingPolicy.peakBandwidth = peak_bandwidth
                try:
                    network_sys.UpdatePortGroup(client_object.name,
                                                pg_spec)
                    return
                except Exception as e:
                    raise Exception("Could not update policy on %r"
                                    % (client_object.name), e)
                pylogger.info("Successfully updated policy on %r"
                              % (client_object.name))
        raise Exception("Could not find specified portgroup")
