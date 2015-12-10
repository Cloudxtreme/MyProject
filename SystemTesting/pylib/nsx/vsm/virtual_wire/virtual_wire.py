import vsm_client
import importlib
import result
from vdn_scope import VDNScope
from virtual_wire_schema import VirtualWireSchema
from virtual_wires_schema import VirtualWiresSchema
from virtual_wire_create_spec_schema import VirtualWireCreateSpecSchema
from virtual_wire_tor_attachment_schema import VirtualWireTORAttachmentSchema
from vsm import VSM
from vdnHost_schema import VdnHostSchema
from list_schema import ListSchema
from base_cli_client import BaseCLIClient

class VirtualWire(vsm_client.VSMClient):
    """ Class to create virtual wire"""

    def __init__(self, cfgVdnScope, scope=None):
        """ Constructor to create VirtualWire managed object

        @param cfgVdnScope scope object using which virtual wire will be created
        """
        super(VirtualWire, self).__init__()
        self.schema_class = 'virtual_wire_create_spec_schema.VirtualWireCreateSpecSchema'
        self.set_connection(cfgVdnScope.get_connection())
        self.connection.api_header = 'api/2.0/'
        if scope is None or scope is "":
            self.set_create_endpoint("vdn/scopes/%s/virtualwires" % cfgVdnScope.id)
        else:
            self.set_create_endpoint("/vdn/scopes/universalvdnscope/virtualwires" )
        self.set_delete_endpoint("/vdn/virtualwires")
        self.set_read_endpoint("/vdn/virtualwires")
        self.id = None

    def get_switch_id(self):
        return self.id

    def full_query(self):
        """ This query method returns all schema objects as a list

        @param name name of virtual wire which is used to query
        """
        response = super(VirtualWire, self).query()
        virtual_wires_object = VirtualWiresSchema()
        virtual_wires_object.set_data(response, "xml")
        count  = virtual_wires_object.dataPage.pagingInfo.totalCount
        page_size = virtual_wires_object.dataPage.pagingInfo.pageSize

        iterations = int(count)/int(page_size)
        if iterations == 0:
            iterations = 1
        new_list = []
        start_index = 0
        for i in range(0,iterations):
            full_query_endpoint = self.read_endpoint + "?startindex=" + str(start_index)
            temp_read_endpoint = self.read_endpoint
            self.read_endpoint = full_query_endpoint
            response = super(VirtualWire, self).query()
            self.read_endpoint = temp_read_endpoint
            virtual_wires_object.set_data(response, "xml")
            for virtual_wire in virtual_wires_object.dataPage.list_schema:
                new_list.append(virtual_wire)
        virtual_wires_object.dataPage.list_schema = new_list
        return new_list

    def read_by_name(self, name):
        """ This read method returns an object whose name matches in input name

        @param name name of virtual wire which is used to query
        """
        response = super(VirtualWire, self).query()
        virtual_wires_object = VirtualWiresSchema()
        virtual_wires_object.set_data(response, "xml")
        count  = virtual_wires_object.dataPage.pagingInfo.totalCount
        page_size = virtual_wires_object.dataPage.pagingInfo.pageSize

        iterations = int(count)/int(page_size)
        if iterations == 0:
            iterations = 1
        start_index = 0
        for i in range(0,iterations):
            full_query_endpoint = self.read_endpoint + "?startindex=" + str(start_index)
            temp_read_endpoint = self.read_endpoint
            self.read_endpoint = full_query_endpoint
            response = super(VirtualWire, self).query()
            self.read_endpoint = temp_read_endpoint
            virtual_wires_object.set_data(response, "xml")
            for virtual_wire in virtual_wires_object.dataPage.list_schema:
                if virtual_wire.name == name:
                    return virtual_wire
            start_index = start_index + int(page_size)
        return "FAILURE"

    def read(self,type = "xml"):
        vWire = VirtualWireSchema()
        self.set_query_endpoint(self.read_endpoint + "/" + self.id)
        vWire.set_data(self.base_query(),type)
        return vWire

    def get_vteps(self,hostid,domainid,type = "xml"):
        """ Get vtep list on esx host by host-ID and domain-ID

        @param hostID host object ID which used to query
        @param domainID domain object ID which used to query
        """
        List = ListSchema(None,VdnHostSchema)
        vteplist = []
        self.response = self.request('GET', "vdn/inventory/ui/cluster/host/" + domainid, "")
        List.set_data(self.response.read(),type)
        for vdnhost in List.list_object:
            if vdnhost.host.objectId == hostid:
                for vdnVmknic in vdnhost.vmknics.vmknics:
                    vteplist.append(vdnVmknic.ipAddress)
                break
        return vteplist

    def get_horizontal_table_from_controllers(self, table_type, controller, exclude_controller_list):
        """ Method to get all horizontal entries for this VNI from controller,
        like get mac-table, arp-table and so on
        nvp-controller #  show control-cluster logical-switches arp-table 6796
        VNI      IP              MAC               Connection-ID
        6796     192.168.139.11  00:50:56:b2:30:6e 1
        6796     192.168.138.131 00:50:56:b2:40:33 2
        6796     192.168.139.201 00:50:56:b2:75:d1 3

        we expect these arp entries only exist on controller, and should not exist in
        the exclude_controller_list

        """
        vxlanid = self.read().vdnId
        cli = BaseCLIClient()
        # Get the cli_schema_class name e.g. arp-table maps to ARPTableSchema
        schema_class = self.get_cli_schema_class(table_type)
        if schema_class is None:
            self.log.error("schema class not found for table type %s" % table_type)
        cli.set_schema_class(schema_class)
        cli.set_create_endpoint("show control-cluster logical-switches " + table_type + " " + vxlanid)
        ssh = controller.get_ssh_connection()
        cli.set_connection(ssh)
        cli_data = cli.read()
        ssh.close()
        for exclude_controller in exclude_controller_list:
            cli.set_schema_class(schema_class)
            ssh = exclude_controller.get_ssh_connection()
            cli.set_connection(ssh)
            cli_data_exclude_controller = cli.read()
            ssh.close()
            if (len(cli_data_exclude_controller.table) > 0):
               self.log.error("expect not found entry on controler  " +\
                              exclude_controller.get_ip() + " but actually we found it")
               return "FAILURE"
        return cli_data.table

    def get_controller_based_on_vni(self, controller_list, vxlanid = 0):
        """ Method to get vni corresponding controller
        nvp-controller # show control-cluster logical-switches vni 9647
        VNI      Controller      BUM-Replication ARP-Proxy Connections VTEPs
        9647     10.144.136.238  Enabled         Enabled   0           0

        """
        vni_table = []
        if (vxlanid == 0):
            vxlanid = self.read().vdnId
        cli = BaseCLIClient()
        cli.set_schema_class('vni_schema.VNISchema')
        cli.set_create_endpoint("show control-cluster logical-switches vni " +\
                           str(vxlanid))
        ssh = controller_list[0].get_ssh_connection()
        cli.set_connection(ssh)
        cli_data = cli.read()
        vni_entry_list = cli_data.table
        ssh.close()
        if (len(vni_entry_list) == 0):
            """ no vxlanid info on controller"""
            return "FAILURE"
        controllerIP = vni_entry_list[0].controller
        for controller in controller_list:
            if controller.get_ip() == controllerIP:
               return controller
        return "FAILURE"

    def test_group_connectivity(self, pyDict):
        testmethod = pyDict['testmethod']
        sourcehostid = pyDict['sourcehostid']
        destinationhostid = pyDict['destinationhostid']
        sourceswitchid = pyDict['sourceswitchid']
        destinationswitchid = pyDict['destinationswitchid']
        sourcegateway = pyDict['sourcegateway']
        sourcevlanid = pyDict['sourcevlanid']
        destinationvlanid = pyDict['destinationvlanid']
        packtsize = pyDict['packtsize']

        sourcehostpyDict = {'hostid': sourcehostid,
                            'switchid': sourceswitchid,
                            'vlanid': sourcevlanid
                            }
        destinationhostpyDict = {'hostid': destinationhostid,
                                 'switchid': destinationswitchid,
                                 'vlanid': destinationvlanid
                                 }
        testparameterspyDict = {'gateway': sourcegateway,
                                'packetsize': packtsize,
                                'sourcehost': sourcehostpyDict,
                                'destinationhost': destinationhostpyDict,
                                }
        schema_class = 'test_parameters_schema.TestParametersSchema'
        module, class_name = schema_class.split(".")
        some_module = importlib.import_module(module)
        loaded_schema_class = getattr(some_module, class_name)
        # creating an instance of schema class
        test_parameters_schema_object = loaded_schema_class(testparameterspyDict)
        post_endpoint = "vdn/virtualwires/" + self.id + "/conn-check/" + testmethod
        payload =  test_parameters_schema_object.get_data(self.content_type)
        self.response = self.request('POST',post_endpoint,
                           test_parameters_schema_object.get_data(self.content_type))
        result_obj = result.Result()
        self.set_result(self.response, result_obj)
        status = result_obj.get_status_code()
        if status == 200:
            return "SUCESS"
        return "FAILURE"

    def get_all_macs_from_controller(controller_list):
        """ Method to get all macs for this VNI from controllers
	nvp-controller #  show control-cluster logical-switches arp-table 5388
	VNI      IP                     MAC                         Connection-ID
	5388    172.31.1.25     00:50:56:9f:36:e6                   9
	5388    172.31.1.15     00:50:56:9f:6b:e4                   10
        """
        """
	    Step 1. Pick a controller obj from controller_list
	    Step 2. call get_ssh_connection on this controller_obj
	    Step 3. Create an object of command_line_interface_client
	    Step 4. set connection on this cli_client obj
	    Step 5. set schema_class on this cli_client obj
	    Step 6. command_line_interface_client will read schema_class.schema_element_order
	            class variable
	    Step 7. command_line_interface_client will read schema_class.schema_parse
	            class variable
	    Step 8. command_line_interface_client will execute cli command, do parsing
	            and return array of py_dicts.
	    Step 9. Loop through each py_dict and read MAC from it, this will give 00:50:56:9f:36:e6
		    and 00:50:56:9f:6b:e4
	    Step 10.Now do this on other controller objects from Step 1.
        """

    def get_cli_schema_class(self, table_name):
        table_schema_map= {
            'arp-table': 'arp_table_schema.ARPTableSchema',
            'mac-table': 'mac_table_schema.MACTableSchema',
            'connection-table': 'connection_table_schema.ConnectionTableSchema',
            'vtep-table': 'vtep_table_schema.VTEPTableSchema',
            'vni': 'vni_schema.VNISchema',
        }
        return table_schema_map[table_name]

    def get_universalRevision(self):
        virtual_wire_scope_object = super(VirtualWire, self).read()
        return virtual_wire_scope_object.universalRevision

    def get_name(self):
        virtual_wire_scope_object = super(VirtualWire, self).read()
        return virtual_wire_scope_object.name

    def tor_attach(self, py_dict):
        if 'hardwaregatewayid' in py_dict:
            attach_endpoint =                                           \
                "vdn/virtualwires/%s/hardwaregateways/%s?action=attach" \
                    % (self.id, py_dict['hardwaregatewayid'])
            schema_object = VirtualWireTORAttachmentSchema(py_dict)
        else:
            attach_endpoint = "vdn/virtualwires/%s/hardwaregateways" % (self.id)
            schema_object = VirtualWireTORAttachmentSchema({})
        temp_endpoint = self.create_endpoint
        temp_id = self.id
        self.create_endpoint = attach_endpoint
        result_obj = self.create(schema_object)
        self.create_endpoint = temp_endpoint
        self.id = temp_id
        if result_obj[0].error is not None:
            raise Exception('Attachment operation failed for binding %s to \
                            virtual wire %s' % (py_dict['hardwaregatewayid'],
                                                self.id))
        return result_obj

    def tor_detach(self, py_dict):
        detach_endpoint =                                               \
                "vdn/virtualwires/%s/hardwaregateways/%s?action=detach" \
                    % (self.id, py_dict['hardwaregatewayid'])
        temp_endpoint = self.create_endpoint
        temp_id = self.id
        self.create_endpoint = detach_endpoint
        schema_object = VirtualWireTORAttachmentSchema({})
        result_obj = self.create(schema_object)
        self.create_endpoint = temp_endpoint
        self.id = temp_id
        if result_obj[0].error is not None:
            raise Exception('Detachment operation failed for binding %s on \
                            virtual wire %s' % (py_dict['hardwaregatewayid'],
                                                self.id))
        return result_obj

    def get_vxlan_id(self):
        vwire = self.read()
        return vwire.vdnId

    def get_uuid(self):
        vwire = self.read()
        return vwire.ctrlLsUuid

if __name__ == '__main__':
    import base_client
    py_dict = {'ipAddress': '10.112.10.xxx', 'userName': 'root', 'password': 'vmware'}
    vsm_obj = VSM("10.112.10.xxx:443", "admin", "default")

    vdn_scope = VDNScope(vsm_obj)
    # What if we dont want to create vdn Scope but use already created one
    # setting the id explicitly
    vdn_scope.id = 'vdnscope-70'
    virtual_wire = VirtualWire(vdn_scope)
    virtual_wire_create = VirtualWireCreateSpecSchema()
    virtual_wire_create.name = 'vWirePython-1'
    virtual_wire_create.tenantId = 'Tenant-1'
    virtual_wire_create.description = 'TmpCreation'
    virtual_wire.create(virtual_wire_create)

    virtual_wire_get_object = VirtualWireSchema()
    response = virtual_wire.query()
    virtual_wire_get_object.set_data(response, 'xml')
    print virtual_wire_get_object.description

    # Bulk Create
    py_dict = {'name': 'vWire-12', 'description': 'Hello-123', 'tenantId': 'Ten-123'}
    virtual_wire_object_ids = base_client.bulk_create(virtual_wire_create, [py_dict, py_dict])
    print virtual_wire_object_ids

    virtual_wire_get_object = virtual_wire.read()
    print virtual_wire_get_object.objectId
    virtual_wire_get_object.description = 'MODIFIED DESCRIPTION'
    if virtual_wire.update(virtual_wire_get_object) != int(200):
        print "Could not UPDATE vWire object"
        print virtual_wire.response.reason
        print virtual_wire.response.read()
        exit(1)
