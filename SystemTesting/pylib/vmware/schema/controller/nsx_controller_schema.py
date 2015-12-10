import vmware.common.base_schema_v2 as base_schema_v2


class NsxControllerTableEntrySchema(base_schema_v2.BaseSchema):
    """
    Schema Class for entries in Nsx Controller Table

    >>> import pprint
    >>> py_dict = {'controller_ip': '10.115.175.187',
    ...           'port': '1234',
    ...           'ssl_enabled': 'true'}
    >>> pprint.pprint((NsxControllerTableEntrySchema(
    ...    py_dict=py_dict).get_py_dict_from_object()))
    {'controller_ip': '10.115.175.187',
     'port': '1234',
     'ssl_enabled': 'true'}
    """

    controller_ip = None
    port = None
    ssl_enabled = None


class NsxControllerTableSchema(base_schema_v2.BaseSchema):
    """
    Schema class for Nsx Controller Table

    >>> import pprint
    >>> py_dict = {'count': 3,
    ...            'table': [{'controller_ip': '10.115.175.187',
    ...                       'port': '1234',
    ...                       'ssl_enabled': 'true'},
    ...                      {'controller_ip': '10.115.175.186',
    ...                       'port': '1234',
    ...                       'ssl_enabled': 'true'},
    ...                      {'controller_ip': '10.115.175.185',
    ...                       'port': '1234',
    ...                       'ssl_enabled': 'true'}]
    ...           }
    >>> pprint.pprint(NsxControllerTableSchema(
    ...             py_dict=py_dict).get_py_dict_from_object())
    {'count': 3,
     'table': [{'controller_ip': '10.115.175.187',
                'port': '1234',
                'ssl_enabled': 'true'},
               {'controller_ip': '10.115.175.186',
                'port': '1234',
                'ssl_enabled': 'true'},
               {'controller_ip': '10.115.175.185',
                'port': '1234',
                'ssl_enabled': 'true'}]
    }
    """
    table = (NsxControllerTableEntrySchema,)
    count = None


if __name__ == '__main__':
    import doctest
    doctest.testmod()
