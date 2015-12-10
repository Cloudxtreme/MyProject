class ServiceInterface(object):
    """Interface for host service operations."""

    @classmethod
    def start_service(cls, client_object, service_name=None, **kwargs):
        """Interface to start the service."""
        raise NotImplementedError

    @classmethod
    def stop_service(cls, client_object, service_name=None, **kwargs):
        """Interface to stop the service."""
        raise NotImplementedError

    @classmethod
    def restart_service(cls, client_object, service_name=None,  **kwargs):
        """Interface to restart the service."""
        raise NotImplementedError

    @classmethod
    def get_individual_service_status(cls, client_object, service_name=None,
                                      **kwargs):
        """Interface to get the current status of the given service."""
        raise NotImplementedError

    @classmethod
    def get_service_status(cls, client_object, service_names=None, **kwargs):
        """Interface to get the current status of the given services."""
        raise NotImplementedError

    @classmethod
    def is_service_running(cls, client_object, service_name=None, **kwargs):
        """Checks if the service is running"""
        raise NotImplementedError

    @classmethod
    def uninstall_service(cls, client_object, service_name=None, **kwargs):
        """Interface to uninstall the service."""
        raise NotImplementedError

    @classmethod
    def update_service_policy(cls, client_object, service_name=None,
                              policy=None, **kwargs):
        """Interface to update activation policy of the service."""
        raise NotImplementedError

    @classmethod
    def configure_service_state(cls, client_object, service_name=None,
                                state=None, **kwargs):
        """Interface to configure service state of NSX Manager"""
        raise NotImplementedError

    @classmethod
    def refresh_services(cls, client_object, **kwargs):
        """Interface to refresh service information and settings."""
        raise NotImplementedError
