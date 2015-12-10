import vsm_client
from vsm import VSM
from edge import Edge
import result
import base_client
import vmware.common.logger as logger
from interfaces_schema import InterfacesSchema

class Interfaces(vsm_client.VSMClient):
    """ Class to create interfaces/LIFs on edge"""

    def __init__(self, edge):
        """ Constructor to create interface managed object

        @param edge object on which interface will be created
        """
        super(Interfaces, self).__init__()
        self.log.debug("Creating LIFs on Edge %s" % edge.id)
        self.schema_class = 'interfaces_schema.InterfacesSchema'
        self.set_connection(edge.get_connection())
        self.set_create_endpoint("/edges/" + edge.id + "/interfaces/?action=patch")
        self.set_delete_endpoint("/edges/" + edge.id + "/interfaces")
        self.set_read_endpoint("/edges/" + edge.id + "/interfaces")
        self.id = None
        self.edge = edge.id
        ## TO DO: (adityaj) why bulk_create can't be overridden
        self.temp_function = base_client.bulk_create
        base_client.bulk_create = self.lif_bulk_create


    def create(self, py_dict_array):
        """ Creates a LIF with specified parameters

        @param schema object which has the paramters to create
              the LIF
        """
        result_array = []
        py_dict = py_dict_array[0]
        schema_obj = self.get_schema_object(py_dict)
        result_obj = super(Interfaces, self).create(schema_obj)
        interfaces_schema = InterfacesSchema()
        response_data = result_obj[0].get_response_data()
        interfaces_schema.set_data(response_data, self.accept_type)
        for interface in interfaces_schema.interfaces:
           result_obj[0].set_response_data(interface.index)
           result_array.append(result_obj[0])
        return result_array

    def lif_bulk_create(self, template_obj, py_dict_array):
        """ Function to create bulk components
            It overrides bulk create in base_client.py
        """
        result_array = []
        py_dict = py_dict_array[0]
        schema_obj = template_obj.get_schema_object(py_dict)
        result_obj = self.create(schema_obj)
        interfaces_schema = InterfacesSchema()
        response_data = result_obj.get_response_data()
        interfaces_schema.set_data(response_data, self.accept_type)
        for interface in interfaces_schema.interfaces:
           result_obj.set_response_data(interface.index)
           result_array.append(result_obj)
        base_client.bulk_create = self.temp_function
        return result_array

    def update(self, py_dict, override_merge=True):
        """
        The py_dict is coming in the form of interfacesSchema from the
        user . The put call makes use of interface schema. So need to convert
        the pydict into an interface pydict. Here override_merge is also set to
        True since we don't want to merge the read schema and update schema
        objects
        """
        interface_pydict = py_dict['interfaces'][0]
        self.log.debug("update input = %s" % interface_pydict)
        self.log.debug("updating interface index %s of edge id %s" %
            (str(self.id), self.edge))
        self.schema_class = 'interface_schema.InterfaceSchema'
        update_object = self.get_schema_object(interface_pydict)
        schema_object = None

        if override_merge is False:
            schema_object = self.read()
            self.log.debug("schema_object after read:")
            schema_object.print_object()
            self.log.debug("schema_object from input:")
            update_object.print_object()
            try:
                self.merge_objects(schema_object, update_object)
            except:
                tb = traceback.format_exc()
                self.log.debug("tb %s" % tb)
        else:
            schema_object = update_object
        self.log.debug("schema object after merge:")
        schema_object.print_object()

        if self.update_as_post:
                self.response = self.request('POST', self.create_endpoint,
                                             schema_object.get_data(self.content_type))
        else:
            if self.id is None:
                self.response = self.request('PUT', self.read_endpoint,
                                             schema_object.get_data(self.content_type))
            else:
                self.response = self.request('PUT', self.read_endpoint + "/" + str(self.id),
                                             schema_object.get_data(self.content_type))
        result_obj = result.Result()
        self.set_result(self.response, result_obj)
        self.schema_class = 'interfaces_schema.InterfacesSchema'
        return result_obj

    def get_interface_ip(self):
           self.schema_class = 'interface_schema.InterfaceSchema'
           interface_obj = self.read()
           self.schema_class = 'interfaces_schema.InterfacesSchema'
           return interface_obj.addressGroups[0].primaryAddress

    def get_interface(self):
           self.schema_class = 'interface_schema.InterfaceSchema'
           interface_obj = self.read()
           return interface_obj

if __name__ == '__main__':
    import base_client
    py_dict = {'ipAddress': '10.115.173.172', 'userName': 'root', 'password': 'vmware'}
    vsm_obj = VSM("10.115.173.172:443", "admin", "default")

    # Bulk Create
    edge = Edge(vsm_obj)
    edge.id = "edge-1"
    py_dict = {'interfaces': [{'name': 'lif-vwire-1-20758',
                               'addressgroups':      [{'subnetmask': '255.255.0.0',
                                                       'addresstype': 'primary',
                                                       'primaryaddress': '172.31.1.1'}
                                                     ],
                               'isconnected': 'true',
                               'mtu': '1500',
                               'connectedtoid': 'virtualwire-1',
                               'type': 'internal'
                              }]
              }



    interface_create = Interfaces(edge)
    interface_object_ids = base_client.bulk_create(interface_create, [py_dict, py_dict])
    print interface_object_ids
