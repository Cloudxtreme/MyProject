import base_schema
import credential_schema
import transport_connector_schema
import nvp_transport_zone_binding_schema
import nvp_tag_schema

class TransportNode(base_schema.BaseSchema):
    _schema_name = "transportNode"

    def __init__(self, py_dict=None):
        super(TransportNode, self).__init__()
        self.display_name = None
        self.transport_connectors = [transport_connector_schema.TransportConnector()]
        self.uuid = None
        self.tags = [nvp_tag_schema.Tag()]
        self.integration_bridge_id = None
        self.mgmt_rendezvous_client = None
        self.mgmt_rendezvous_server = None
        self.credential = credential_schema.Credential()
        self.tunnel_probe_random_vlan = None
        self.zone_forwarding = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

        self._uuid_meta = {'isReq':False,'type':'string'}
        self._tags_meta = {'isReq':False,'type':'array','maxLen':5}
        self._display_name_meta = {'isReq':False,'type':'string',
                                    'default':'<uuid>','maxLen':40}

        self._transport_connectors_meta = {'isReq':False,'type':'array'}
        self._integration_bridge_id_meta = {'isReq':False,'type':'string'}
        self._mgmt_rendezvous_client_meta = {'isReq':False,'type':'boolean',
                                                'default':False}
        self._mgmt_rendezvous_server_meta = {'isReq':False,'type':'boolean',
                                                'default':False}
        self._credential_meta = {'isReq':False,'type':'object'}
        self._tunnel_probe_random_vlan_meta = {'isReq':False,'type':'boolean',
                                                        'default':False}
        self._zone_forwarding_meta = {'isReq':False,'type':'boolean',
                                                        'default':False}

    def add_transport_connector(self, transport_connetor):
        self.transport_connectors.append(transport_connector)

    def add_tag(self, tag):
        self.tags.append(tag)

if __name__=='__main__':
    pass

