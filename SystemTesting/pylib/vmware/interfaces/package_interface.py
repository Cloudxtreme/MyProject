class PackageInterface(object):

    @classmethod
    def install(cls, client_object, resource=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def uninstall(cls, client_object, resource=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def update(cls, client_object, resource=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def configure_package(cls, client_object, operation=None, resource=None,
                          **kwargs):
        raise NotImplementedError

    @classmethod
    def are_installed(cls, client_object, packages=None):
        raise NotImplementedError
