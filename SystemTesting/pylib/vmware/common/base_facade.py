#!/usr/bin/env python

import vmware.base.base as base
import vmware.common.base_client as base_client


auto_resolve = base.auto_resolve


class BaseFacade(base.Base):

    DEFAULT_IMPLEMENTATION_VERSION = 'Default'
    DEFAULT_EXECUTION_TYPE = None
    # Client objects in this dictionary should implement get_connection()
    # and prepare_to_serialize interface.
    _clients = None
    _is_facade = True

    @property
    def clients(self):
        return self._clients

    @clients.setter
    def clients(self, clients):
        self._clients = clients

    def _validate_client_objects(self):
        if not self.clients:
            raise ValueError("Need at least one client object, got %r" %
                             self.clients)
        if not isinstance(self.clients, dict):
            raise ValueError("Need a dictionary of client objects, got %r" %
                             self.clients)
        for execution_type, client_obj in self.clients.iteritems():
            if not isinstance(client_obj, base_client.BaseClient):
                raise TypeError("Client object %s for execution_type %s is "
                                "not an instance of BaseClient" %
                                (client_obj, execution_type))

    def initialize(self):
        """Creates connections using client objects."""
        self._validate_client_objects()
        for execution_type in self.clients:
            # check for valid connection is done in _validate_client_objects()
            _ = self.clients[execution_type].connection  # Unused

    def get_impl_version(self, execution_type=None, interface=None):
        _ = execution_type, interface  # Unused
        return self.DEFAULT_IMPLEMENTATION_VERSION

    def get_client(self, execution_type=None):
        """
        Helper to return the correct client object based on the specified
        execution_type.

        @param execution_type [str] Defines which implementation to call.
        """
        if execution_type is None:
            execution_type = self.DEFAULT_EXECUTION_TYPE
        if execution_type not in self.clients:
            raise TypeError("Execution type %r not available, try one of %r" %
                            (execution_type, self.clients.keys()))
        return self.clients[execution_type]

    def prepare_to_serialize(self):
        """Sets up the connection objects to serialize commands/outputs."""
        self._validate_client_objects()
        for client_obj in self.clients:
            client_obj.connection.anchor = None

    def set_runtime_params(self, **kwargs):
        """
        Helper to set runtime parameters on facade object.
        Runtime options can be set like username, password,
        different service ports
        @param kwargs [key-value pair] runtime parameters to be configured
        """
        username = kwargs.get('username', None)
        password = kwargs.get('password', None)

        execution_type = kwargs.get('execution_type', None)
        client = self.get_client(execution_type=execution_type)

        if username:
            client.parent.username = username
        if password:
            client.parent.password = password

if __name__ == "__main__":
    # TODO(James): Provide a unit-test like functionality if the module is
    # directly invoked. Doctest style? Could use doctest_helper module from
    # the MH qe code.
    pass
