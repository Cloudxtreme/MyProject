# TODO(James): Module header
#
# Custom exceptions used by library.
#
import httplib

import vmware.common as common
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


class Error(Exception):
    """Unqualified library-specific error."""

    def __init__(self, status_code=None, reason=None, response_data=None,
                 exc=None):
        """
        Initializes attributes for raising error
        @type status_code: int
        @param status_code: Status code sent from inventory object
        @type reason: str
        @param reason: Reason for failure as sent from inventory object
        @type response_data: [may be in json format]
        @param response_data: Data sent from inventory object in response
            [could be exception object raised]
        @type exc: subclass of Exception
        @param exc: Exception object that have similar attributes
        """
        self.status_code = status_code
        self.reason = reason
        self.response_data = response_data
        self.exc = exc

        # If exception carries any status/reason/response data copy them over
        if self.exc:
            if self.status_code is None:
                self.status_code = getattr(exc, 'status_code', None)
                if self.status_code is not None:
                    # Map the status code if it extracted from the exception,
                    # instead of being passed in by the caller
                    self.status_code = self.map_sdk_status_code(
                        self.status_code)
            if self.reason is None:
                self.reason = getattr(exc, 'reason', None)
            if self.response_data is None:
                self.response_data = getattr(exc, 'response_data', None)
            # Setting the same info on exc too, will allow the same exception
            # to be raised instead of raising a new exception which would loose
            # the stack trace from the original exception
            self.exc.status_code = self.status_code
            self.exc.reason = self.reason
            self.exc.response_data = self.response_data
        super(Error, self).__init__(self.reason or self.exc)

    @property
    def status_code_map(self):
        return {}

    def map_sdk_status_code(self, status_code):
        '''
        Method to map status_codes returned by product/sdk to common status
        codes to be used across the products and sdks.
        @type status_code: int|string
        @param status_code: Status code returned by making product/sdk method
            calls
        @rtype: string
        @return: Framework status code from vmware/common/status_codes,
            defaults to status code returned by sdk if map is not defined
        '''
        if status_code is None:
            return
        elif status_code in self.status_code_map:
            return self.status_code_map[status_code]
        else:
            pylogger.debug('%r: status_code=%s is not mapped, skipping ...' %
                           (self, status_code))
            return status_code


class APIError(Error):

    def __init__(self, status_code=None, **kwargs):
        if status_code not in self.status_code_map.values():
            status_code = self.map_sdk_status_code(status_code)
        super(APIError, self).__init__(status_code=status_code, **kwargs)

    @property
    def status_code_map(self):
        # https://docs.python.org/2/library/httplib.html
        http_status_map = {
            httplib.OK: common.status_codes.SUCCESS,
            httplib.CREATED: common.status_codes.CREATED,
            httplib.BAD_REQUEST: common.status_codes.BAD_REQUEST,
            httplib.CONFLICT: common.status_codes.CONFLICT,
            httplib.NOT_FOUND: common.status_codes.NOT_FOUND,
            httplib.METHOD_NOT_ALLOWED: common.status_codes.METHOD_NOT_ALLOWED,
            httplib.NOT_IMPLEMENTED: common.status_codes.NOT_IMPLEMENTED,
            httplib.SERVICE_UNAVAILABLE: common.status_codes.
            SERVICE_UNAVAILABLE,
            httplib.FORBIDDEN: common.status_codes.FORBIDDEN,
            httplib.INTERNAL_SERVER_ERROR: common.status_codes.
            INTERNAL_SERVER_ERROR,
        }
        # Note: Support mapping http error codes 200 and '200' as generic api
        # libraries return integers but nsx-sdk returns strings
        str_map = {str(k): v for k, v in http_status_map.iteritems()}
        http_status_map.update(str_map)

        return http_status_map


class CLIError(Error):

    def __init__(self, status_code=None, **kwargs):
        if status_code not in self.status_code_map.values():
            status_code = self.map_sdk_status_code(status_code)
        super(CLIError, self).__init__(status_code=status_code, **kwargs)

    @property
    def status_code_map(self):
        cli_status_map = {
            0: common.status_codes.SUCCESS,
            1: common.status_codes.FAILURE,
            255: common.status_codes.RUNTIME_ERROR,
        }
        # Note: Support mapping return codes which are of int/str types
        str_map = {str(k): v for k, v in cli_status_map.iteritems()}
        cli_status_map.update(str_map)
        return cli_status_map
