import vmware.common.utilities as utilities
import vmware.interfaces.adapter_interface as adapter_interface
import vmware.schema.gateway.show_interface_schema as show_interface_schema


class Edge70AdapterImpl(adapter_interface.AdapterInterface):

    @classmethod
    def _parse_get_interface(cls, client_object, adapter_name):
        if adapter_name is None:
            raise ValueError("vNic name must be a valid value. "
                             "Provided: %r" % adapter_name)
        endpoint = "get interface " + adapter_name
        PARSER = "raw/showinterface"
        EXPECT_PROMPT = ['bytes*', 'NSXEdge>']

        mapped_pydict = utilities.get_mapped_pydict_for_expect(
            client_object.connection, endpoint, PARSER, EXPECT_PROMPT, ' ')

        client_object.connection.close()
        return mapped_pydict

    @classmethod
    def show_interface(cls, client_object, adapter_name=None,
                       show_interface=None):

        mapped_pydict = cls._parse_get_interface(client_object, adapter_name)
        show_interface_schema_object = show_interface_schema.\
            ShowInterfaceSchema(mapped_pydict)
        return show_interface_schema_object

    @classmethod
    def get_assigned_interface_ip(cls, client_object, ip_version=None,
                                  network_name=None, adapter_name=None,
                                  get_assigned_interface_ip=None):

        mapped_pydict = cls._parse_get_interface(client_object, adapter_name)
        mapped_pydict['result'] = str(len([x for x in
                                           mapped_pydict[ip_version]
                                           if x.startswith(network_name)]) > 0)
        return mapped_pydict

    @classmethod
    def get_edge_interface_ip(cls, client_object, ip_version=None,
                              network_name=None, adapter_name=None,
                              get_edge_interface_ip=None):

        mapped_pydict = cls._parse_get_interface(client_object, adapter_name)
        for x in mapped_pydict[ip_version]:
            if x.startswith(network_name):
                mapped_pydict['result'] = x
        return mapped_pydict
