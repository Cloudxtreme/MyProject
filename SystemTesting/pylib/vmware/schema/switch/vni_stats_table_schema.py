import vmware.common.base_schema as base_schema


class VNIStatsTableSchema(base_schema.BaseSchema):
    """
    Schema class for VNI stats Table.

    >>> import pprint
    >>> py_dict = {
    ...     'table': [{'update_arp': 4,
    ...                'query_arp': 3}]}
    >>> pprint.pprint(VNIStatsTableSchema(
    ...     py_dict=py_dict).get_py_dict_from_object())
    {'table': [{'query_arp': 3, 'update_arp': 4}]}
    """
    _schema_name = "VNIStatsTableSchema"

    def __init__(self, py_dict=None):
        super(VNIStatsTableSchema, self).__init__()
        self.table = [VNIStatsTableEntrySchema()]
        if py_dict:
            self.get_object_from_py_dict(py_dict)


class VNIStatsTableEntrySchema(base_schema.BaseSchema):
    """
    Schema Class for entries in VNI table.

    >>> import pprint
    >>> py_dict = {'update_arp': 4,
    ...            'query_arp': 3}
    >>> pprint.pprint(VNIStatsTableEntrySchema(
    ...     py_dict=py_dict).get_py_dict_from_object())
    {'query_arp': 3, 'update_arp': 4}
    """
    _schema_name = "VNIStatsTableEntrySchema"

    def __init__(self, py_dict=None):
        """
        Initializes the VNIStatsTableEntrySchema object attributes.

        @type py_dict: dict
        @param py_dict: Dictionary containing information for a VNI table
            entry as key-value.
        """
        super(VNIStatsTableEntrySchema, self).__init__()
        self.update_arp = None
        self.query_arp = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

if __name__ == '__main__':
    import doctest
    doctest.testmod()
