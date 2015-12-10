import base_schema
import tag_schema

class TransportConnector(base_schema.BaseSchema):
    _schema_name = "transportConnector"

    def __init__(self, py_dict=None):
        super(TransportConnector, self).__init__()
        self.type = None
        self.transport_zone_uuid = None
        self.ip_address = None

        self._type_meta = {'isReq':True,'type':'string'}
        self._transport_zone_uuid_meta = {'isReq':True,'type':'string'}
        self._ip_address_meta = {'isReq':True,'type':'string'}

if __name__=='__main__':
    pass
