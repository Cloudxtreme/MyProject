import base64
from datetime import datetime
import copy
import error
import importlib
import inspect
import json
import vmware.common.global_config as global_config
import tasks
import pylib
import result
from state import StateSchema
import traceback
import eventlet
from urllib import urlencode
import os

class BaseClient(object):
    """ Class to provide attributes and method for client operations (CRUD)"""

    def __init__(self):
        """ Constructor to create an object of BaseClient"""

        self.version = '3.0'
        self.log = global_config.pylogger
        self.connection = None
        self.endpoint = None
        self.create_endpoint = None
        self.read_endpoint = None
        self.delete_endpoint = None
        self.state_endpoint = None
        self.query_endpoint = None
        self.id = None
        self.content_type = "application/json"
        self.accept_type = "application/json"
        self.response = None
        self.schema_class = None
        self.update_as_post = None
        self.create_as_put = False

    def set_create_endpoint(self, end_point):
        """ Setter for URL required to create a managed object

        @param end_point URL part to be used during firing POST call
        """
        self.create_endpoint = end_point
        self.set_read_endpoint(self.create_endpoint)
        self.set_delete_endpoint(self.create_endpoint)
        self.set_query_endpoint(self.create_endpoint)

    def get_create_endpoint(self):
        """ Get method for create_endpoint """
        return self.create_endpoint

    def set_read_endpoint(self, end_point):
        """ Setter for URL required to read a managed object

        @param end_point URL part to be used during firing GET call
        """
        self.read_endpoint = end_point

    def set_delete_endpoint(self, end_point):
        """ Setter for URL required to delete a managed object

        @param end_point URL part to be used during firing DELETE call
        """
        self.delete_endpoint = end_point

    def set_state_endpoint(self, end_point):
        """ Setter for URL required to retrieve state

        @param end_point URL part to be used during firing state call
        """
        self.state_endpoint = end_point

    def set_query_endpoint(self, end_point):
        """ Setter for URL required to retrieve all objects for an endpoint

        @param end_point URL part used to get all objects for an endpoint
        """
        self.query_endpoint = end_point

    def set_content_type(self, content_type):
        """ Setter for specifying content type while firing all REST calls

        @param content_type eg. application/xml, application/json, plain/text
        """
        self.content_type = content_type

    def set_accept_type(self, accept_type):
        """ Setter for specifying accept type while firing all REST calls

        @param accept_type eg. application/xml, application/json, plain/text
        """
        self.accept_type = accept_type

    def get_content_type(self):
        """ Getter for content type used while firing all REST calls
        """
        return self.content_type

    def get_accept_type(self):
        """ Getter for accept type used while firing all REST calls
        """
        return self.accept_type

    def set_id(self, managed_object_id):
        self.id = managed_object_id

    @tasks.thread_decorate
    def create(self, schema_object=None, url_parameters=None):
        """ Client method to perform create operation

        @param schema_object instance of BaseSchema class
        @return result object
        """

        self.log.debug("In create base_client...")
        if self.create_as_put:
               self.log.error('This is workaround, File a PR, '+
                  'create should not be a PUT call')
               self.response = self.request('PUT',
                                            self.create_endpoint,
                                            schema_object.get_data(self.content_type),
                                            url_parameters=url_parameters)
        else:
            if schema_object is not None:
                self.response = self.request('POST',
                                             self.create_endpoint,
                                             schema_object.get_data(self.content_type),
                                             url_parameters=url_parameters)
            else:
                self.response = self.request('POST',
                                             self.create_endpoint,
                                             url_parameters=url_parameters)

        result_obj = result.Result()
        self.set_result(self.response, result_obj)
        return result_obj

    def create_using_put(self, py_dict=None, url_parameters=None):
        """ Method to create sub component using PUT call
        @param py_dict dictionary object which contains schema attributes to be
        updated
        @return result_obj
        """

        self.log.debug("update input %s" % py_dict)
        schema_object = self.get_schema_object(py_dict)

        self.response = self.request('PUT',
                                     self.create_endpoint,
                                     schema_object.get_data(self.content_type),
                                     url_parameters=url_parameters)

        result_obj = result.Result()
        self.set_result(self.response, result_obj)
        return result_obj

    def update_with_override_merge(self, py_dict):
        return self.update(py_dict, True)

    def update(self, py_dict, override_merge=False, url_parameters=None):
        """ Client method to perform update operation

        @param py_dict dictionary object which contains schema attributes to be
        updated
        @param override_merge
        @return status http response status
        """
        self.log.debug("update input = %s" % py_dict)
        update_object = self.get_schema_object(py_dict)
        schema_object = None

        if override_merge is False:
            schema_object = self.read()
            self.log.debug("schema_object after read:")
            schema_object.print_object()
            self.log.debug("schema_object from input:")
            update_object.print_object()
            try:
                self.merge_objects(schema_object, update_object)
            except:
                tb = traceback.format_exc()
                self.log.debug("tb %s" % tb)
        else:
            schema_object = update_object

        self.log.debug("schema object after merge:")
        schema_object.print_object()

        if self.update_as_post:
                self.response = self.request('POST', self.create_endpoint,
                                             schema_object.get_data(self.content_type),
                                             url_parameters=url_parameters)
        else:
            if self.id is None:
                self.response = self.request('PUT', self.read_endpoint,
                                             schema_object.get_data(self.content_type),
                                             url_parameters=url_parameters)
            else:
                self.response = self.request('PUT',
                                             self.read_endpoint + "/" + str(self.id),
                                             schema_object.get_data(self.content_type),
                                             url_parameters=url_parameters)
        result_obj = result.Result()
        self.set_result(self.response, result_obj)

        return result_obj

    def merge_objects(self, base_object, update_object):
        """ Method to merge given two schema objects

        @param base_object   Base object which needs to be updated
        @param update_object Reference to result object which contains
        updated information
        """

        for attribute in update_object.__dict__:
            if (attribute[0] != "_" or attribute.startswith('_tag_')) and update_object.__dict__[attribute] is not None:
                if type(update_object.__dict__[attribute]) in [bool, int, str, unicode]:
                    if update_object.__dict__[attribute] is not None:
                        base_object.__dict__[attribute] = update_object.__dict__[attribute]
                else:
                    if type(update_object.__dict__[attribute]) in [list]:
                        index = 0
                        # If new object do not have any items in the list
                        if len(update_object.__dict__[attribute]):
                            for element in update_object.__dict__[attribute]:
                                if element is not None:
                                    try:
                                        if type(element) in [str, bool, int, unicode]:
                                            base_object.__dict__[attribute][index] = element
                                        else:
                                            self.merge_objects(base_object.__dict__[attribute][index], element)
                                    # If new object has more elements that currently configured object
                                    except IndexError:
                                        base_object.__dict__[attribute].append(element)
                                index += 1
                                # If there are excess elements in already configured object - delete them
                            for i in range(index, len(base_object.__dict__[attribute])):
                                del base_object.__dict__[attribute][i]
                        else:
                            del base_object.__dict__[attribute][:]
                    else:
                        if type(base_object.__dict__[attribute]) not in [file, dict]:
                            self.merge_objects(base_object.__dict__[attribute], update_object.__dict__[attribute])

    def query(self, url_parameters=None):
        """ Method to perform GET operation """


        self.response = self.request('GET',
                                     self.read_endpoint,
                                     url_parameters=url_parameters)
        self.log.debug(self.response.status)
        # read() seems to be one time call, i.e once called
        # next call will return None
        response = self.response.read()
        return response

    def get_state(self, url_parameters=None):
        """ Method to perform get operation on 'state' for all endpoints in neutron"""

        self.response = self.request('GET',
                                     self.state_endpoint % self.id,
                                     "",
                                     url_parameters=url_parameters)
        self.log.debug(self.response.status)
        response = self.response.read()
        state_schema = StateSchema()
        state_schema.set_data(response, self.accept_type)
        return state_schema

    def base_query(self, url_parameters=None):
        """ Client method to perform query operation """

        self.response = self.request('GET',
                                     self.query_endpoint,
                                     "",
                                     url_parameters=url_parameters)
        self.log.debug(self.response.status)
        payload_schema = self.response.read()
        return payload_schema

    def read(self, url_parameters=None):
        """ Client method to perform READ operation """
        schema_object = self.get_schema_object()
        #Check for value of self.id as not None and not an empty string
        if self.id is not None and self.id:
            self.response = self.request('GET', self.read_endpoint + "/"
                                        + str(self.id), "", url_parameters)

        else:
            self.response = self.request('GET', self.read_endpoint, "",
                                         url_parameters=url_parameters)
        self.log.debug(self.response.status)
        payload_schema = self.response.read()
        if payload_schema != None and payload_schema != "":
            schema_object.set_data(payload_schema, self.accept_type)
        else:
            return None
        return schema_object

    def get_response_dict(self):
        return self.read().__dict__

    def set_result(self, response, result_obj):
        result_obj.set_status_code(response.status)
        result_obj.set_response(response)
        response_data = response.read()

        if response.status == int(400) or \
                response.status == int(401) or \
                response.status == int(403) or \
                response.status == int(404) or \
                response.status == int(405) or \
                response.status == int(500):
            self.log.error(response.reason)
            self.log.error('Create Failed: Details: %s', result_obj.error)
            self.log.error('Create Failed: ErrorCode: %s',
                           result_obj.status_code)
            result_obj.set_error(response_data, response.reason)

        self.log.debug(response_data)
        result_obj.set_response_data(response_data)

    @tasks.thread_decorate
    def delete(self, schema_object=None, url_parameters=None):
        """ Client method to perform DELETE operation """

        #TODO: Is catching ResponseNotReady exception right thing to do
        self.log.debug("delete_endpoint is %s " % self.delete_endpoint)
        self.log.debug("endpoint id is %s " % self.id)
        self.log.debug("schema_object to delete call is %s " % schema_object)
        end_point_uri = None
        if self.id is None or len(str(self.id)) == 0:
            end_point_uri = self.delete_endpoint
        else:
            end_point_uri = self.delete_endpoint + '/' + str(self.id)

        if schema_object is None:
            self.response = self.request('DELETE', end_point_uri,
                                         "", url_parameters=url_parameters)
        else:
            self.response = self.request('DELETE', end_point_uri,
                                         schema_object.get_data(self.content_type),
                                         url_parameters=url_parameters)
        result_obj = result.Result()
        self.set_result(self.response, result_obj)
        return result_obj

    def get(self, url_parameters=None):
        """ Method to perform a "GET" request on endpoint and
        return result object """
        if self.id is not None:
            self.response = self.request('GET',
                                         self.read_endpoint + "/" + self.id,
                                         "",
                                         url_parameters=url_parameters)
        else:
            self.response = self.request('GET', self.read_endpoint,
                                         "",url_parameters=url_parameters)
        self.log.debug(self.response.status)
        result_object = result.Result()
        self.set_result(self.response,result_object)
        return result_object

    def set_connection(self, connection):
        self.connection = connection

    def get_connection(self):
        return self.connection

    def request(self, method, endpoint, payload="", url_parameters=None):
        """ Method to make request call on connection already established

        @rtype : HTTP response object
        @param method   method name
        @param endpoint http or https url
        @param payload  request payload
        @return http response object
        """
        auth = base64.urlsafe_b64encode(self.connection.username + ":" + self.connection.password).decode("ascii")

        headers = {}
        headers['Authorization'] = 'Basic %s' % auth
        headers['content-type'] = self.content_type
        headers['Accept'] = self.accept_type

        # If-Match header required for PUT and DELETE operations on DFW
        if 'if_match' in dir(self) and method in ['PUT', 'DELETE', 'POST']:
            if self.if_match:
                headers['If-Match'] = self.if_match

        self.log.debug("method %s" % method)
        url_params = ""
        if url_parameters:
            url_params = "?%s" % urlencode(url_parameters)
        # Adding a check here for payload type as payload can be binary in
        # certain cases.
        if type(payload) is 'str':
            if len(payload) < 10000:
                self.log.debug("payload %s" % payload)

        self.connection.anchor = self.connection.createConnection()
        request = '/%s/%s%s' % (self.connection.api_header,
                                endpoint,
                                url_params)
        self.log.debug("Request Endpoint %s" % (request))
        self.response = self.connection.request(method,
                                                request,
                                                payload,
                                                headers)

        return self.response

    def get_schema_object(self, py_dict=None):
        """ Method to create schema object from python dictionary

        @param py_dict python dictionary which needs to be converted
        """

        module, class_name = self.schema_class.split(".")
        some_module = importlib.import_module(module)
        loaded_schema_class = getattr(some_module, class_name)
        # creating an instance of schema class
        schema_object = loaded_schema_class(py_dict)
        return schema_object

    def check_on_subcomponents(self, py_dict):
        """ Abstract method for checking values on registered subcomponents
            Has to be implemented in end point files
        """
        return 'SUCCESS'

    def set_schema_class(self, schema):
        """ set a schema class to specify the detailed data structure
            @param schema E.g. horizontal schema class
        """
        self.schema_class = schema

def bulk_create(template_obj, py_dict_array):
    """ Function to bulk create components

    @param py_dict_array reference to array of python dictionary which contains \
    spec needed to create schema object
    """
    time_start = datetime.now()
    pool = eventlet.GreenPool(30)
    options = {}
    result_array = []

    for py_dict in py_dict_array:
        options['py_dict'] = py_dict
        options['template_obj'] = template_obj
        options['result_array'] = result_array
        template_obj.log.debug("py_dict = %s" % py_dict)
        if ('VDNET_PYLIB_THREADS' not in os.environ.keys()):
            schema_object = template_obj.get_schema_object(py_dict)
            result_obj = result.Result()
            result_obj = template_obj.create(schema_object)
            result_array.append(result_obj)
        else:
            pool.spawn(create_with_threads, options)
        if pool.running():
            pool.waitall()
    time_end = datetime.now()
    total_time = time_end - time_start
    template_obj.log.debug("Attempt to create %s components " % len(py_dict_array))
    template_obj.log.debug("Time taken to create components %s " % total_time.seconds)
    return result_array

def create_with_threads(options):
    template_obj = options['template_obj']
    py_dict = options['py_dict']
    result_array = options['result_array']
    schema_object = template_obj.get_schema_object(py_dict)
    result_obj = result.Result()
    template_obj.log.debug("Running create call with threads...")
    result_obj = template_obj.create(schema_object)
    # No need to do mutex/semaphore for shared memory for greenlets
    # http://learn-gevent-socketio.readthedocs.org/en/latest/greenlets.html
    result_array.append(result_obj)

def bulk_update(update_array):
    """ Function to bulk update components

    @param py_dict_array reference to array of python dictionary which contains \
    spec as well as client objects
    """
    result_array = []
    for update_hash in update_array:
        update_object = update_hash["obj"]
        update_spec = update_hash["spec"]
        update_object.log.debug("py_dict (update spec)  = %s" % update_spec)
        update_object.log.debug("update object id  = %s" % update_object.id)
        update_object.log.debug("update object type  = %s" % str(type(update_object)))
        result_obj = result.Result()
        update_object.log.debug("------------------------------------------------")
        result_obj = update_object.update(update_spec)
        result_array.append(result_obj)
    return result_array

def bulk_api_verify(template_obj, py_dict_array, metadata_array, result_obj_array):
    template_obj.log.debug("py_dict_array: " + str(py_dict_array))
    template_obj.log.debug("metadata_array: " + str(metadata_array))
    template_obj.log.debug("result_obj_array:" + str(result_obj_array))

    final_result_array = []
    template_obj.log.debug("Verifying configured object ...")
    if metadata_array is None:
        template_obj.log.debug("Metadata not provided skipping entire object verification ...")
        template_obj.log.debug("Verifying return codes only")
        for result_obj in result_obj_array:
            if str(result_obj.status_code)[0] == "2":
                final_result_array.append('SUCCESS')
            else:
                final_result_array.append('FAILURE')
        return final_result_array
    for py_dict, metadata, result_obj in zip(py_dict_array, metadata_array, result_obj_array):
        # If the operation [create/update] result code does not match expected value
        # mark it as failed
        template_obj.log.debug("------------------------------------------------")
        if str(result_obj.status_code) != str(metadata['expectedresultcode']):
                template_obj.log.debug(
                    "result_obj.status_code %s not matching expectedresultcode %s" \
                    % (result_obj.status_code, str(metadata['expectedresultcode'])))
                final_result_array.append('FAILURE')
        # if the operation was successful check for configured object
        elif str(result_obj.status_code)[0] == "2":
            verify_object = template_obj.get_schema_object(py_dict)
            configured_object = template_obj.get_schema_object()

            if result_obj.get_is_result_object() is True:
                configured_object.set_data(result_obj.get_response_data(), template_obj.accept_type)
            else:
                template_obj.log.debug("result_obj payload:" + str(result_obj.get_response_data()))
                template_obj.log.debug("Object Id:" + str(template_obj.id))
                configured_object = template_obj.read()
                configured_object.print_object()
                template_obj.log.debug("------------------------------------------------")
                verify_object.print_object()

            if verify_object.verify(configured_object):
                final_result_array.append('SUCCESS')
                template_obj.log.debug("Object Verification Succeeded")
            else:
                final_result_array.append('FAILURE')
                template_obj.log.debug("Object Verification Failed")
        else:
            # This condition is when result code is matching expected
            # and result code is not success
            final_result_array.append('SUCCESS')
    return final_result_array


def get_objs_from_state_schema(inv_obj_array, template_obj_array, state_schema):

    """ Function to populate dummy python object with information obtained
        from state api call

    @param inv_obj_array reference to array of inventory objs where backing
     components should get realized

    @param template_obj_array reference to array of dummy objects of the type
     of backing components

    @param state_schema schema object containing information from state API

    """

    obj_array = []
    detail_array = state_schema.details
    template_obj = template_obj_array[0]
    inv_obj = inv_obj_array[0]
    if state_schema.state != "success":
        return "FAILURE"
    for detail in detail_array:

        if detail.state != "success":
            return "FAILURE"

        # getting the right inventory and template objects
        index = 0
        for obj in inv_obj_array:
            if obj.get_connection().ip == detail.sub_system_address:
                inv_obj = obj
                template_obj = template_obj_array[index]
            index = index + 1

        # getting full endpoint path from state call
        # e.g. /api/2.0/vdn/scopes/vdnscope-3
        full_id = detail.sub_system_id
        slash_index = full_id.rfind("/")

        # extracting the endpoint without the id
        # e.g. /api/2.0/vdn/scopes
        path = full_id[:slash_index]

        # extracting just the id
        # e.g. vdnscope-3
        id = full_id[slash_index+1:]

        # getting the connection object from the incoming inventory object
        # this is essential as it contains ip and auth info
        conn  = inv_obj.get_connection()

        # removing the api header from from the path
        # e.g. /vdn/scopes
        path = path.replace(conn.api_header, "")

        # setting the endpoints, id and conn object for the realized object
        template_obj.set_create_endpoint(path)
        template_obj.id = id
        template_obj.set_connection(conn)
        obj_array.append(template_obj)

    return obj_array

def bulk_get_state(inv_obj_array, template_obj_array, obj_array):

    """ Function to bulk get backing components

    @param inv_obj_array reference to array of inventory objs where backing
     components should get realized

    @param template_obj_array reference to array of dummy objects of the type
     of backing components

    @param obj_array reference to array of test objects whose state api is to
     be queried for backing object information

    """

    realized_objs_array = []
    for obj in obj_array:
        state_schema = obj.get_state()
        obj.log.debug("realized state %s" % str(state_schema.get_data(obj.content_type)))
        objs_array = get_objs_from_state_schema(inv_obj_array, template_obj_array, state_schema)
        if objs_array == "FAILURE":
            return "FAILURE"
        for obj_inst in objs_array:
            realized_objs_array.append(obj_inst)
    return realized_objs_array

