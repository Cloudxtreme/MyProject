import doctest

import vmware.common.base_schema as base_schema


class VtepTableSchema(base_schema.BaseSchema):
    """
    Schema class for Vtep Table.
    >>> import pprint
    >>> py_dict = {
    ...     'table': [{'adapter_ip': '192.168.1.2'}]}
    >>> pprint.pprint(VtepTableSchema(
    ...    py_dict=py_dict).get_py_dict_from_object(), width=78)
    {'table': [{'adapter_ip': '192.168.1.2'}]}
    """
    _schema_name = "VtepTableSchema"

    def __init__(self, py_dict=None):
        super(VtepTableSchema, self).__init__()
        self.table = [VtepTableEntrySchema()]
        if py_dict:
            self.get_object_from_py_dict(py_dict)


class VtepTableEntrySchema(base_schema.BaseSchema):
    """
    Schema Class for entries in MAC table.
    """
    _schema_name = "VtepTableEntrySchema"

    def __init__(self, py_dict=None):
        """
        Initializes the VtepTableEntrySchema object attributes.

        @type py_dict: dict
        @param py_dict: Dictionary containing information for a Vtep table
            entry as key-value.
        >>> import pprint
        >>> py_dict = {'adapter_ip': '192.168.1.2'}
        >>> pprint.pprint(VtepTableEntrySchema(
        ...     py_dict=py_dict).get_py_dict_from_object(), width=78)
        {'adapter_ip': '192.168.1.2'}
        """
        super(VtepTableEntrySchema, self).__init__()
        self.adapter_ip = None
        self.adapter_mac = None
        self.segment_id = None
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


if __name__ == '__main__':
    doctest.testmod()
