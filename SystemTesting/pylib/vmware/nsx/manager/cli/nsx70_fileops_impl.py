import os
import time
import vmware.common as common
import vmware.common.global_config as global_config
import vmware.common.timeouts as timeouts
import vmware.common.utilities as utilities
import vmware.interfaces.fileops_interface as fileops_interface

pylogger = global_config.pylogger


class NSX70FileOpsImpl(fileops_interface.FileOpsInterface):

    @classmethod
    def file_append(cls, client_object, file_name=None,
                    size=None, append_string=None):
        """
        Append a string in the desired file of the NSX Manager, this tool
        uses the 'echo' command to achieve this.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host
        @type file_name: string
        @param file_name: The path to the file to append
        @type size: Integer
        @param size: The size of text to append to the file
        @type append_string: string
        @param append_string: The string to write
        @rtype: status_code
        @return: SUCCESS or FAILURE
        """
        if not append_string:
            client_object.connection.login_to_st_en_terminal(expect=['#'])
            expect_prompt = ['>', '#']
            log_separator = "printf '%.s*' {1..100} >> " + file_name
            command = 'echo %s >> %s' % (os.urandom(size).encode('hex'),
                                         file_name)
            zip_file = 'echo ls %s.*.gz' % file_name
            try:
                pylogger.info("CLI send to append text to file: [%s]"
                              % file_name)
                client_object.connection.request(log_separator, expect_prompt)
                client_object.connection.request(command, expect_prompt)
                client_object.connection.request(log_separator, expect_prompt)
                pylogger.info("Text appended to file: [%s]" % file_name)
                timeouts.file_creation_timeout.wait_until(
                    client_object.connection.request,
                    args=[zip_file, expect_prompt])
                return common.status_codes.SUCCESS
            except Exception, error:
                pylogger.exception(error)
                return common.status_codes.FAILURE
        else:
            try:
                client_object.connection.login_to_st_en_terminal(expect=['#'])
                cmd = "echo '%s' >> '%s'" % (append_string, file_name)
                expect_prompt = ['>', '#']
                client_object.connection.request(cmd, expect_prompt)
                return common.status_codes.SUCCESS
            except Exception, error:
                pylogger.exception(error)
                return common.status_codes.FAILURE

    # TODO:smyneni: refactor query file method
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
            client_object.connection.login_to_st_en_terminal(expect=['#'])
            expect_prompt = ['>', '#']

            result = client_object.connection.request(command, expect_prompt)
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
        client_object.connection.login_to_st_en_terminal(expect=['#'])

        command = ("awk \"/%s/,/%s/\" %s | grep \"%s\" | wc -l" %
                   (start_str, end_str, file_name, pattern))
        pylogger.debug("Executing command %s" % command)
        expect_prompt = ['>', '#']
        result = client_object.connection.request(command, expect_prompt)
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

        # TODO:Use the vmware.common.timeouts instead
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

                if str(common.status_codes.SUCCESS) in result:
                    return common.status_codes.SUCCESS
            pylogger.debug("Looking for log message still, %s" %
                           max_wait + " seconds remaining")
            client_object.connection.logout_of_st_en_terminal()
            time.sleep(interval)
            max_wait -= interval

        return common.status_codes.FAILURE
