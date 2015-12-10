import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.common.global_config as global_config
import vmware.interfaces.labels as labels

pylogger = global_config.pylogger
auto_resolve = base_facade.auto_resolve


class ApplianceManagement(base.Base):

    #
    # This is base class for all components of ApplianceManagement type.
    #
    display_name = None
    description = None

    def __init__(self, parent=None):
        super(ApplianceManagement, self).__init__()
        self.parent = parent
        self.id_ = None

    @auto_resolve(labels.SERVICE)
    def configure_service_state(self, execution_type=None,
                                service_name=None, state=None, **kwargs):
        """
        Stop/Start/Restart services of NSX Manager appliance.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass

    @auto_resolve(labels.CRUD)
    def get_interface_statistics(self, execution_type=None, **kwargs):
        """
        Get interface statistics of NSX Manager appliance e.g tx,rx.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass

    @auto_resolve(labels.CRUD)
    def verify_support_bundle(self, execution_type=None, **kwargs):
        """
        Verifies downloaded techsupport bundle
        of NSX Manager appliance

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass

    @auto_resolve(labels.CRUD)
    def check_log_file(self, execution_type=None, **kwargs):
        """
        Check log file verifies if log data is downloaded

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        """
        pass