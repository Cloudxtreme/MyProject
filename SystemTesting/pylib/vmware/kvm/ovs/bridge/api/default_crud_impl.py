import pprint

import vmware.common.global_config as global_config
import vmware.interfaces.crud_interface as crud_interface
import vmware.linux.ovs.ovs_helper as ovs_helper
import vmware.parsers.vertical_table_parser as vertical_table_parser

pylogger = global_config.pylogger
OVS = ovs_helper.OVS


class DefaultCRUDImpl(crud_interface.CRUDInterface):
    """Impl class for Bridge related CRUD operations."""

    # TODO(salmanm): Unify the IDs used across the api/cmd impls of the bridge.
    @classmethod
    def create(cls, client_object, name=None, discover=None,
               switch_fail_mode=None, external_id=None):
        """
        Method to create/acquire bridge on this kvm host.

        @type name: str
        @param name: name of the bridge
        @type switch_fail_mode: str
        @param discover: Flag to determine if we need to discover an existing
            bridge by name or not.
        @type discover: bool
        @param switch_fail_mode: Fail mode for the bridge.
        @type external_id: str
        @param external_id: External bridge id to be set on the newly
            created/acquired bridge.
        @rtype bridge_obj: obj of the new bridge with this name
        """
        if name is None:
            raise Exception("Name of the bridge to be discovered/created is "
                            "not provided")
        discovered = None
        if external_id is not None:
            if not type(external_id) == dict:
                raise ValueError("Expected external_id to be a dict, got: %r" %
                                 external_id)
            external_id = ",".join(["%s=%s" % (key, val) for key, val in
                                    external_id.iteritems()])
        if discover:
            ret_columns = {OVS.NAME: name}
            if switch_fail_mode:
                ret_columns[OVS.FAIL_MODE] = switch_fail_mode
            if external_id:
                ret_columns[OVS.EXTERNAL_IDS] = external_id
            pylogger.debug("Discovering bridge with name: %r" % name)
            discover_cmd = OVS.find_columns_in_table(
                OVS.BRIDGE, ret_columns.keys(), OVS.NAME, name,
                data_format=OVS.BARE)
            discovered_attrs = client_object.connection.request(
                discover_cmd).response_data
            if not discovered_attrs:
                raise Exception("Failed to find a bridge with name: %r" % name)
            parser = vertical_table_parser.VerticalTableParser()
            parsed_data = parser.get_parsed_data(discovered_attrs)
            if not parsed_data['table'] == ret_columns:
                pylogger.error("Discovered bridge did not match expected "
                               "attributes! Expected: %s,\nFound: %s" %
                               (pprint.pformat(ret_columns),
                                pprint.pformat(parsed_data['table'])))
                raise Exception("The discovered bridge is configured "
                                "improperly: %r" % name)
            pylogger.debug("Discovered bridge %r" % name)
            discovered = True
        if discovered is None:
            pylogger.debug("Creating bridge with name %r" % name)
        kvm = client_object.kvm
        ret = kvm.network.check_create(name, set_external_id=False)
        if switch_fail_mode:
            mode_cmd = OVS.set_column_of_record(
                OVS.BRIDGE, name, OVS.FAIL_MODE, switch_fail_mode)
            client_object.connection.request(mode_cmd)
        if external_id:
            set_br_id_cmd = OVS.set_column_of_record(
                OVS.BRIDGE, name, OVS.EXTERNAL_IDS, external_id)
            client_object.connection.request(set_br_id_cmd)
        return ret

    @classmethod
    def read(cls, client_object):
        raise NotImplementedError

    @classmethod
    def update(cls, client_object, schema=None):
        raise NotImplementedError

    @classmethod
    def delete(cls, client_object, name=None):
        """
        Deletes the bridge.

        @type name: str
        @param name: Name of the bridge
        """
        return client_object.kvm.network.get_one(bridge=name).destroy()
