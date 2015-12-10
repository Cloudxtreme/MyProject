import vmware.interfaces.port_interface as port_interface


class DefaultPortImpl(port_interface.PortInterface):

    @classmethod
    def get_status(cls, client_object):
        """
        Queries a port's link status.

        @type client_object: BaseClient
        @param client_object: CLI client object that is used to execute
            commands on the relevant host.
        @rtype: str
        @return: Returns the link state as 'up'/'down'
        """
        return client_object.ovsdb.Interface.get_one(
            search='name=%s' % client_object.name).link_state

    @classmethod
    def get_number(cls, client_object):
        """
        Fetches the ofport number.

        @type client_object: BaseClient
        @param client_object: CLI client object that is used to execute
            commands on the relevant host.
        @rtype: str
        @return: Returns the ofport number.
        """
        return client_object.ovsdb.Interface.get_one(
            search='name=%s' % client_object.name).ofport

    @classmethod
    def get_attachment(cls, client_object):
        """
        Fetches the interface uuids of the interfaces attached to a port.

        @type client_object: BaseClient
        @param client_object: CLI client object that is used to execute
            commands on the relevant host.
        @rtype: list
        @return: Returns the list of uuids of attached interfaces.
        """
        return client_object.ovsdb.Port.get_one(
            search='name=%s' % client_object.name).interfaces
