import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx.manager.appliancemanagement.api.appmgmt_crud_impl \
    as appmgmt_crud


pylogger = global_config.pylogger


class NSX70CRUDImpl(appmgmt_crud.AppMgmtCRUDImpl, base_crud_impl.BaseCRUDImpl):

    @classmethod
    def get_node_id(cls, client_obj, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_base_url(cls, client_obj, **kwargs):
        raise NotImplementedError
