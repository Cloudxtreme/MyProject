import vsm_client
from vsm import VSM
from edge import Edge
import vmware.common.logger as logger
from vnics_schema import VnicsSchema
import result

class Vnics(vsm_client.VSMClient):
    """ Class to create vnics/LIFs on edge"""

    def __init__(self, edge):
        """ Constructor to create vnic managed object

        @param edge object on which vnic will be created
        """
        super(Vnics, self).__init__()
        self.log.debug("Creating Vnics on Edge %s" % edge.id)
        self.schema_class = 'vnics_schema.VnicsSchema'
        self.set_connection(edge.get_connection())
        self.set_create_endpoint("/edges/" + edge.id + "/vnics/?action=patch")
        self.set_delete_endpoint("/edges/" + edge.id + "/vnics/?index=")
        self.set_read_endpoint("/edges/" + edge.id + "/vnics")
        self.set_query_endpoint("/edges/" + edge.id + "/vnics")
        self.id = None

    def query(self):
        """ Query all Vnics on the given edge

        @param None
        """
        vnics_schema = VnicsSchema()
        vnics_schema.set_data(self.base_query(), self.accept_type)
        return vnics_schema

    def delete(self, vnic_index):
        self.delete_endpoint = self.delete_endpoint + vnic_index['vnic_index']
        return super(Vnics,self).delete(None)
