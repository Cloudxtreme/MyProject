import base_schema

class VirtualWireTORAttachmentSchema(base_schema.BaseSchema):
    """This schema is used for configuration
    """
    _schema_name = "hardwaregatewaybinding"
    def __init__(self, py_dict=None):
        """ Constructor to create VirtualWireTORAttachmentSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(VirtualWireTORAttachmentSchema, self).__init__()
        self.hardwaregateway_id = None
        self.switchname = None
        self.portname = None
        self.vlan = None
        self.set_data_type('xml')

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

if __name__ == '__main__':
    import pylib
    vs = VirtualWireTORAttachmentSchema({"torbindings":["torbd1", "torbd2"]})
    print vs.get_data("xml")
