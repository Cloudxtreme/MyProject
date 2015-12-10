import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.interfaces.labels as labels
import vmware.common.global_config as global_config
import vmware.nsx.manager.logical_switch.api.logical_switch_api_client as logical_switch_api_client  # noqa
import vmware.nsx.manager.logical_switch.logical_switch as logical_switch
import vmware.nsx.manager.logical_switch.cli.logical_switch_cli_client as logical_switch_cli_client  # noqa
import vmware.nsx.manager.logical_switch.cmd.logical_switch_cmd_client as logical_switch_cmd_client  # noqa
import vmware.nsx.manager.logical_switch.ui.logical_switch_ui_client as logical_switch_ui_client  # noqa
import vmware.nsx.manager.transport_zone.transport_zone_facade as transport_zone_facade  # noqa

pylogger = global_config.pylogger


def _preprocess_resolve_switch_name(obj, kwargs):
    """
    Determine the anticipated host switch name for the logical switch
    respresented by <obj> and store it in caller's <kwargs>. If an existing
    name is present, use it.

    @type obj: logical switch facade
    @param obj: the facade interfacing to a specific logical switch
    @type kwargs: dict
    @param kwargs: Reference to dictionary.
    @rtype None
    """
    # Determine the expected host_switch_name from the associated
    # TransportZone. This must be done via API regardless of requested
    # execution_type.
    if kwargs.get('host_switch_name') is None:
        # XXX(jschmidt): read() should be able to default to proper
        # obj.id_ instead of requiring explicit caller input.
        tz_id = obj.read(id_=obj.id_)["transport_zone_id"]
        pylogger.debug("Retrieved logical switch transport_zone_id: %s" %
                       tz_id)
        tz = transport_zone_facade.TransportZoneFacade(parent=obj.parent,
                                                       id_=tz_id)
        tz_switch_name = tz.read(id_=tz.id_)["switch_name"]
        pylogger.debug("Retrieved transport zone switch_name: %s" %
                       tz_switch_name)
        kwargs.update({'host_switch_name': tz_switch_name})


class LogicalSwitchFacade(logical_switch.LogicalSwitch,
                          base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None, id_=None):
        super(LogicalSwitchFacade, self).__init__(parent)
        self.id_ = id_
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = logical_switch_api_client.LogicalSwitchAPIClient(
            parent=parent.get_client(constants.ExecutionType.API),
            id_=self.id_)
        cli_client = logical_switch_cli_client.LogicalSwitchCLIClient(
            id_=self.id_)
        cmd_client = logical_switch_cmd_client.LogicalSwitchCMDClient(
            id_=self.id_)
        ui_client = logical_switch_ui_client.LogicalSwitchUIClient(
            parent=parent.get_client(constants.ExecutionType.UI),
            id_=self.id_)

        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client,
                         constants.ExecutionType.CMD: cmd_client,
                         constants.ExecutionType.UI: ui_client}

    @base_facade.auto_resolve(labels.SWITCH)
    def get_switch_vni(self, execution_type=None, **kwargs):
        pass

    @base_facade.auto_resolve(labels.SWITCH,
                              preprocess=_preprocess_resolve_switch_name)
    def get_vtep_table(self, execution_type=None, **kwargs):
        pass
