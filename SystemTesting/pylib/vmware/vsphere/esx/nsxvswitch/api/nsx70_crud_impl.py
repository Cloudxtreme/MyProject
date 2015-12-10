import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.common.result as result
from vmware.interfaces.crud_interface import CRUDInterface

pylogger = global_config.pylogger

class NSX70CRUDImpl(CRUDInterface):

    @classmethod
    def create(cls, esx, anchor=None):
        raise NotImplementedError("STUB")

    @classmethod
    def read(cls, esx, anchor=None):
        # This is where the implementation will reside
        raise NotImplementedError("STUB")

    @classmethod
    def update(cls, esx, anchor=None):
        # This is where the implementation will reside
        raise NotImplementedError("STUB")

    @classmethod
    def delete(cls, esx, anchor=None):
        # This is where the implementation will reside
        raise NotImplementedError("STUB")
