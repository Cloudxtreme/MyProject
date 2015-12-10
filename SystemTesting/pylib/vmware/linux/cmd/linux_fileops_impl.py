import json
import os
import time

import vmware.common as common
import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.interfaces.fileops_interface as fileops_interface

pylogger = global_config.pylogger


class LinuxFileOpsImpl(fileops_interface.FileOpsInterface):

    @classmethod
    def syslog_append(cls, client_object, syslog_message=None):
        """
        Append a single string in the syslog file of the linux host, this tool
        uses the 'logger' command to achieve this, so it should function
        seamlessly between esx, ubuntu and rhel systems

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host
        @type syslog_message: string
        @param syslog_message: The string to write to the syslog
        @rtype: status_code
        @return: SUCCESS or FAILURE
        """
        pylogger.debug("Appending '%s' to syslog" % syslog_message)

        command = 'logger %s' % syslog_message
        try:
            client_object.connection.request(command)
            return common.status_codes.SUCCESS
        except Exception, error:
            pylogger.exception(error)
            return common.status_codes.FAILURE

    @classmethod
    def file_append(cls, client_object, file_name=None, append_string=None,
                    size=None):
        """
        Append a single string in the desired file of the linux host, this tool
        uses the 'echo' command to achieve this, so it should function
        seamlessly between esx, ubuntu and rhel systems. This is similar to the
        syslog_append method except in this case you must specify a file name

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host
        @type file_name: string
        @param file_name: The path to the file to append
        @type append_string: string
        @param append_string: The string to write
        @type size: Integer
        @param size: Size of string to write
        @rtype: status_code
        @return: SUCCESS or FAILURE
        """
        pylogger.debug("Appending: %s to file: %s" % (append_string,
                                                      file_name))

        command = 'echo "%s" >> %s' % (append_string, file_name)
        try:
            client_object.connection.request(command)
            return common.status_codes.SUCCESS
        except Exception, error:
            pylogger.exception(error)
            return common.status_codes.FAILURE

    @classmethod
    def file_find_context(cls, client_object, file_name=None,
                          start_str=None, end_str=None):
        """
        Find a string in a file between a start and end string

        i.e. file contains:
             aaa
             bbb
             ccc
             ddd
             eee

             file_find_context(file_name, bbb, ddd)
             returns: ccc

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host
        @type file_name: string
        @param file_name: The path to the file to append
        @type start_str: string
        @param start_str: The string used to start capturing data
        @type end_str: string
        @param end_str: The string used to stop capturing data
        @rtype: status_code
        @return: SUCCESS or FAILURE
        """
        pylogger.debug("Looking for %s after %s in file: %s" %
                       (end_str, start_str, file_name))

        command = "awk \"/%s/,/%s/\" %s |tail -1" % (start_str, end_str,
                                                     file_name)
        try:
            result = client_object.connection.request(command)
            response = result.response_data
            if end_str in response:
                pylogger.debug("found the search string %s", end_str)
                return common.status_codes.SUCCESS
            else:
                pylogger.debug("could not find the search string %s", end_str)
                return common.status_codes.FAILURE
        except Exception, error:
            pylogger.exception(error)
            raise ValueError(error)

    @classmethod
    def find_pattern_count(cls, client_object, file_name=None,
                           start_str=None, end_str=None, pattern=None):
        """
        Count the number of occurrences of pattern in a file between start
        string and end string

        i.e. file contains:
             aaa
             bbb
             ccc
             ccc
             ddd
             eee

             file_find_context(file_name, bbb, ddd, ccc)
             returns: 2

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host
        @type file_name: string
        @param file_name: The path to the file to append
        @type start_str: string
        @param start_str: The string used to start capturing data
        @type end_str: string
        @param end_str: The string used to stop capturing data
        @type pattern: string
        @param pattern: the string which you are seeking
        @rtype: status_code
        @return: SUCCESS or FAILURE
        """
        pylogger.debug("Looking for %r between %r and %r in file: %r",
                       pattern, start_str, end_str, file_name)

        command = ("awk \"/%s/,/%s/\" %s | grep '%s' | wc -l" %
                   (start_str, end_str, file_name, pattern))
        pylogger.debug("Executing command %s" % command)
        result = client_object.connection.request(command)
        response = result.response_data
        pylogger.debug("Found the search string %s, %s times" %
                       (pattern, response))
        return int(response)

    @classmethod
    def query_file(cls, client_object, file_name=None, grep_after=None,
                   grep_string=None, max_wait=None, interval=None,
                   pattern=None, count=None):
        """
        Repeatedly look in a file until the grep_string string appears, which
        must be found after the grep_after string

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type file_name: string
        @param file_name: the file name to which you wish to find a string
        @type grep_after: string
        @param grep_after: the context string that needs to be found first
        @type grep_string: string
        @param grep_string: the context string that needs to be found second
        @type max_wait: integer
        @param max_wait: the maximum number of seconds to wait for string
        @type interval: integer
        @param interval: seconds between intervals
        @type pattern: string
        @param pattern: regex used to search for pattern in a file
        @type count: integer
        @param count: number of occurrences of pattern to be found
        @rtype: status_code
        @return: SUCCESS or FAILURE
        """

        max_wait = utilities.get_default(max_wait, 30)
        interval = utilities.get_default(interval, 5)

        pylogger.debug("Waiting up to " + str(max_wait) + " seconds for " +
                       "\"%s\" to show up in the file: %s" %
                       (grep_string, file_name))

        while max_wait > 0:
            if count is not None and pattern is not None:
                try:
                    result = cls.find_pattern_count(client_object,
                                                    file_name=file_name,
                                                    start_str=grep_after,
                                                    end_str=grep_string,
                                                    pattern=pattern)
                    if count == result:
                        return common.status_codes.SUCCESS
                except Exception, error:
                    pylogger.error("Failed in find_pattern_count: %s" % error)
                    raise
            else:
                try:
                    result = cls.file_find_context(client_object,
                                                   file_name=file_name,
                                                   start_str=grep_after,
                                                   end_str=grep_string)
                except Exception, error:
                    pylogger.exception("Failed to find context in the file: "
                                       "%s" % error)
                    pylogger.debug("failed to find context, "
                                   "retry before timeout")
                    pass

                if "SUCCESS" in result:
                    return common.status_codes.SUCCESS
            pylogger.debug("Looking for log message still, %s" %
                           max_wait + " seconds remaining")
            time.sleep(interval)
            max_wait -= interval

        return common.status_codes.FAILURE

    @classmethod
    def download_files(cls, client_object,
                       resource=None, destination=None, timeout=None):
        """
        Download files onto the host

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type resource: string
        @param resource: file or url to a specific resource
        @type destination: string
        @param destination: destination directory
        @rtype: status_code
        @return: SUCCESS or FAILURE
        """
        timeout = utilities.get_default(timeout, 120)

        pylogger.info("Downloading files onto host")
        timestamp = time.time()
        dest_tmp = '/%s/%d' % (destination, int(timestamp))
        cmd = 'mkdir %s' % dest_tmp
        try:
            client_object.connection.request(cmd, strict=False)
        except Exception as e:
            pylogger.exception("could not make a tmp dir", e)
            raise

        for source in resource:
            command = 'wget -P %s %s' % (dest_tmp, source)
            pylogger.debug(command)
            try:
                client_object.connection.request(command, timeout=timeout)
            except Exception, error:
                pylogger.exception(error)
                error.status_code = common.status_codes.RUNTIME_ERROR
                raise

        cmd1 = 'mv -f %s/* %s; rm -rf %s' % (dest_tmp, destination, dest_tmp)
        try:
            client_object.connection.request(cmd1, strict=False)
        except Exception as error:
            pylogger.exception(
                " failed to copy files and remove a tmp directory", error)
            raise
        return common.status_codes.SUCCESS

    @classmethod
    def remove_file(cls, client_object,
                    options=None,
                    file_name=None,
                    timeout=None):
        """
        Remove files from the host

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type options: string
        @param options: Options to pass with the rm command
        @type timeout: integer
        @param timeout: Time to complete operation
        @type file_name: string
        @param file_name: the file name you wish to remove
        @rtype: status_code
        @return: SUCCESS or FAILURE
        """

        pylogger.debug("Removing following file from host %r: %r" %
                       (client_object.ip, file_name))

        command = 'rm %s %s' % (options, file_name)

        try:
            client_object.connection.request(command, timeout=timeout)
        except Exception:
            pylogger.exception("Failed to remove files from host: %s %s" %
                               (client_object.ip, file_name))
            raise
        return common.status_codes.SUCCESS

    @classmethod
    def get_dict_from_json_file(cls, client_object,
                                get_dict_from_json_file=None,
                                file_name=None):
        '''
        Retrieves a json file and returns a dict

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type file_name: string
        @param file_name: json file to read
        @rtype: dict
        @return: Dict containing parsed json file
        '''
        _ = get_dict_from_json_file
        pylogger.debug('Attempting to get json file: %s' % file_name)
        response_data = {}

        cmd = 'cat %s' % file_name
        try:
            result = client_object.connection.request(cmd)
        except Exception as error:
            pylogger.error("Failed to cat file: %s" % error)
            raise

        pylogger.debug("Content of file: %s" %
                       result.response_data)

        data = json.loads(result.response_data)
        response_data['file'] = data

        result_dict = {'json': response_data}
        return result_dict

    @classmethod
    def move_file(cls, client_object, source_path, destination_path,
                  file_name, dest_file_name):
        '''
        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type source_path: string
        @param source_path: path of the source file
        @type destination_path: string
        @param destination_path: path of the destination file
        @type file_name: string
        @param file_name: the source file you wish to move
        @type: dest_file_name: string
        @param dest_file_name: the name of the destination file
        @rtype: status_code
        @return: SUCCESS or FAILURE
        '''
        pylogger.debug('Attempting to move %s from %s to %s as %s'
                       % (file_name, source_path, destination_path,
                          dest_file_name))
        source = os.path.join(source_path, file_name)
        destination = os.path.join(destination_path, dest_file_name)
        cmd = 'mv %s %s' % (source, destination)
        try:
            client_object.connection.request(cmd)
        except Exception:
            pylogger.exception("File move failed with error")
            raise
        return common.status_codes.SUCCESS
