import vmware.common.utilities as utilities


IFCFG_BRIDGE_MAP = {
    'DEVICE': None,
    'NM_CONTROLLED': "no",
    'DEFROUT': "yes",
    'IPV4_FAILURE_FATAL': "no",
    'IPV6INIT': "no",
    'ONBOOT': "yes",
    'HOTPLUG': "no",
    'TYPE': "OVSBridge",
    'DEVICETYPE': "ovs",
    'OVS_EXTRA': None,
    'OVSBOOTPROTO': None,
    'OVSDHCPINTERFACES': None
}

IFCFG_PORT_MAP = {
    'DEVICE': None,
    'NM_CONTROLLED': "no",
    'ONBOOT': "yes",
    'IPV6INIT': "no",
    'TYPE': "OVSPort",
    'DEVICETYPE': "ovs",
    'OVS_BRIDGE': None,
    'BOOTPROTO': "none"
}


class OVS(object):
    """
    Class for containing OVS related attributes and helper methods.
    """
    VSCTL = 'ovs-vsctl'

    # Table Names
    BRIDGE = 'bridge'
    PORT = 'port'
    INTERFACE = 'interface'

    # Column names
    UUID = '_uuid'
    NAME = 'name'
    INTERFACES = 'interfaces'
    PORTS = 'ports'
    LINK_STATE = 'link_state'
    OFPORT = 'ofport'
    FAIL_MODE = 'fail_mode'
    EXTERNAL_IDS = 'external_ids'
    OPTIONS = 'options'
    MTU = 'mtu'

    # Keys in columns
    BRIDGE_ID = 'bridge-id'
    REMOTE_IP = 'remote_ip'

    # Data formats
    BARE = "bare"

    @classmethod
    def add_record(cls, record_type, record_name, parent=None, may_exist=None):
        """
        Returns a command that can be used to add new recods in OVSDB.

        @type record_type: str
        @param record_type: Identifies the table name to which the record needs
            to be added (e.g. 'br' or 'port')
        @type record_name: str
        @param record_name: Name of the record being added.
        @type parent: str
        @param parent: Name of the parent record of this record (e.g. a port
            can be added to a bridge)
        @type may_exist: bool
        @param may_exist: Flag for the add_command not to fail if the record
            already exists in the database
        @rtype: str
        @return: Command for adding a record
        """
        add_cmd = [cls.VSCTL]
        if may_exist:
            add_cmd.append('--may-exist')
        add_cmd.append('add-%s' % record_type)
        if parent:
            add_cmd.append(parent)
        add_cmd.append(record_name)
        return ' '.join(add_cmd)

    @classmethod
    def del_record(cls, record_type, record_name, parent=None):
        """
        Returns a command that can be used to add new recods in OVSDB.

        @type record_type: str
        @param record_type: Identifies the table name from which the record
            needs to be deleted (e.g. 'br' or 'port')
        @type record_name: str
        @param record_name: Name of the record being deleted.
        @type parent: str
        @param parent: Name of the parent record of this record (e.g. a port
            can be deleted from a bridge)
        @rtype: str
        @return: Command for deleting a record.
        """
        del_cmd = ['%s del-%s' % (cls.VSCTL, record_type)]
        if parent:
            del_cmd.append(parent)
        del_cmd.append(record_name)
        return ' '.join(del_cmd)

    @classmethod
    def set_column_of_record(cls, table, record, column, value):
        """
        Returns a command that can be used for setting a column of a particular
        record in a particular table of OVSDB.

        @type table: str
        @param table: Name of the table (e.g. 'bridge')
        @type record: str
        @param record: Name of the record (e.g. 'nsx-managed')
        @type column: str
        @param column: Name of the column (e.g. 'fail_mode')
        @type value: str
        @param value: Value to be set for the specified column (e.g. 'secure')
        @rtype: str
        @return: OVS query command.
        """
        return '%s set %s %s %s=%s' % (cls.VSCTL, table, record, column, value)

    @classmethod
    def get_column_from_record(cls, table, record, column):
        """
        Returns a command that can be used for fetching a column of a
        particular record in a particular table of OVSDB.

        @type table: str
        @param table: Name of the table (e.g. 'Port')
        @type record: str
        @param record: Name of the record (e.g. 'breth1')
        @type column: str
        @param column: Name of the column (e.g. _uuid)
        @rtype: str
        @return: OVS query command.
        """
        return '%s get %s %s %s' % (cls.VSCTL, table, record, column)

    @classmethod
    def get_columns_from_record(cls, table, record, columns):
        """
        Returns a command that can be used for fetching a column of a
        particular record in a particular table of OVSDB.

        @type table: str
        @param table: Name of the table (e.g. 'Port')
        @type record: str
        @param record: Name of the record (e.g. 'breth1')
        @type column: list
        @param column: List of names of the columns (e.g. ['_uuid', 'name'])
        @rtype: str
        @return: OVS query command.
        """
        if not isinstance(columns, list):
            raise ValueError('Expected columns argument to be a list, got %r' %
                             columns)
        get_columns_cmd = ('%s -- --columns=%s list %s %s' %
                           (cls.VSCTL, ','.join(columns), table, record))
        return get_columns_cmd

    @classmethod
    def find_columns_in_table(cls, table, return_columns, match_column,
                              value, key=None, data_format=None):
        """
        Returns a command for getting columns of the record found in the given
        table that matches the key/value queried for the matched column.

        @type table: str
        @param table: Name of the table (e.g. 'Bridge')
        @type return_columns: str
        @param return_columns: Comma separated names of the columns that we
            want to retrieve for a given record.
        @type match_column: str
        @param match_column: Name of the column that will be used to find a
            record.
        @type value: str
        @param value: Value of the match_column that will be used to find the
            record we are interested in.
        @type key: str
        @param key: If the column that we are matching against consists of data
            in key/value format (e.g. external_ids column), then this option
            can be used to provide the key.
        @type data_format: str
        @param data_format: Determines the formatting of data of cells in the
            output of the table retrieved from OVSDB query. (e.g. 'bare',
            'json' etc.)
        """
        return_columns = utilities.as_list(return_columns)
        find_cmd = "--columns=%s find %s" % (','.join(return_columns), table)
        opts = []
        if data_format:
            opts = ["--data=%s" % data_format]
        get_columns_cmd = ["%s %s %s" % (cls.VSCTL, " ".join(opts), find_cmd)]
        if key:
            match_part = '%s:%s=%s' % (match_column, key, value)
        else:
            match_part = '%s=%s' % (match_column, value)
        get_columns_cmd.append(match_part)
        return ' '.join(get_columns_cmd)

    @classmethod
    def list_columns_in_table(cls, table, return_columns, format_type=None):
        """
        Returns a command to list the given columns in a table.

        @type table: str
        @param table: Name of the table (e.g. 'Port')
        @type return_columns: list
        @param return_columns: List of names of the columns.
        @rtype: str
        @return: OVS query command.
        @type format_type: str
        @param format_type: Name of the format type (e.g 'table')
        """
        return_columns = utilities.as_list(return_columns)
        if format_type:
            list_columns_cmd = ('%s --format %s --columns=%s list %s' %
                                (cls.VSCTL, format_type,
                                    ','.join(return_columns), table))
        else:
            list_columns_cmd = ('%s -- --columns=%s list %s' %
                                (cls.VSCTL, ','.join(return_columns), table))
        return list_columns_cmd

    @classmethod
    def set_external_id(cls, table=None, record=None, key=None, value=None):
        """
        Returns a command for setting the external-ids column of the 'record'
        in the 'table' of OVSDB with the provided key, value pair.

        @type table: str
        @param table: Name of the table where the record exists (e.g. bridge)
        @type record: str
        @param record: Name of the record whose external id needs to be set
            (e.g. nsx-managed)
        @type key: str
        @param key: Name of the key to be set in external-ids column. (e.g.
            bridge-id)
        @type value: str
        @param value: Value to be set for the provided key (e.g. nsx-managed)
        """
        return ('%s set %s %s external-ids:%s=%s' %
                (cls.VSCTL, table, record, key, value))
