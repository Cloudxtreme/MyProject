import nvp_client
import connection
import vmware.common.logger as logger
import nvp_transport_zone_schema
import nvp_tag_schema

class TransportZone(nvp_client.NVPClient):

    def __init__(self, nvp_controller=None):
        super(TransportZone, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'nvp_transport_zone_schema.TransportZone'

        if nvp_controller is not None:
            self.set_connection(nvp_controller.get_connection())

        self.set_create_endpoint('transport-zone')

if __name__=='__main__':

    tz = nvp_transport_zone_schema.TransportZone()
    tz.set_data('{"display_name":"name"}', 'application/json')
    print tz.display_name
    print json.loads(tz.getData())
    tz.display_name = "name"

    tg1 = nvp_tag_schema.Tag()
    tg1.scope = "tz"
    tg1.tag = "tag1"

    tgarr = []
    tgarr.append(tg1)
    tz.tags.append(tg1)
    tz.addTag(tg1)

    print tz.getData()

    tzc = TransportZone()

    conn = connection.Connection("192.168.1.5", "admin", "admin", "ws.v1", "https")
    tzc.set_connection(conn)
    tzc.set_create_endpoint("transport-zone")
    tzc.create(tz)

    tzu = nvp_transport_zone_schema.TransportZone()
    tzu.display_name = "name1"

    print tzu.getData()
    tzc.update(tzu)

    tzc.query()

    tzr = tzc.read()

    print tzr.display_name

    tzc.delete()
