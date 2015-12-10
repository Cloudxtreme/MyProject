import vmware.common.global_config as global_config
import vmware.interfaces.appliance_interface as appliance_interface

pylogger = global_config.configure_logger()


class Ubuntu1204ApplianceImpl(appliance_interface.ApplianceInterface):
    """Appliance management class for Ubuntu."""

    @classmethod
    def regenerate_certificate(cls, client_object, status=None):
        """
        Regenerates the certificate of the appliance

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @rtype: NonType
        @return: None
        """

        pid_cmd = "ps aux | grep openvswitch | grep vtep | awk '{print $2}'"
        old_pid = client_object.connection.request(pid_cmd).response_data

        ovs_cmd = 'ovs-pki init --force'
        client_object.connection.request(ovs_cmd)
        mv_cmd = 'mv /var/lib/openvswitch/pki/switchca/cacert.pem '
        mv_cmd = mv_cmd + '/etc/openvswitch/ovsclient-cert.pem'
        client_object.connection.request(mv_cmd)
        mv_cmd = 'mv /var/lib/openvswitch/pki/switchca/private/cakey.pem '
        mv_cmd = mv_cmd + '/etc/openvswitch/ovsclient-privkey.pem'
        client_object.connection.request(mv_cmd)
        restart_cmd = 'service openvswitch-switch restart'
        client_object.connection.request(restart_cmd)
        restart_cmd = 'service openvswitch-vtep restart'
        client_object.connection.request(restart_cmd)

        new_pid = client_object.connection.request(pid_cmd).response_data

        if str(old_pid) == str(new_pid):
            raise ValueError('Service was not restarted.')
