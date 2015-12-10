import base_schema
from vc_info_schema import VCInfoSchema

class VSMGlobalConfigSchema(base_schema.BaseSchema):
    ''' This managed object is used to register VSM with VC '''
    _schema_name = "vsmGlobalConfig"
    def __init__(self, py_dict=None):
        ''' Constructor to create VSMGlobalConfigSchema object

        @param py_dict : python dictionary to construct this object
        '''
        super(VSMGlobalConfigSchema, self).__init__()
        self.vcInfo = VCInfoSchema()
        self._attributeName = 'xmlns'
        self._attributeValue = "vmware.vshield.edge.2.0"
        self.set_data_type('xml')
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

    def get_data_xml(self):
        _objXML = """<vsmGlobalConfig xmlns='vmware.vshield.edge.2.0'>\
<vcInfo>\
<ipAddress>%s</ipAddress>\
<userName>%s</userName>\
<password>%s</password>\
</vcInfo>\
</vsmGlobalConfig>"""

        return _objXML % (self.vcInfo.ipAddress, self.vcInfo.userName, self.vcInfo.password)

if __name__=='__main__':
    '''
    XML required for registering vsm is:
    <vsmGlobalConfig xmlns='vmware.vshield.edge.2.0'>
         <vcInfo>
            <ipAddress>#{vc.ip}</ipAddress>
            <userName>#{vc.username}</userName>
            <password>#{vc.password}</password>
         </vcInfo>
       </vsmGlobalConfig>
    '''
    py_dict = {'vcinfo': {'ipaddress': '10.110.28.50', 'username': 'root', 'password': 'vmware'}}
    test_obj = VSMGlobalConfigSchema(py_dict)
    from vsm import VSM
    import vsm_global_config
    import base_client
    vsm_obj = VSM("10.110.28.44", "admin", "default", "")
    global_config = vsm_global_config.VSMGlobalConfig(vsm_obj)
    py_dict = {'vcinfo': {'ipaddress': '10.110.28.50', 'username': 'root', 'password': 'vmware'}}
    results = base_client.bulk_create(global_config, [py_dict])

    vsmGC = VSMGlobalConfigSchema()
    vsmGC.vcInfo.ipAddress = '10.112.10.180'
    vsmGC.vcInfo.userName = 'root'
    vsmGC.vcInfo.password = 'vmware'

    print vsmGC.get_data_xml()
