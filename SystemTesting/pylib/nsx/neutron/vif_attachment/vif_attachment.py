import base_client
import vmware.common.logger as logger
import neutron_client
import string


class VifAttachment(neutron_client.NeutronClient):

    def __init__(self, logical_switch_port=None):
        """ Constructor to create VifAttachment object

        @param VifAttachment object on which VifAttachment object has to be configured
        """
        super(VifAttachment, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'vif_attachment_schema.VifAttachmentSchema'

        if logical_switch_port is not None:
            self.set_connection(logical_switch_port.get_connection())

        self.set_create_endpoint(logical_switch_port.create_endpoint + "/" + logical_switch_port.id +"/attachment")
        self.id = None

    def create_using_put(self, py_dict):

        # Workaound for Bug 1123879

        if py_dict.has_key('_host_type'):
            if py_dict['_host_type'] == "esx":
                vif = py_dict['vif_uuid']
                vnic_label =  vif.split("-")[len(vif.split("-"))-1]
                v_arr = vif.split("-")
                v_len = len(v_arr)
                vm_uuid = string.join(v_arr[0:(v_len-1)],"-")
                py_dict['vif_uuid'] = vm_uuid + "." + vnic_label.zfill(3)

        return super(VifAttachment, self).create_using_put(py_dict)
 

if __name__ == '__main__':
    pass
