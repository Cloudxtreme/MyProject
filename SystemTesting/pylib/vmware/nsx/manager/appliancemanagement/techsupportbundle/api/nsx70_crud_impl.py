import os
import subprocess
import time
import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.appliance.node.readnodesupportbundle \
    as readnodesupportbundle

DEFAULT_TECHSUPPORT_BUNDLE_PATH = '/tmp/vdnet/techsupportbundle/'

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    # Attribute map
    _attribute_map = {}
    _client_class = readnodesupportbundle.ReadNodeSupportBundle
    _schema_class = ''

    @classmethod
    def read(cls, client_obj, id_=None, **kwargs):
        result_dict = dict()
        result_dict['response_data'] = dict()
        result_dict['result'] = os.path.isfile(id_)
        result_dict['response_data']['status_code'] = 200
        return result_dict

    @classmethod
    def create(cls, client_obj, schema=None, **kwargs):
        if 'logdir' in kwargs:
            file_path = kwargs.get('logdir')
        else:
            file_path = DEFAULT_TECHSUPPORT_BUNDLE_PATH
        cls.assign_response_schema_class()
        client_class_obj = cls._client_class(
            connection_object=client_obj.connection)
        result, filename = cls._tech_supportbundle_create(
            client_class_obj.read(), file_path)
        schema_dict = {'id_': filename}
        result_dict = schema_dict
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict

    @classmethod
    def verify_support_bundle(cls, client_obj, **kwargs):
        id_ = client_obj.id_
        tmp_path = DEFAULT_TECHSUPPORT_BUNDLE_PATH + 'tmp_extract'
        if not os.path.exists(tmp_path):
            os.makedirs(tmp_path)
        result_dict = dict()
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = 200
        if os.path.isfile(id_):
            try:
                subprocess.check_call(['tar', '-xvf'+id_, '-C' + tmp_path])
                result_dict['result'] = True
            except subprocess.CalledProcessError:
                pylogger.error("Extracting " + id_ +
                               " Techsupportbundle failed")
                result_dict['result'] = False
        subprocess.check_call(['rm', '-rf', tmp_path])
        return result_dict

    @classmethod
    def _tech_supportbundle_create(cls, file_content, file_path):
        try:
            if not os.path.exists(file_path):
                os.makedirs(file_path)
            filename = file_path + 'techsupportbundle-'\
                + time.strftime("%Y%m%d-%H%M%S") + '.tar.gz'
            pylogger.info("Saving Techsupport Bundle in : %s" % filename)
            f = open(filename, 'w')
            f.write(file_content)
            f.close()
        except Exception:
            raise Exception("Failed to Save TechSupportBundle")
        return True, filename