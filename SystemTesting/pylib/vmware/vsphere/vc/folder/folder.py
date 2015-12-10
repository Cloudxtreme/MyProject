import vmware.base.folder as folder


class Folder(folder.Folder):

    def get_impl_version(self, execution_type=None, interface=None):
                return "VC55"
