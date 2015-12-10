import vmware.common.logger as logger
import vsm_client
from vsm import VSM

class VsmVersion(vsm_client.VSMClient):
    def __init__(self, vsm=None):
        super(VsmVersion, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'vsmglobalinfo_schema.VSMGlobalInfoSchema'
        self.set_connection(vsm.get_connection())
        conn = self.get_connection()
        conn.set_api_header("api/1.0/")
        self.set_read_endpoint("appliance-management/global/info")
        self.id = None
        self.update_as_post = False

    def get_build(self):
        globalInfoSchema = self.read()
        buildNumber = globalInfoSchema.versionInfo.buildNumber
        return buildNumber

    def get_version(self):
        globalInfoSchema = self.read()
        majorVersion = globalInfoSchema.versionInfo.majorVersion
        minorVersion = globalInfoSchema.versionInfo.minorVersion
        patchVersion = globalInfoSchema.versionInfo.patchVersion
        version = "%s.%s.%s" % (majorVersion, minorVersion, patchVersion)
        return version

if __name__=='__main__':
    vsm_obj = VSM("10.143.127.220:443", "admin", "default","")
    versionObj = VsmVersion(vsm_obj)
    build = versionObj.get_build()
    version = versionObj.get_version()
    print "vsm build is %s" % build
    print "vsm version is %s" % version