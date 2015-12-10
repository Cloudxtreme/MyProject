import vmware.interfaces.crud_interface as crud_interface
import vmware.common.global_config as global_config
import vmware.schema.vc_schema as vc_schema

pylogger = global_config.pylogger
VCSchema = vc_schema.VCSchema


class VC55CRUDImpl(crud_interface.CRUDInterface):

    @classmethod
    def read(cls, client_object):
        """
        Returns the VC build information.

        @type client_object: VCAPIClient instance
        @param client_object: VCAPIClient instance
        """
        content = client_object.connection.anchor.RetrieveContent()
        version = content.about.licenseProductVersion
        return VCSchema(api_type=content.about.apiType,
                        api_version=content.about.apiVersion,
                        build=content.about.build,
                        full_name=content.about.fullName,
                        license_product_name=content.about.licenseProductName,
                        license_product_version=version,
                        name=content.about.name,
                        os_type=content.about.osType,
                        vendor=content.about.vendor,
                        version=content.about.version)
