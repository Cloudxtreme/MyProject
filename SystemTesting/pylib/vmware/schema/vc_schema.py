import vmware.common.base_schema as base_schema


class VCSchema(base_schema.BaseSchema):

    def __init__(self, api_type=None, api_version=None, build=None,
                 full_name=None, license_product_name=None,
                 license_product_version=None, name=None,
                 os_type=None, vendor=None, version=None):

        self.api_type = api_type
        self.api_version = api_version
        self.build = build
        self.full_name = full_name
        self.license_product_name = license_product_name
        self.license_product_version = license_product_version
        self.name = name
        self.os_type = os_type
        self.vendor = vendor
        self.version = version
