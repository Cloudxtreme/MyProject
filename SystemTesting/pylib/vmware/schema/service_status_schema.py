import vmware.common.base_schema_v2 as base_schema_v2


class ServiceStatusTableEntrySchema(base_schema_v2.BaseSchema):
    """
    Schema class for returning service status.

    >>> import pprint
    >>> py_dict = {'service_name': 'nsxa', 'service_status': 'started'}
    >>> pprint.pprint(ServiceStatusTableEntrySchema(
    ...     py_dict=py_dict).get_py_dict_from_object())
    {'service_name': 'nsxa', 'service_status': 'started'}
    """
    service_name = None
    service_status = None


class ServiceStatusTableSchema(base_schema_v2.BaseSchema):
    """
    Schema class for returning the service status.

    >>> import pprint
    >>> py_dict = {
    ...     'table': [
    ...               {'service_name': 'nsxa', 'service_status': 'started'},
    ...               {'service_name': 'netcpad', 'service_status': 'unknown'}
    ...              ]
    ...           }
    >>> pprint.pprint(ServiceStatusTableSchema(
    ...    py_dict=py_dict).get_py_dict_from_object())
    {'table': [{'service_name': 'nsxa', 'service_status': 'started'},
               {'service_name': 'netcpad', 'service_status': 'unknown'}]}
    """
    table = (ServiceStatusTableEntrySchema,)


if __name__ == '__main__':
    import doctest
    doctest.testmod()
