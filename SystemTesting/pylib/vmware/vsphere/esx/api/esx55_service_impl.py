import vmware.interfaces.service_interface as service_interface
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


class ESX55ServiceImpl(service_interface.ServiceInterface):
    """Service related operaions."""

    @classmethod
    def _get_service_system(cls, client_object):
        host_mor = client_object.host_mor
        if host_mor is None:
            raise Exception("Could not retrieve host mor from host IP %s"
                            % client_object.ip)
        if hasattr(host_mor, 'configManager'):
            return host_mor.configManager.serviceSystem
        else:
            raise Exception("Could not retrieve host configManager")

    @classmethod
    def refresh_services(cls, client_object):
        """
        Refreshes service information and settings.

        @type client_object: client instance
        @param client_object: Hypervisor client instance

        @rtype: NoneType
        @return: None
        """
        pylogger.info("Attempting to refresh services")
        service_system = cls._get_service_system(client_object)
        return service_system.RefreshServices()

    @classmethod
    def restart_service(cls, client_object, key=None):
        """
        Restarts the service.

        @type client_object: client instance
        @param client_object: Hypervisor client instance

        @type key: str
        @param key: Service identifier

        @rtype: NoneType
        @return: None
        """
        pylogger.info("Attempting to restart %s service" % key)
        service_system = cls._get_service_system(client_object)
        service_system.RestartService(key)
        cls.refresh_services(client_object)

    @classmethod
    def start_service(cls, client_object, key=None):
        """
        Starts the service.

        @type client_object: client instance
        @param client_object: Hypervisor client instance

        @type key: str
        @param key: Service identifier

        @rtype: NoneType
        @return: None
        """
        pylogger.info("Attempting to start %s service" % key)
        service_system = cls._get_service_system(client_object)
        service_system.StartService(key)
        cls.refresh_services(client_object)

    @classmethod
    def stop_service(cls, client_object, key=None):
        """
        Stops the service.

        @type client_object: client instance
        @param client_object: Hypervisor client instance

        @type key: str
        @param key: Service identifier

        @rtype: NoneType
        @return: None
        """
        service_system = cls._get_service_system(client_object)
        service_system.StopService(key)
        cls.refresh_services(client_object)

    @classmethod
    def uninstall_service(cls, client_object, key=None):
        """
        Uninstalls the service.

        @type client_object: client instance
        @param client_object: Hypervisor client instance

        @type key: str
        @param key: Service identifier

        @rtype: NoneType
        @return: None
        """
        service_system = cls._get_service_system(client_object)
        service_system.UninstallService(key)
        cls.refresh_services(client_object)

    @classmethod
    def update_service_policy(cls, client_object, key=None, policy=None):
        """
        Updates activation policy of the service.

        @type client_object: client instance
        @param client_object: Hypervisor client instance

        @type key: str
        @param key: Service identifier

        @type policy: str
        @param policy: Can be automatic/on/off

        @rtype: NoneType
        @return: None
        """
        service_system = cls._get_service_system(client_object)
        return service_system.UpdateServicePolicy(key, policy)
