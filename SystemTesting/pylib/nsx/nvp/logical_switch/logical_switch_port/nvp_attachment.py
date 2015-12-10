import pylib
import nvp_client
import vmware.common.logger as logger
from nvp_logical_port_attachment_schema import LogicalPortAttachmentSchema
from nvp_vif_attachment import VIFAttachmentSchema
class LogicalPortAttachment(nvp_client.NVPClient):

    def __init__(self, logical_port=None):
        """ Constructor to create LogicalPortAttachment object

        @param LogicalSwitchPort object on which LogicalPortAttachment object has to be configured
        """
        super(LogicalPortAttachment, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'nvp_logical_port_attachment_schema.LogicalPortAttachmentSchema'
        self.schema_class = 'nvp_vif_attachment.VIFAttachmentSchema'

        if logical_port is not None:
            self.set_connection(logical_port.get_connection())
            self.set_create_endpoint("%s/%s/attachment" %(logical_port.get_create_endpoint(),\
            logical_port.id))

        self.id = None

if __name__ == '__main__':
    pass
