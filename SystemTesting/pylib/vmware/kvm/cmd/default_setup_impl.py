import vmware.common.global_config as global_config
import vmware.interfaces.setup_interface as setup_interface

pylogger = global_config.pylogger


class DefaultSetupImpl(setup_interface.SetupInterface):

    @classmethod
    def set_nsx_manager(cls, client_object, manager_ip=None,
                        manager_thumbprint=None):
        # WORKAROUND(gjayavelu): PR1294131
        # nsxcli is not yet ready. This block takes care of
        # configuring RMQ broker to connect manager and ESX
        command = '/automation/scripts/set-manager %s %s KVM' % (
            client_object.get_account_name(), manager_ip)
        pylogger.info("Executing NSX registration command: %s" % command)
        result = client_object.connection.request(command).response_data
        pylogger.info("result for set-manager: %s" % result)

    @classmethod
    def set_nsx_controller(cls, client_object, controller_ip=None,
                           node_id=None):
        # WORKAROUND(gjayavelu): PR1294145
        # This steps configures hypervisor to connect with the given
        # controller. This should be automatically taken care by manager
        vsm_path = '/etc/vmware/netcpa/config-by-vsm.xml'
        command = '/automation/scripts/set-controller %s %s %s KVM' % (
            controller_ip, node_id, vsm_path)
        pylogger.info("Set controller command: %s" % command)
        result = client_object.connection.request(command).response_data
        pylogger.info("result for set-controller: %s" % result)
