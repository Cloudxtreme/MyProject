class SetupInterface(object):

    @classmethod
    def set_nsx_manager(cls, client_object, manager_ip=None,
                        manager_thumbprint=None, username=None,
                        password=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def remove_nsx_manager(cls, client_object, manager_ip=None,
                           manager_thumbprint=None, username=None,
                           password=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def clear_nsx_manager(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def configure_nsx_manager(cls, client_object, operation=None,
                              manager_ip=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def set_nsx_registration(cls, client_object,  manager_ip=None,
                             manager_thumbprint=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def clear_nsx_registration(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def configure_nsx_registration(cls, client_object, operation=None,
                                   manager_ip=None, manager_thumbprint=None,
                                   **kwargs):
        raise NotImplementedError

    @classmethod
    def setup_3rd_party_library(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def remove_ccp_cluster_node(cls, client_object,  controller_ip=None,
                                **kwargs):
        raise NotImplementedError

    @classmethod
    def remove_nsx_controller(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def set_security(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_control_cluster_thumbprint(cls, client_obj, **kwargs):
        raise NotImplementedError

    @classmethod
    def register_nsx_edge_node(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def clear_controller(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def install_nsx_components(cls, client_obj, **kwargs):
        raise NotImplementedError

    @classmethod
    def uninstall_nsx_components(cls, client_obj, **kwargs):
        raise NotImplementedError

    @classmethod
    def tunnel_process(cls, client_obj, **kwargs):
        """
        Kill/Check tunnel to other conntroller on controller
        """
        raise NotImplementedError
