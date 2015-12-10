import vmware.common as common
import vmware.common.errors as errors
import vmware.common.global_config as global_config
import vmware.common.timeouts as timeouts
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


pylogger = global_config.pylogger


class NSX70ClusterImpl(base_crud_impl.BaseCRUDImpl):

    @classmethod
    def wait_for_required_cluster_status(
            cls, client_object, required_status=None, time_to_monitor=None):
        if required_status is None:
            raise ValueError("Mandatory parameter *required_status* missing")

        def cluster_status_checker(result_dict):
            return (result_dict["response"]["mgmt_cluster_status"]["status"]
                    == required_status)

        def exc_handler(exc):
            pylogger.debug('Cluster status check returned exception: %s' % exc)

        pylogger.debug("Checking for cluster status ...")
        result_dict = timeouts.cluster_stability_check.wait_until(
            client_object.status, checker=cluster_status_checker,
            exc_handler=exc_handler, timeout=time_to_monitor, logger=pylogger)
        result = None
        if (result_dict is not None and
                "response" in result_dict and
                "mgmt_cluster_status" in result_dict["response"] and
                "status" in result_dict["response"]["mgmt_cluster_status"]):
            result = result_dict["response"]["mgmt_cluster_status"]["status"]
        if result != required_status:
            reason = ("NSX Manager cluster status check failed, "
                      "was %s but expected %s" % (result, required_status))
            raise errors.Error(status_code=common.status_codes.FAILURE,
                               reason=reason)
