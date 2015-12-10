import base_schema
import vmware.common.logger as logger
import nvp_tag_schema

class TransportZone(base_schema.BaseSchema):
    _schema_name = "transportZone"

    def __init__(self, py_dict=None):
        super(TransportZone, self).__init__()
        self.display_name = None
        self.tags = [nvp_tag_schema.Tag()]
        self.uuid = None
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

    def add_tag(self, tag):
        self.tags.append(tag)

if __name__=='__main__':
    tz = TransportZone()
    tz.setData_json('{"display_name":"name","tags":[{"scope":"scope1","tag":"tag1"}]}')
    print tz.display_name
    print tz.tags[0].tag
    print tz.getData_json()