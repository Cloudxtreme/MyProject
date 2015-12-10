import base_schema
from nvp_port_security_address_pair import PortSecurityAddressPairSchema
from nvp_collector_config import CollectorConfigSchema
from nvp_tag_schema import Tag

class LogicalSwitchPortSchema(base_schema.BaseSchema):
    _schema_name = "logicalswitchport"

    def __init__(self, py_dict=None):
        """ Constructor to create LogicalSwitchPortSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(LogicalSwitchPortSchema, self).__init__()
        self.uuid = None
        self.display_name = None
        self.admin_status_enabled = None
        self.allow_egress_multicast = None
        self.allow_ingress_multicast = None
        self.allowed_address_pairs = [PortSecurityAddressPairSchema()]
        self.mac_learning = None
        self.mirror_targets = [CollectorConfigSchema()]
        self.portno = None
        self.queue_uuid = None
        self.security_profiles = ['']
        self.tags = [Tag()]
        self.type = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
