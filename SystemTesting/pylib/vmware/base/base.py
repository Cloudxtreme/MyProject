import pprint

import vmware.interfaces.labels as labels
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


def _facade_to_clients(data, execution_type=None):
    """
    Helper method to inspect nested structures for the presense of facade
    objects and to convert the corresponding to client objects.

    @type data: Any
    @param data: Contains python types that can potentially be nested.
    @type execution_type: str
    @param execution_type: Specifies the type of client to retrieve for the
        case when a facade object is found.
    @rtype: Any
    @return: Returns the passed in data in the same format but after replacing
        all the facade instances with their corresponding client objects.
    """
    if not data:
        return data
    if not hasattr(data, '__iter__'):
        if isinstance(data, Base) and data._is_facade:
            return data.get_client(execution_type=execution_type)
        return data
    elif isinstance(data, dict):
        converted_data = {}
        for key, val in data.iteritems():
            key = _facade_to_clients(key, execution_type=execution_type)
            val = _facade_to_clients(data[key], execution_type=execution_type)
            converted_data[key] = val
        return converted_data
    elif type(data) in [list, tuple]:
        converted_list = []
        for elem in data:
            converted_list.append(_facade_to_clients(
                elem, execution_type=execution_type))
        if isinstance(data, tuple):
            return tuple(converted_list)
        return converted_list
    else:
        raise NotImplementedError('Was not expecting %r to be an iterable ' %
                                  type(data))


def auto_resolve(interface, preprocess=None, **kwargs):
    '''
    Decorator to autoresolve the method and call it with appropriate
    args and kwargs, Parameters that can be passed in are,

    interface - Name of the interface class like Power, VM, Package
    impl_func_name - Method name in implementation if different from client
    execution_type - Hard-coded execution type that overrides the caller
    preprocess - Static function for preprocessing actions, execution occurs
        before calling the resolved function.
    Example,
        @auto_resolve(labels.POWER, impl_func_name='reboot')
        def reboot_not_named_same(...):
            pass
        @auto_resolve(labels.POWER, execution_type=constants.ExecutionType.CMD)
        def wait_for_reboot(...):
            pass
        @auto_resolve(labels.CRUD)
        def create(...):
            pass
    '''
    _impl_func_name = kwargs.get('impl_func_name')
    _execution_type = kwargs.get('execution_type')

    def func_resolver(func):
        if _impl_func_name is None:
            impl_func_name = func.__name__
        else:
            impl_func_name = _impl_func_name

        def resolved_func(obj, **kwargs):
            if global_config.ENABLE_DEBUG_RESOLVE:
                pylogger.debug('Resolving method: %s.%s(execution_type=%s)' %
                               (interface, impl_func_name, _execution_type))
            if not _execution_type:
                execution_type = kwargs.pop('execution_type', None)
            else:
                execution_type = _execution_type
                kwargs.pop('execution_type', None)

            if preprocess:
                # Pass kwargs by reference to provide for in-place adjustments.
                preprocess(obj, kwargs)

            func(obj, **kwargs)
            if isinstance(obj, Base) and obj._is_facade:
                client_obj = obj.get_client(execution_type=execution_type)
            else:
                client_obj = obj

            if not client_obj:
                raise NotImplementedError('%sClient not implemented for %r' %
                                          (execution_type, obj))
            resolved_method = client_obj._resolve_method(
                interface, impl_func_name)
            if global_config.ENABLE_DEBUG_RESOLVE:
                pylogger.debug('Resolved method: %s' % resolved_method)
            # inspect the arguments passed to implementation and
            # convert any facade objects to client object corresponding
            # to execution type
            for key in kwargs:
                kwargs[key] = _facade_to_clients(
                    kwargs[key], execution_type=execution_type)
            try:
                return resolved_method(client_obj, **kwargs)
            except Exception as e:
                pylogger.exception("%r threw an exception" % resolved_method)
                client_obj.map_sdk_exception(e)
                raise
        resolved_func._resolveefunc = func
        return resolved_func
    return func_resolver


# This is the base of all abstract/base classes
# All the abstract components like hypervisor, vm, switch,
# adapter etc. would derive from this class.
#
# This class is detached from any client or facade object
class Base(object):
    _is_facade = False
    version_tree = None
    DEFAULT_IMPLEMENTATION_VERSION = 'Default'

    def __init__(self, version=None):
        super(Base, self).__init__()
        if version is not None:
            self.set_version(version)

    def get_version(self):
        raise NotImplementedError(
            "get_version needs to be implemented by sub-class")

    def set_version(self, version_info):
        raise NotImplementedError(
            "set_version needs to be implemented by sub-class")

    def get_impl_version(self, interface=None, execution_type=None):
        _ = execution_type, interface  # Unused
        return self.DEFAULT_IMPLEMENTATION_VERSION

    def previous_version(self, version):
        if self.version_tree and version in self.version_tree:
            return self.version_tree[version]
        pylogger.warn('Previous version not found for %r in:\n%s' %
                      (version, pprint.pformat(self.version_tree)))

    @auto_resolve(labels.CRUD)
    def create(self, execution_type=None, schema=None, **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def read(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def update(self, execution_type=None, schema=None, **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def delete(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def get_id(self, execution_type=None, schema=None, **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def get_uuid(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def query(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def get_id_from_schema(self, execution_type=None, **kwargs):
        pass
