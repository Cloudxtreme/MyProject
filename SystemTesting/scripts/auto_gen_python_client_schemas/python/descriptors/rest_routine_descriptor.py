#!/usr/bin/python2.6
#
# Copyright (C) 2011-2012 Nicira, Inc.
#
# This is an unpublished work, is confidential and proprietary to
# Nicira, Inc. as a trade secret and is not to be used or
# disclosed without Nicira's consent.

__all__ = ["RestRoutineDescriptor"]


import copy
import httplib
import os
import re
import simplejson
import time
import traceback
import types
import urlparse
#from webob import exc
#from webob import Request
#from webob import Response
import yaml

from lib.json_schema import JsonSchema
from descriptors import lg
from descriptors.descriptor import Descriptor
from descriptors.descriptor import SCHEMA_REGISTRY
#from management_api.napi.task_manager import get_task_manager

REST_ROUTINE_SCHEMA_FILE = os.path.join(os.path.dirname(__file__),
                                        'rest_routine_descriptor.yml')

REST_ROUTINE_TYPES = dict((r.id, r)
                          for r in yaml.load(open(REST_ROUTINE_SCHEMA_FILE)))

FLAT_OBJECT_META_RAW_SCHEMA = REST_ROUTINE_TYPES['FlatObjectMetaSchema'].raw_schema
FLAT_OBJECT_META_SCHEMA = JsonSchema(
    FLAT_OBJECT_META_RAW_SCHEMA, strict=True,
    type_path=["FlatObjectMetaSchema"], schema_registry=SCHEMA_REGISTRY)


STRING_META_RAW_SCHEMA = REST_ROUTINE_TYPES['StringMetaSchema'].raw_schema
STRING_META_SCHEMA = JsonSchema(
    STRING_META_RAW_SCHEMA, strict=True, type_path=["StringMetaSchema"],
    schema_registry=SCHEMA_REGISTRY)


NO_PARAM_RAW_SCHEMA = REST_ROUTINE_TYPES['NoRestRequestParameters'].raw_schema
NO_PARAM_SCHEMA = JsonSchema(
    NO_PARAM_RAW_SCHEMA, strict=True,
    type_path=["NoRestRequestParameters"], schema_registry=SCHEMA_REGISTRY)


REST_ROUTINE_RAW_SCHEMA = REST_ROUTINE_TYPES['RestRoutine'].raw_schema
REST_ROUTINE_SCHEMA = JsonSchema(
    REST_ROUTINE_RAW_SCHEMA, strict=True,
    type_path=["RestRoutine"], schema_registry=SCHEMA_REGISTRY)


REST_ROUTINE_AUTO_RELOAD_KEY = "REST_ROUTINE_AUTO_RELOAD"


DEFAULT_HEADERS_SCHEMA = {"$ref": "DefaultHeaders"}
DEFAULT_CONTENT_TYPE = {"type": "string",
                        "enum": ["text/html", "text/plain", "application/json",
                                 ""]}  # "" for 204


IGNORE_RESPONSE_VALIDATION_ERRORS = 1  # Non-zero: ignore; 0: don't ignore


class _RestRequest(object):
    def __init__(self, parameters_schema=None, headers_schema=None,
                 content_type_schema=None, body_type_id=None):
        self.parameters_schema = parameters_schema
        self.headers_schema = headers_schema
        self.content_type_schema = content_type_schema
        self.body_type_id = body_type_id

    def __cmp__(self, other):
        return self.__dict__.__cmp__(other.__dict__)

    @property
    def meta_spec(self):
        return self.__dict__


class _RestResponse(object):
    def __init__(self, status, headers_schema=None, content_type_schema=None,
                 body_type_id=None):
        if hasattr(status, '__iter__'):
            self.status = status
        else:
            self.status = [status]
        self.headers_schema = headers_schema
        self.content_type_schema = content_type_schema
        self.body_type_id = body_type_id

    def __cmp__(self, other):
        return self.__dict__.__cmp__(other.__dict__)

    @property
    def meta_spec(self):
        return self.__dict__


class PathArgument(object):
    def __init__(self, name, help_summary, pattern="[^/]*"):
        self.name = name
        self.pattern = pattern
        self.help_summary = help_summary

    @property
    def meta_spec(self):
        return self.__dict__


class _PythonProvider(object):
    def __init__(self, module, class_name):
        self.module = module
        self.module_obj = module
        self.class_name = class_name
        self.handler = None
        self.import_time = 0

    def resolve_handler(self, descriptor):
        imported = False
        if self.handler is None:
            module_name = self.module.split(".")[-1]
            self.module_obj = __import__(self.module, globals(), locals(),
                                         [module_name])
            imported = True
        elif os.environ.get(REST_ROUTINE_AUTO_RELOAD_KEY, "") == "TRUE":
            source_file = re.sub("py.$", "py", self.module_obj.__file__)
            if os.stat(source_file).st_mtime > self.import_time:
                reload(self.module_obj)
                imported = True
        if imported:
            self.import_time = time.time()
            self.handler = getattr(self.module_obj,
                                   self.class_name)(descriptor)
        return self.handler

    def __call__(self, descriptor, req):
        return self.resolve_handler(descriptor)(req)


class _ProtobufRpcProvider(object):
    def __init__(self, service, class_name):
        self.service = service
        self.class_name = class_name

    def __call__(self, descriptor, req):
        # XXX TODO(dtsai): implement protobuf rpc provider when supported
        raise Exception("Not implemented yet")


class _MockProviderImpl(object):
    def __init__(self, status, headers, body):
        self.status = status    # integer
        self.headers = headers  # array of 'header-name: value' strings
        self.body = body        # string

    def __call__(self, req):
        resp_headers = [("Content-Type", "application/json"),
                        ("Content-Length", str(len(self.body)))]
        if self.headers:
            headers = [h.split(': ', 1) for h in self.headers]
            resp_headers.extend(headers)
        return Response(self.body, self.status, resp_headers)

    def initialize_pre_start(self, config):
        pass

    def initialize_post_start(self, config):
        pass

    def authorized(self, req):
        return True


class _MockProvider(object):
    def __init__(self, status, headers, body):
        self.provider = _MockProviderImpl(status, headers, body)

    def resolve_handler(self, descriptor):
        return self.provider


def get_provider(self, type, **kwargs):
    """Return provider instance corresponding to the specified arguments.

    Raises:
        TypeError: An invalid type was provided.
    """
    #TODO(pjb): this should be abstracted out of the descriptor module
    if type == 'mock':
        # proper kwargs is enforced by schema
        return _MockProvider(**kwargs)
        #return _PythonProvider("descriptors.mock_provider", "MockProvider")
        #TODO: pass in the mock properties
    if type == 'local_python':
        # proper kwargs is enforced by schema
        return _PythonProvider(**kwargs)
    elif type == 'protobuf_rpc':
        return _ProtobufRpcProvider(**kwargs)
    else:
        # schema should prevent this
        raise TypeError("Unknown provider type '%s'" % type)


class RestRoutineDescriptor(Descriptor):
    """Descriptor specification of a rest routine.

    This class provides a class for representing rest routines defined
    in YAML Descriptor format.
    """

    yaml_tag = u'!RestRoutine'

    spec_schema = REST_ROUTINE_SCHEMA

    default_error_response = _RestResponse(
        (httplib.MOVED_PERMANENTLY, httplib.TEMPORARY_REDIRECT,
         httplib.BAD_REQUEST, httplib.FORBIDDEN,
         httplib.INTERNAL_SERVER_ERROR, httplib.SERVICE_UNAVAILABLE))

    @classmethod
    def from_raw_spec(cls, raw_spec):
        def _default_req_resp_fields(spec, is_response=False):
            d = spec.copy()
            if "headers_schema" not in d:
                d["headers_schema"] = DEFAULT_HEADERS_SCHEMA
            if (is_response and "content_type_schema" not in d and
                d.get("status") != httplib.NO_CONTENT):
                d["content_type_schema"] = DEFAULT_CONTENT_TYPE
            return d

        req = _RestRequest(**_default_req_resp_fields(raw_spec['request']))
        responses = [_RestResponse(**_default_req_resp_fields(r, True))
                     for r in raw_spec['response']]
        # Create _RestResponse for default_error_responses not in raw_spec
        spec_errors = []
        for r in raw_spec['response']:
            status = r["status"]
            if hasattr(status, '__iter__'):
                spec_errors.extend(status)
            else:
                spec_errors.append(status)
        errors_not_in_spec = [err for err in cls.default_error_response.status
                              if err not in spec_errors]
        if errors_not_in_spec:
            r = _default_req_resp_fields({"status": errors_not_in_spec}, True)
            responses.append(_RestResponse(**r))

        provider_type = raw_spec.get('provider', {}).get('type')
        if provider_type:
            provider = get_provider(type, **raw_spec['provider'])
        else:
            provider = None

        required_privileges = raw_spec.get('required_privileges', [])
        path_arguments = [PathArgument(**p)
                          for p in raw_spec.get('path_arguments', [])]

        return cls(raw_spec['id'], raw_spec['method'], raw_spec['path'],
                   raw_spec['help_summary'], raw_spec.get('description', ""),
                   raw_spec['doc_category'], req, responses, provider,
                   required_privileges, path_arguments,
                   raw_spec.get('cancelable', False),
                   raw_spec.get('persisted_task', False),
                   raw_spec.get('resumable_task', False),
                   raw_spec.get('experimental', False),
                   raw_spec.get('deprecated', False),
                   raw_spec.get('hidden', False),
                   raw_spec.get('snmp_oid'))

    def __init__(self, id, method, path, help_summary, description,
                 doc_category, request, responses, provider,
                 required_privileges, path_arguments, cancelable,
                 persisted_task, resumable_task, experimental,
                 deprecated, hidden, snmp_oid):
        self.id = id
        self.method = method
        self.path = path
        self.help_summary = help_summary
        self.description = description
        self.doc_category = doc_category

        self.request = request
        self.responses = responses
        self.response_by_code = {}
        for response in self.responses:
            for code in response.status:
                self.response_by_code[code] = response

        # If the descriptor provides responses for default error codes,
        # use the descriptor's version instead of the default.
        default_response = copy.copy(self.default_error_response)
        overrides = [code for code in self.default_error_response.status
                     if code in self.response_by_code]
        if overrides:
            default_response.status = [code for code in default_response.status
                                       if code not in overrides]
            olen = len(overrides)
            lg.debug("Descriptor %s provides custom response handler for "
                     "code%s %s, overriding default handler"
                     % (self.id, "" if olen == 1 else "s",
                        overrides[0] if olen == 1 else str(overrides)))
        if default_response.status:
            self.responses.append(default_response)
            for code in default_response.status:
                self.response_by_code[code] = default_response

        self.provider = provider
        self.required_privileges = required_privileges
        self.supported_versions = []
        self.module_min_version = None
        self.module_max_version = None
        self.call_count = 0
        self.time_spent = float(0)
        self.async_calls = 0

        self.path_arguments = path_arguments
        self._path_re = self._resolve_path_re()
        self.cancelable = cancelable
        self.resumable_task = resumable_task
        # Resumability implies persistability
        self.persisted_task = persisted_task | resumable_task
        self.experimental = experimental
        self.deprecated = deprecated
        self.hidden = hidden
        self.snmp_oid = snmp_oid

    def _resolve_path_re(self):
        pattern = "^%s$" % self.path
        for arg in self.path_arguments:
            assert pattern.find("<%s>" % arg.name) != -1, \
                "RestRoutineDescriptor path missing required path argument"
            # Regex group names have to be valid Python identifiers, since REST
            # and the control API uses dashes we substitute with underscores.
            # We'll have to account for the substitution when extracting the
            # groups from match objects
            _name = arg.name.replace("-", "_")
            arg_pattern = arg.pattern
            if arg_pattern.startswith("^"):
                arg_pattern = arg_pattern[1:]
            if arg_pattern.endswith("$"):
                arg_pattern = arg_pattern[:-1]
            pattern = pattern.replace("<%s>" % arg.name,
                                      "(?P<%s>%s)" % (_name, arg_pattern))
        return re.compile(pattern)

    @property
    def meta_spec(self):
        spec = {
            "id": self.id,
            "method": self.method,
            "path": self.path,
            "help_summary": self.help_summary,
            "description": self.description,
            "doc_category": self.doc_category,
            "required_privileges": self.required_privileges,
            "request": self.request.meta_spec,
            "response": [r.meta_spec for r in self.responses],
            "cancelable": self.cancelable,
            "persisted_task": self.persisted_task,
            "resumable_task": self.resumable_task,
            "experimental": self.experimental,
            "deprecated": self.deprecated,
            "hidden": self.hidden,
        }
        if self.snmp_oid is not None:
            spec["snmp_oid"] = self.snmp_oid
        return spec

    def resolve_and_authorize_provider(self, request, authorize):
        handler = self.provider.resolve_handler(self)
        if authorize and not handler.authorized(request):
            raise exc.HTTPForbidden(
                "You are not authorized to perform this operation.")
        return handler

    def call_provider(self, request, authorize):
        """Invoke provider with specified request.

        Args:
            request: A RestRoutineRequest instance wrapping the request
                environment.
            authorize: If True, perform per-request authorization check.

        Returns:
            A webob.Response containing the routine response, note that a
            HTTPBadRequest or HTTPInternalServerError can be returned if
            a badly formatted request or response is detected, respectively.
        """
        return
        try:
            request.path_args = self.get_path_args(request.rest_routine_path)
            self.validate_request(request)
            handler = self.resolve_and_authorize_provider(request, authorize)
            response = get_task_manager().start_task(handler, request, self)
            # If async request, stash _is_nvp_async_request = True field in
            # response so response validation can handle async reponse body
            if request.headers.get("X-Nvp-Async", "").lower() == "true":
                response._is_nvp_async_request = True
            try:
                self.validate_response(response)
            except Exception:
                # Ideally, providers return responses matching declared YML
                # schema; however, in case bugs exist and are not fixed before
                # release, validation errors are ignored based on the
                # configured IGNORE_RESPONSE_VALIDATION_ERRORS value.
                if not IGNORE_RESPONSE_VALIDATION_ERRORS:
                    raise
            return response
        except exc.HTTPException as response:
            return response
        except Exception:
            lg.error("Exception caught while trying to call provider: %s" %
                     traceback.format_exc())
            return exc.HTTPInternalServerError(
                "Error occurred while trying to process the request")

    def __unicode__(self):
        return u"%s(id=%s, method=%s, path=%s, help_summary=%s)" % (
            self.__class__.__name__, self.id, self.method,
            self.path, self.help_summary)

    def validate_request(self, request):
        """Validate that request conforms to this descriptor.

        Args:
            request: A webob.Request instance wrapping the request environment.

        Raises:
            HTTPBadRequest if the request headers, parameters, or body
            do not conform to the routine specification.
        """
        # Validate headers
        err = self._validate(request.headers, self._validate_request_headers,
                             "One or more request headers not valid: '%s'")
        # Validate Content-Type header
        if not err:
            err = self._validate(request, self._validate_content_type,
                                 "Request Content-Type not valid", False)
        # Validate parameters
        if not err:
            err = self._validate(request.query_string, self._validate_params,
                                 "One or more query strings not valid: '%s'")
        # Validate body
        if not err:
            err = self._validate(request, self._validate_body,
                                 "Request body not valid", False)
        if err:
            raise exc.HTTPBadRequest(err)

    def validate_response(self, response):
        """Validate that response conforms to this descriptor.

        Args:
            response: A webob.Response instance containing the routine
                response.

        Raises:
            HTTPInternalServerError if the response headers, body or
            status code do not conform to the routine specification.
        """
        # Validate status
        err = self._validate(response, self._validate_status,
                             "Invalid status code in response", False)
        # Validate headers
        if not err:
            err = self._validate(response, self._validate_response_headers,
                                 "Invalid headers in response", False)
        # Validate Content-Type header
        if not err:
            err = self._validate(response, self._validate_content_type,
                                 "Content-Type not valid", False)
        # Validate body
        if not err:
            err = self._validate(response, self._validate_body,
                                 "Invalid body in response", False)
        if err:
            raise exc.HTTPInternalServerError(err)

    def match_path(self, path):
        """Determine if specified path matches RestRoutine's path.

        Args:
            path: Path to match.

        Returns:
            True if specified path matches RestRoutine's path.
            False if not.
        """
        m = self._path_re.match(path)
        return bool(m)

    def get_path_args(self, path):
        """Returns a parsed path_args dict from path.

        Args:
            path: Path to parse.

        Returns:
            parsed path_args dict.
        """
        result = {}
        m = self._path_re.match(path)
        if m:
            for arg in self.path_arguments:
                group_name = arg.name.replace("-", "_")
                result[arg.name] = m.group(group_name)
        return result

    def _validate(self, obj, validate_method, err_msg, add_obj_in_err_msg=True):
        """Helper function to validate request/response objects.

        Args:
            obj: Request/response object to validate.
            validate_method: Validation method to invoke.
            err_msg: Error message to return if validation fails.
            add_obj_in_err_msg: True if err_msg contains a %s to be replaced
                by str(obj).

        Returns:
            None, if validation is successful; otherwise, an error message.
        """
        error_text = None
        valid, error_details = validate_method(obj)
        if not valid:
            error_summ = err_msg % str(obj) if add_obj_in_err_msg else err_msg
            error_text = "%s - %s" % (error_summ, error_details)
            lg.debug(error_text)
        return error_text

    def _validate_object(self, obj_dict, schema):
        """Validate object dictionary against specified schema.

        Args:
            obj_dict: Object to validate, specified as python dictionary.
            schema: Schema to validate against.

        Returns:
            (True, "Success") if header validation succeeded; otherwise,
            (False, error message).

        Raises:
            webob.exc.HTTPInternalServerError if specified schema is a $ref
            that has not been declared.
        """
        if "$ref" not in schema:
            js = JsonSchema(schema, strict=True,
                            schema_registry=SCHEMA_REGISTRY)
            return js.validate(obj_dict)
        ref = schema.get("$ref")
        t = self.descriptor_factory.get_type(ref)
        if t:
            return t.validate(obj_dict)
        lg.error("Routine descriptor '%s' declared unknown schema: '%s'" %
                 (self.id, ref))
        raise exc.HTTPInternalServerError("Error validating request/response")

    def _validate_request_headers(self, headers):
        """Validate request or response headers.

        Args:
            headers: A webob dictionary-like object returned by
                webob.Request.headers.

        Returns:
            (True, "Success") if header validation succeeded; otherwise,
            (False, error message).

        Note:
            The Content-Type header is validated separately by
            self._validate_content_type.
        """
        if not self.request.headers_schema:
            if headers:
                return False, ("Request does not allow any headers, request "
                               "specified: %s" % headers)
            else:
                return True, "Success"
        return self._validate_object(dict(headers), self.request.headers_schema)

    def _validate_response_headers(self, response):
        """Validate request or response headers.

        Args:
            response: A webob response.

        Returns:
            (True, "Success") if header validation succeeded; otherwise,
            (False, error message).

        Note:
            The Content-Type header is validated separately by
            self._validate_content_type.
        """
        found, schema = self._get_response_attr(response, "headers_schema")
        if not found:
            return False, ("Response returned an invalid status: %s" %
                           response.status_int)
        elif not schema:  # It's possible to specify headers_schema: null
            if response.headers:
                return False, ("Request does not allow any headers, response "
                               "specified: %s" % str(response.headers))
            else:
                return True, "Success"
        header_dict = {}
        for header, value in response.headers.iteritems():
            if header not in header_dict:
                header_dict[header] = value
            elif type(header_dict[header]) == types.ListType:
                header_dict[header].append(value)
            else:
                header_dict[header] = [header_dict[header], value]
        return self._validate_object(header_dict, schema)

    def _validate_content_type(self, req_or_res):
        """Validate request or response Content-Type header.

        The Content-Type is only checked for responses that have
        status code < 400 (i.e. non-errors).

        Args:
            req_or_res: A webob request or response object

        Returns:
            (True, "Success") if request/response Content-Type validation
            succeeded; otherwise, (False, error message).

        Raises:
            webob.exc.HTTPInternalServerError if specified req_or_res object
                is not valid or descriptor content_type_schema is not valid.
        """
        # Determine content_type schema from request/response schema
        schema = None
        if isinstance(req_or_res, Request):
            schema = self.request.content_type_schema
        elif isinstance(req_or_res, Response):
            if req_or_res.status_int >= httplib.BAD_REQUEST:
                return True, "Success"
            found, schema = self._get_response_attr(req_or_res,
                                                    "content_type_schema")
            if not found:
                return False, ("Response returned an invalid status: %s" %
                               req_or_res.status_int)
        else:
            raise exc.HTTPInternalServerError("Invalid request or response")
        # Extract type/subtype portion of the Content-Type
        # TODO(dtsai): For now validation of Content-Type parameters (e.g.
        # charset=UTF8) is unsupported.  Currently no NAPI providers model
        # parameters in its content_type_schema declaration.
        content_type = req_or_res.headers.get("Content-Type", "")
        type_subtype = content_type.split(";")[0]
        # Validate request/response content-type value against schema
        if not schema:
            if type_subtype:
                return False, ("Unexpected Content-Type header specified: %s" %
                               type_subtype)
            else:
                return True, "Success"
        elif "pattern" in schema:
            if re.match(schema["pattern"], type_subtype):
                return True, "Success"
            else:
                return False, ("Invalid Content-Type type/subtype detected: %s"
                               % type_subtype)
        else:
            return self._validate_object(type_subtype, schema)

    def _validate_params(self, query_string):
        """Validate request query_string.

        Args:
            query_string: Request query string, e.g. field1=value1&field2=value2

        Returns:
            (True, "Success") if query string validation succeeded; otherwise,
            (False, error message).
        """
        if not self.request.parameters_schema:
            if query_string:
                return False, ("Request does not allow parameters, "
                               "request specified: %s" % query_string)
            else:
                return True, "Success"
        params = {}
        for key, value in urlparse.parse_qsl(query_string):
            if key not in params:
                params[key] = value
            elif type(params[key]) == types.ListType:
                params[key].append(value)
            else:
                params[key] = [params[key], value]
        # Convert request param values to correct type as specified by schema
        param_schema = self.request.parameters_schema
        result, error_text = self._type_request_params(params, param_schema)
        if not result:
            return False, error_text
        return self._validate_object(params, self.request.parameters_schema)

    def _validate_body(self, req_or_res):
        """Validate request or response body.

        Perform request or response body validation if Content-Type is
        application/json; otherwise, return a successful result.  Also, if a
        response is an error response (i.e. status code >= 400), no validation
        is performed and a successful result is returned.

        Args:
            req_or_res: A webob request or response object.

        Returns:
            (True, "Success") if request/response body validation succeeded;
            otherwise, (False, error message).

        Raises:
            webob.exc.HTTPInternalServerError if specified req_or_res object
                is not valid.
            ValueError if req_or_resp.body is not valid json.
        """
        # Non-application/json Content-Types are by definition valid
        # (note that Content-Type can have parameters delimited by ";")
        content_type = req_or_res.headers.get("Content-Type", "")
        if content_type.split(";")[0] != "application/json":
            return True, "Success"
        elif isinstance(req_or_res, Response) and req_or_res.status_int >= 400:
            return True, "Success"
        # Determine the applicable body_type_id for the specified req/resp
        body_type_id = None
        if isinstance(req_or_res, Request):
            body_type_id = self.request.body_type_id
        elif isinstance(req_or_res, Response):
            found, body_type_id = self._get_response_attr(req_or_res,
                                                          "body_type_id")
            if not found:
                return False, ("Response returned an invalid status: %s" %
                               req_or_res.status_int)
        else:
            raise exc.HTTPInternalServerError("Invalid request or response")
        # Validate body_dict against body_type_id schema
        body_dict = simplejson.loads(req_or_res.body)
        if not body_type_id:
            if body_dict:
                # Probably doesn't make sense to log body content,
                # it may be too big, sensitive, etc.
                return False, "Request does not allow body content"
            else:
                return True, "Success"
        return self._validate_object(body_dict, {"$ref": body_type_id})

    def _validate_status(self, response):
        """Validate response status code.

        Args:
            response: A webob response object.

        Returns:
            (True, "Success") if status code validation succeeded; otherwise,
            (False, error message).
        """
        # If request was an async operation, the task_manager
        # returns an accepted status
        if (hasattr(response, "_is_nvp_async_request") and
            response.status_int == httplib.ACCEPTED):
            return True, "Success"
        for resp in self.responses:
            if response.status_int in resp.status:
                return True, "Success"
        return False, "Invalid status: %s" % response.status_int

    def _get_response_attr(self, response, attr_name):
        """Get descriptor response attribute value for specified response.

        Given a response object with a status_int value, determine which of
        the descriptor responses match and return the corresponding descriptor
        response attribute value.

        Args:
            response: A webob response object.
            attr_name: Name of response attribute to return.

        Returns:
            (True, attribute value) if specified response is defined by
            this descriptor; otherwise, (False, None).
        """
        # Override attribute values for responses to async requests as
        # defined by the task_manager (instead of the descriptor yml).
        if hasattr(response, "_is_nvp_async_request"):
            if attr_name == "body_type_id":
                return True, "TaskProperties"
            elif attr_name == "content_type_schema":
                return True, DEFAULT_CONTENT_TYPE
            elif attr_name == "headers_schema":
                return True, DEFAULT_HEADERS_SCHEMA
        res = self.response_by_code.get(response.status_int)
        return (True, getattr(res, attr_name)) if res else (False, None)

    def _type_request_params(self, params, schema):
        """Convert request parameters to type as specified by parameter schema.

        Args:
            params: Object to validate, specified as python dictionary.
            schema: Schema to validate against.

        Returns:
            (True, "Success") if request parameter (if any) type conversion
            succeeded; otherwise, (False, error message).

        Raises:
            webob.exc.HTTPInternalServerError if invalid parameter schema.
        """
        if not params:
            return True, "Success"
        error_text = "Invalid request parameter definition"
        if not isinstance(schema, types.DictType) or "$ref" not in schema:
            lg.error("%s, schema: %s" % (error_text, schema))
            raise exc.HTTPInternalServerError(error_text)
        type_id = schema["$ref"]
        type_descriptor = self.descriptor_factory.get_type(type_id)
        if not type_descriptor:
            lg.error("%s, unknown type descriptor: %s" %
                     (error_text, type_id))
            raise exc.HTTPInternalServerError(error_text)
        type_schema = type_descriptor.raw_schema
        property_dicts = []
        if isinstance(type_schema, types.DictType):
            if "properties" in type_schema:
                property_dicts.append(type_schema.get("properties", {}))
            elif ("type" in type_schema and
                  isinstance(type_schema["type"], types.ListType)):
                for typ in type_schema["type"]:
                    if isinstance(typ, types.DictType) and "properties" in typ:
                        property_dicts.append(typ.get("properties", {}))
                    else:
                        # Invalid parameter type defined, request parameters
                        # cannot be unions of simple types, each parameter
                        # must be named
                        lg.debug("Invalid request parameter schema, union "
                                 "types must contain named properties: %s" %
                                 type_schema)
        if not property_dicts:
            lg.error("Invalid type_schema: %s" % type_schema)
            raise exc.HTTPInternalServerError(error_text)
        for prop in property_dicts:
            params_valid = True
            for param_name, param_schema in prop.iteritems():
                result, _ = self.__type_param(params, param_name, param_schema)
                if not result:
                    params_valid = False
                    break
            if params_valid:
                return True, "Success"
        return False, error_text

    def __type_param(self, params, param_name, param_schema):
        error_text = "Invalid request parameter definition"
        if param_name not in params:
            return True, "Success"
        elif "type" in param_schema:
            param_type = param_schema["type"]
            try:
                if param_type == "string":
                    pass
                elif param_type == "number":
                    params[param_name] = float(params[param_name])
                elif param_type == "integer":
                    params[param_name] = int(params[param_name])
                elif param_type == "boolean":
                    if params[param_name].lower() not in ["true", "false"]:
                        raise ValueError()
                    params[param_name] = params[param_name].lower() == "true"
                else:
                    lg.error("%s, type %s not supported" %
                             (error_text, param_type))
                    return False, error_text
                return True, "Success"
            except ValueError:
                return False, ("Request parameter %s=%s is invalid" %
                               (param_name, params[param_name]))
        elif "$ref" in param_schema:
            type_id = param_schema["$ref"]
            type_descriptor = self.descriptor_factory.get_type(type_id)
            if not type_descriptor:
                lg.error("%s, unknown type descriptor: %s" %
                         (error_text, type_id))
                raise exc.HTTPInternalServerError(error_text)
            type_schema = type_descriptor.raw_schema
            return self.__type_param(params, param_name, type_schema)
        return False, "%s, schema: %s" % (error_text, param_schema)
