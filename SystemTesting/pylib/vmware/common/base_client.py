#!/usr/bin/env python
import importlib
import pprint

import vmware.common as common
import vmware.common.connections.expect_connection as expect_connection
import vmware.common.connections.ssh_connection as ssh_connection
import vmware.common.constants as constants
import vmware.common.errors as errors
import vmware.common.global_config as global_config
import vmware.common.utilities as utilities

pylogger = global_config.pylogger


def _get_module_name(*args):
    """
    Returns the module name from version/interface details
    >>> _get_module_name("RHEL64", "Package", "Impl")
    'rhel64_package_impl'
    """
    return "_".join(x.lower() for x in args)


def _get_module_path(*args):
    return ".".join(args)


def _get_class_name(*args):
    return "".join(args)


def _get_component_module_path(module, execution_type):
    """
    Returns the module path for the component where base component,
    facade classes are defined like vmware/nsx/manager for NSXManager
    >>> _get_component_module_path(
    ...     "vmware.nsx.controller.cli.controller_cli_client", "cli")
    'vmware.nsx.controller'
    >>> _get_component_module_path("vmware.kvm.kvm_facade", "cli")
    'vmware.kvm'
    """
    dirs = module.split(".")[:-1]
    end = -1 if dirs[-1] == execution_type else len(dirs)
    return _get_module_path(*dirs[:end])


class BaseClient(object):
    ''' Base client class to be used for all the clients in library '''
    _connection = None
    _is_facade = False
    parent = None
    status_code_map = None

    def __init__(self, parent=None, ip=None, username=None,
                 password=None, root_password=None, cmd_username=None,
                 cmd_password=None, cert_thumbprint=None, build=None):
        super(BaseClient, self).__init__()
        self.parent = parent
        self.ip = ip
        self.username = username
        self.password = password
        self.root_password = root_password
        self.cmd_username = cmd_username
        self.cmd_password = cmd_password
        self.cert_thumbprint = cert_thumbprint
        self.build = build

    def execute_cmd_get_schema(self, cmd, attr_map, parser_type, schema_class,
                               expect=None, skip_records=None,
                               **parser_kwargs):
        """
        Helper method for executing a command, and returning the parsed data as
        a schema object.

        @type cmd: str
        @param cmd: Command to execute.
        @type attr_map: dict
        @param attr_map: Map from the product specific keys to vdnet specific
            keys.
        @type parser_type: str
        @param parser_type: Type of parser to use for parsing the raw data.
        @type schema_class: Any
        @param schema_class: Reference to the schema class, that will be used
            to encapsulate the parsed data.
        @param expect: Parameter for expect connection, the response_data is
            empty if there isn't special expect prompt.
        @param skip_records: Parameter to identify how many records need to be
            skipped from the parsed and mapped data.
        """
        if expect is None:
            raw_data = self.connection.request(cmd).response_data
        else:
            raw_data = self.connection.request(cmd, expect).response_data
        mapped_pydicts = utilities.parse_data_map_attributes(
            raw_data, parser_type, attr_map, skip_records=skip_records,
            **parser_kwargs)
        return schema_class(mapped_pydicts)

    def get_connection(self):
        '''
        Instantiates a new connection instance of specific type like SOAP, SSH
        thats required by this client type. If parent is set, gets connection
        from the parent

        @rtype: Connection
        @return: New connection instance for itself or from parent
        '''
        if self.parent:
            return self.parent.get_connection()
        else:
            raise NotImplementedError

    def set_connection(self, connection_type=constants.ConnectionType.SSH,
                       username=None, password=None):
        '''
        Sometimes for special target we need to change its connection type
        dynamically, for example, we make default connection type as SSH for
        ESX, but for some special operation like set_nsx_manager, we need to
        use EXPECT connection to register hosts, in thus scenario, we need to
        temporary change its connection type, after use it we should restore
        its default connection type by calling restore_connection method.

        @type connection_type: ssh | expect
        @param connection_type: connection type you wan to change dynamically,
        currently only 'expect' and 'ssh' types are suppported
        '''
        if username is None:
            username = self.username
        if password is None:
            password = self.password
        if connection_type == constants.ConnectionType.EXPECT:
            self._connection = expect_connection.ExpectConnection(
                ip=self.ip, username=username, password=password)
        elif connection_type == constants.ConnectionType.SSH:
            self._connection = ssh_connection.SSHConnection(
                ip=self.ip, username=username, password=password)
        else:
            raise ValueError("Currently only 'ssh' and 'expect' "
                             "connection_types are supported, but you "
                             "passed %r" % connection_type)

    def restore_connection(self):
        '''
        Used combine with set_connection, just set '_connection' to None will
        make the connection type as default, because below property
        'connection' will call get_connection again when self._connection
        is None

        '''
        self._connection = None

    @property
    def connection(self):
        '''
        Connection to be used by this client. If _connection is not yet
        assigned, it would call get_connection() and use that as the default
        from there on. If the connection is not established or anchor becomes
        invalid, this method also calls create_connection() to recreate it.
        If parent is set, redirects to parent connection.

        @rtype: Connection
        @return: New|Existing connection for itself or from parent
        '''
        if self.parent:
            return self.parent.connection
        if not self._connection:
            self._connection = self.get_connection()
        if not self._connection.anchor:
            self._connection.create_connection()
            if not self._connection.anchor:
                raise ValueError("Connection anchor is missing, check if "
                                 "credentials passed for ip %s are correct" %
                                 self._connection.ip)
        return self._connection

    def _get_execution_type(self):
        raise NotImplementedError

    def _resolve_method(self, interface, method_name, version=None):
        """
        Dynamically resolve a method.

        interface - CamelCase name of the target interface.
        method_name - Name of the target method to be resolved.
        version - version of the client

        Returns  resolved method based on this formatting,
        module - <version>_<interface>_impl
        class  - <Version><Interface>Impl
        method - method_name
        e.g. For PowerInterface, 'Power' is passed as interface parameter to
        resolve_method
        """

        execution_type = self._get_execution_type().lower()
        if version is None:
            version = self.get_impl_version(
                interface=interface, execution_type=execution_type)
        running_version = version

        module_path = _get_component_module_path(
            self.__module__, execution_type)
        # Iterates over all the versions based on the dependencies defined by
        # the version_tree and tries to find the right impl to be loaded.
        while version:
            module_name = _get_module_name(version, interface, 'impl')
            module_fullname = _get_module_path(
                module_path, execution_type, module_name)
            cls_name = _get_class_name(version, interface, 'Impl')
            try:
                module = importlib.import_module(module_fullname)
                if global_config.ENABLE_DEBUG_RESOLVE:
                    pylogger.debug("Resolved class %s.%s from version=%s, "
                                   "path=%s, name=%s, execution_type=%s" %
                                   (module_fullname, cls_name, version,
                                    module_path, module_name, execution_type))
                break
            except ImportError, e:
                pylogger.warn("Error in loading %s: %r" % (module_fullname, e))
                version = self.previous_version(version)
                if global_config.ENABLE_DEBUG_RESOLVE and version:
                    pylogger.debug(
                        "Unable to find %s impl that implements %sInterface "
                        "for version %s, trying previous versions from %s" %
                        (execution_type, interface, version,
                         pprint.pformat(self.version_tree)))
        else:
            raise ValueError("Unable to find %s impl that implements "
                             "%sInterface for version %s in the tree %s" %
                             (execution_type, interface, running_version,
                              pprint.pformat(self.version_tree)))

        cls = getattr(module, cls_name, None)
        if not cls:
            raise NotImplementedError("Class not found in %r: %r" %
                                      (module_fullname, cls_name))
        method = getattr(cls, method_name, None)
        if not method:
            raise NotImplementedError("Classmethod not found in %r.%r: %r" %
                                      (module_fullname, cls_name, method_name))
        if global_config.ENABLE_DEBUG_RESOLVE:
            pylogger.debug("Found method %r for class %r in %r" %
                           (method, cls, module))
        return method

    def map_sdk_exception(self, exc):
        '''
        Method to map exceptions returned by product/sdk to common errors
        with generic status_codes across the products and sdks.
        @type exc: Exception
        @param exc: Exception caught while making product/sdk method calls
        @rtype: Error
        @return: Framework error defined in vmware/common/errors
        '''
        return errors.Error(exc=exc)


# Base for API, CLI and CMD client classes
class BaseAPIClient(BaseClient):

    def _get_execution_type(self):
        return constants.ExecutionType.API

    def map_sdk_exception(self, exc):
        # Map all well known python errors to runtime errors as they are
        # not any sdk related errors
        if type(exc) in (AttributeError, RuntimeError, TypeError, ValueError):
            return errors.Error(
                status_code=common.status_codes.RUNTIME_ERROR, exc=exc)
        else:
            return errors.APIError(exc=exc)


class BaseCLIClient(BaseClient):

    def _get_execution_type(self):
        return constants.ExecutionType.CLI

    def map_sdk_exception(self, exc):
        if type(exc) in (AttributeError, RuntimeError, TypeError, ValueError):
            return errors.Error(
                status_code=common.status_codes.RUNTIME_ERROR, exc=exc)
        else:
            return errors.CLIError(exc=exc)


class BaseCMDClient(BaseClient):

    def _get_execution_type(self):
        return constants.ExecutionType.CMD

    def map_sdk_exception(self, exc):
        if type(exc) in (AttributeError, RuntimeError, TypeError, ValueError):
            return errors.Error(
                status_code=common.status_codes.RUNTIME_ERROR, exc=exc)
        else:
            # reuse same errors as cli
            return errors.CLIError(exc=exc)


class BaseUIClient(BaseClient):

    def _get_execution_type(self):
        return constants.ExecutionType.UI

    def map_sdk_exception(self, exc):
        if type(exc) in (AttributeError, RuntimeError, TypeError, ValueError):
            return errors.Error(
                status_code=common.status_codes.RUNTIME_ERROR, exc=exc)
        else:
            return errors.APIError(exc=exc)


if __name__ == '__main__':
    import doctest
    doctest.testmod(optionflags=(
        doctest.ELLIPSIS | doctest.NORMALIZE_WHITESPACE))
