import vmware.common.global_config as global_config
import vmware.interfaces.adapter_interface as adapter_interface

pylogger = global_config.pylogger


class DefaultAdapterImpl(adapter_interface.AdapterInterface):
    """Impl class for VM related CRUD operations."""

    @classmethod
    def delete_all_test_adapters(cls, client_object):
        return client_object.vm.clean_up()

    @classmethod
    def get_ip(cls, client_object):
        """
        Returns the management IP of the VM if VM is running else returns None.
        """
        if client_object.vm.is_running():
            return client_object.vm.ip
        pylogger.warn('VM %r on host %r is not running, no IP found' %
                      (client_object.vm.unique_name, client_object.parent.ip))
        return None
