import vmware.common as common
import vmware.common.constants as constants
import vmware.common.errors as errors
import vmware.common.global_config as global_config
import vmware.interfaces.fileops_interface as fileops_interface

pylogger = global_config.pylogger


class NSX70FileOpsImpl(fileops_interface.FileOpsInterface):

    @classmethod
    def delete_file(cls, client_object, file_name=None):
        """
        Delete given file on CCP node

        @type file_name: String
        @param file_name: file name with absolute path,

        """
        cmd = "rm -f %s" % file_name
        result = client_object.connection.request(cmd)
        if result.response_data:
            return constants.Result.FAILURE.upper()
        return constants.Result.SUCCESS.upper()

    @classmethod
    def delete_backend_file(cls, client_object, path, file_name):
        endpoint = 'rm -rf ' + ' ' + path + '/' + file_name
        expect_prompt = ['>', '#']
        pylogger.debug("Command executed to delete file: [%s]" % endpoint)
        result = client_object.connection.request(endpoint, expect_prompt)
        response = result.response_data
        if 'No such file or directory' in response:
            pylogger.debug("%s file_name does not exist, skipping delete")
            return common.status_codes.SUCCESS
        if 'cannot remove' in response:
            raise errors.CLIError(status_code=common.status_codes.FAILURE,
                                  reason=response)
        else:
            return common.status_codes.SUCCESS
