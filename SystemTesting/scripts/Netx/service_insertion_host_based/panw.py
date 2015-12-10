#!/usr/bin/python

# Standard imports.
import base64
from collections import namedtuple
import ConfigParser
import gevent
from gevent import httplib, pywsgi, select
import logging
import socket
import sys
import time
import paramiko
import re
# ######################################################################
# Globals
# ######################################################################

LOG = logging.getLogger(__name__)

# Poor man's enum factory.
def enum(*keys):
    return namedtuple('Enum', keys)(*keys)

# State tracking enum.
RunState = enum(
    'IDLE',

    'VSM_CREATE_SERVICE_MANAGER',
    'VSM_GET_SERVICE_MANAGER',
    'VSM_UPDATE_SERVICE_MANAGER_STATUS',
    'VSM_DELETE_SERVICE_MANAGER',

    'VSM_CREATE_SERVICE',
    'VSM_GET_SERVICE',
    'VSM_UPDATE_SERVICE_STATUS',
    'VSM_DELETE_SERVICE',

    'VSM_CREATE_VENDOR_TEMPLATE',
    'VSM_GET_VENDOR_TEMPLATE',
    'VSM_DELETE_VENDOR_TEMPLATE',

    'VSM_CREATE_SERVICE_PROFILE',
    'VSM_GET_SERVICE_PROFILE',
    'VSM_DELETE_SERVICE_PROFILE',
    'VSM_CREATE_DEPLOYMENTSPEC',
    'VSM_GET_SERVICE_DEPLOYMENTSPEC',
    'VSM_SET_DEPLOYMENT_SCOPE',
    'VSM_SERVICE_INSTALL',
    'VSM_SERVICE_UNINSTALL',
    'VSM_SERVICE_DISABLE',
    'VSM_SERVICE_SETUP',
    'VSM_SERVICE_CLEANUP',
    'VSM_ADD_RULE',
    'VSM_UPDATE_SERVICE_PROFILE_STATUS',
    'VSM_UPDATE_SERVICE_PROFILE_BINDING',

    'VSM_USER_INTERFACE_DEMO',
    'VSM_CREATION_COMPLETE',
     
    'VSM_CREATE_SERVICE_INSTANCE_TEMPLATE',
    'VSM_DEPLOY_SERVICE',
    'VSM_DELETE_SERVICE_INSTANCE',
    'VSM_DELETE_CLUSTER'

) # keep adding relevant states here

# HTTP verbs.
HttpVerb = enum(
    'GET',
    'POST',
    'PUT',
    'DELETE')

# ######################################################################
# Functions
# ######################################################################

# Implements the vSM callback handler.
def callback_response_handle(env, start_response):
    global g_state

    # Get the content of the current request.
    content = env['wsgi.input'].read()

    logging.info('State: %s. Content: %s', g_state, content)

    # Get the URI corresponding to the request
    uri = env['PATH_INFO']
    verb = env['REQUEST_METHOD']

    # Based on the request URI and/or state do the right validations.
    if uri == '/':
        start_response('200 OK', [('Content-Type', 'text/html')])
        return ["<h1>ECM Service Endpoint dummy (HTTP/SSL)</h1><h3>Proudly serving vShield Manager HTTP/REST callbacks...</h3>"]

    elif uri == '/vmware/2.0/si/serviceprofile/':

        # Respond to the vSM endpoint.
        start_response('200 OK', [('Content-Type', 'application/xml')])
        return ['<?xml version="1.0" encoding="UTF-8"?><serviceProfileResponse><message>OK</message></serviceProfileResponse>']

    elif verb == 'DELETE':
        start_response('200 OK', [('Content-Type', 'application/xml')])
        return ['<?xml version="1.0" encoding="UTF-8"?><serviceProfileResponse><message>OK</message></serviceProfileResponse>']

    else:
        start_response('404 Not Found', [('Content-Type', 'text/html')])
        return ['<h1>Not Found</h1>']

# Gets the local IP address for the communication with the remote VMware/vSM host.
def get_local_ipaddress(remoteHost):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect((remoteHost, 0))
    ip = s.getsockname()[0]
    s.close()
    return ip

# Gets the local REST URL, for the VMware/vSM (remoteHost) to call back into.
def get_callback_rest_url(remoteHost):
    return 'https://{0}:{1}'.format(get_local_ipaddress(remoteHost), config.get('ssl', 'port'))

# Initializes configuration.
def init_config(configFile='panw.conf'):
    global config
    config = ConfigParser.ConfigParser()
    config.read(configFile)

# Initializes logging.
def init_logging(level=logging.INFO):

    format = '%(asctime)-15s: %(funcName)s(): %(message)s'
    logging.basicConfig(format=format, level=level)

# Initializes the HTTP/SSL server.
def init_server(async=True):
    global ssl_svr

    host = config.get('ssl', 'host')
    port = int(config.get('ssl', 'port'))

    # Create a new WSGI HTTP/SSL server.
    ssl_svr = pywsgi.WSGIServer(
        (host, port),
        callback_response_handle,
        keyfile=config.get('ssl', 'keyFile'),
        certfile=config.get('ssl', 'crtFile'))

    logging.info('Serving on https://%s:%d', host, port)

    # Start our HTTP/SSL web server (based on the async flag).
    if async:
        ssl_svr.start()
        gevent.sleep(0.1)

    else:
        ssl_svr.serve_forever()

def init_esx_host_conn():
    global esx_handle
    esx_ip = config.get('esx','host')
    esx_un = config.get('esx','user')
    esx_pwd = config.get('esx','pwd')

    esx_handle = paramiko.SSHClient()
    esx_handle.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    esx_handle.connect(esx_ip, username = esx_un ,password = esx_pwd)


# Makes an HTTP request to the given URL.
def make_http_request(
    verb,
    url,
    payload=None,
    payloadFile=None,
    params=None,
    state=RunState.IDLE):

    global g_state
    g_state = state

    host = config.get('vsm', 'host')
    port = int(config.get('vsm', 'port'))

    logging.info('Entering state: %s...', g_state)
    #logging.info('Creating HTTPS connection to %s:%d...', host, port)

    # Create HTTPS connection to the vSM REST endpoint.
    conn = httplib.HTTPSConnection(
        host,
        port,
        timeout = int(config.get('http', 'timeout')))

    # Check for payload.
    if payload == None:

        # Look for the payload file.
        if payloadFile != None:

            f = open(payloadFile)
            payload = f.read()

            # Look for parameters (to be replaced in the payload).
            if params:
                payload = payload.format(*params)

    user = config.get('vsm', 'user')
    pwd = config.get('vsm', 'pwd')

	# Define required headers.
    authz = 'Basic ' + base64.encodestring('{0}:{1}'.format(user, pwd))
    content_type = 'application/xml'

    # Set the content length (header).
    if payload:
        content_length = len(repr(payload))

    else:
        content_length = 0

    # Add headers to our HTTP connection object.
    conn_headers = {
        'Authorization': authz,
        'Content-Type': content_type,
        'Content-Length': content_length}

    # Log w/o payload.
    if payload:
        logging.info('Sending request: %s: %s\n\n', verb, url)
        #logging.info('Sending request: %s: %s\n\n%s', verb, url, payload)

    else:
        logging.info('Sending request: %s: %s', verb, url)

    # Make the HTTP request.
    conn.request(verb, url, headers=conn_headers, body=payload)

    # Breathe (this is crucial for callbacks into our HTTP/SSL endpoint).
    gevent.sleep(1)

    # Get the HTTP response.
    result = conn.getresponse()
    response = result.read()

    # Close the outbound connection.
    conn.close()

    logging.info('Received response:\n\n%s\n', response)

    return response

# Composes a target URI based on the default REST URI.
def make_uri(uri):
    result = '{0}{1}'.format(config.get('vsm', 'restUri'), uri)
    return result

# Performs a wait on stdin.
def blocking_wait(prompt=None):

    # If no prompt is given, assume a default one.
    if (prompt == None):
        prompt = 'Press any key to continue...'

    sys.stdout.write('\n{0}\n'.format(prompt))
    sys.stdout.flush()
    gevent.select.select([sys.stdin], [], [])
    return sys.stdin.readline()

# Stops the HTTP/SSL web server.
def stop_server():
    global ssl_svr
    host = config.get('ssl', 'host')
    port = int(config.get('ssl', 'port'))
    logging.info('Stop serving on https://%s:%d', host, port)
    ssl_svr.stop()

# ######################################################################
# vSM: Service Manager API-s
# ######################################################################

# Create a Service Manager.
def vsm_create_service_manager():

    result = make_http_request(
        HttpVerb.POST,
        make_uri('/si/servicemanager'),
        payloadFile='vsm_create_service_manager.xml',
        params=[
            config.get('Service Manager', 'name'),
            config.get('Service Manager', 'description'),
            config.get('Vendor Template', 'name'),
            config.get('Vendor Template', 'id'),
            config.get('ssl', 'thumbprint'),
	    ""],
#            get_callback_rest_url(config.get('vsm', 'host'))],
        state=RunState.VSM_CREATE_SERVICE_MANAGER)

    return result

# Get the Service Manager.
def vsm_get_service_manager(serviceManagerId):

    result = make_http_request(
        HttpVerb.GET,
        make_uri('/si/servicemanager/{0}'.format(serviceManagerId)),
        state=RunState.VSM_GET_SERVICE_MANAGER)

    return result

# Delete the Service Manager.
def vsm_delete_service_manager(serviceManagerId):

    result = make_http_request(
        HttpVerb.DELETE,
        make_uri('/si/servicemanager/{0}'.format(serviceManagerId)),
        state=RunState.VSM_DELETE_SERVICE_MANAGER)

    return result

# Update the Service Manager status.
def vsm_update_service_manager_status(serviceManagerId):

    result = make_http_request(
        HttpVerb.PUT,
        make_uri('/si/servicemanager/{0}/status'.format(serviceManagerId)),
        payloadFile='vsm_update_service_manager_status.xml',
        state=RunState.VSM_UPDATE_SERVICE_MANAGER_STATUS)

    return result


# ######################################################################
# vSM: Service API-s
# ######################################################################

# Create a Service associated with a Service Manager.
def vsm_create_service(serviceManagerId):

    result = make_http_request(
        HttpVerb.POST,
        make_uri('/si/service'),
        payloadFile='vsm_create_service.xml',
        params=[
            config.get('Service', 'name'),
            config.get('Service', 'category'),
            serviceManagerId,
            config.get('Service', 'agentname')],
        state=RunState.VSM_CREATE_SERVICE)

    return result

# Get the Service.
def vsm_get_service(serviceId):

    result = make_http_request(
        HttpVerb.GET,
        make_uri('/si/service/{0}'.format(serviceId)),
        state=RunState.VSM_GET_SERVICE)

    return result

# Delete the Service.
def vsm_delete_service(serviceId):

    result = make_http_request(
        HttpVerb.DELETE,
        make_uri('/si/service/{0}'.format(serviceId)),
        state=RunState.VSM_DELETE_SERVICE)

    return result

# Update the Service status.
def vsm_update_service_status(serviceId):

    result = make_http_request(
        HttpVerb.PUT,
        make_uri('/si/service/{0}/status'.format(serviceId)),
        payloadFile='vsm_update_service_status.xml',
        state=RunState.VSM_UPDATE_SERVICE_STATUS)

    return result

# ######################################################################
# vSM: Service Instance Template API-s
# ######################################################################
def vsm_create_service_instance_template(serviceId):

    result = make_http_request(
        HttpVerb.POST,
        make_uri('/si/service/{0}/serviceinstancetemplate'.format(serviceId)),
        payloadFile='vsm_create_service_instance_template.xml',
	params=[
            config.get('Service', 'agentname')],
	state=RunState.VSM_CREATE_SERVICE_INSTANCE_TEMPLATE)

    return result

def vsm_get_sevice_serviceinstanceId(serviceId):

    result = make_http_request(
        HttpVerb.GET,
        make_uri('/si/serviceinstances'.format(serviceId)),
        state=RunState.VSM_GET_SERVICE)
    
    (xml_boiler, separator, xml) = result.partition("<serviceInstances>")
    import xml.etree.ElementTree as ET
    root = ET.fromstring(result)
    for child_lev_1 in root:
         for child_lev_2 in child_lev_1:
             if(str(child_lev_2.tag) == 'objectId'):
	         serviceInstance = str(child_lev_2.text)
	     for child_lev_3 in child_lev_2:
		 if (str(child_lev_3.text) == serviceId):
                     return serviceInstance

def vsm_deploy(serviceInstanceId):
    result = make_http_request(
        HttpVerb.POST,
        make_uri('/si/deploy'),
        payloadFile='vsm_deploy.xml',
        params=[
            config.get('Deployment Scope', 'moid'),
            config.get('Deployment Scope', 'datastore'),
            serviceInstanceId,
            config.get('Binding', 'distributedvirtualportgroups')],
        state=RunState.VSM_DEPLOY_SERVICE)

    return result


def vsm_delete_serviceinstance(serviceInstanceId):
    result = make_http_request(
        HttpVerb.DELETE,
        make_uri('/si/serviceinstance/{0}'.format(serviceInstanceId)),
        state=RunState.VSM_DELETE_SERVICE_INSTANCE)

    return result


def vsm_delete_cluster():

    clusterId = config.get('Deployment Scope','moid')
    result = make_http_request(
        HttpVerb.DELETE,
        make_uri('/si/deploy/cluster/{0}'.format(clusterId)),
        state=RunState.VSM_DELETE_CLUSTER)

    return result

# ######################################################################
# vSM: Vendor Template API-s
# ######################################################################

# Create a Vendor Template associated with a Service.
def vsm_create_vendor_template(serviceId):

    result = make_http_request(
        HttpVerb.POST,
        make_uri('/si/service/{0}/vendortemplate'.format(serviceId)),
        payloadFile='vsm_create_vendor_template.xml',
        params=[
            config.get('Vendor Template', 'name'),
            config.get('Vendor Template', 'description'),
            config.get('Vendor Template', 'id')],
        state=RunState.VSM_CREATE_VENDOR_TEMPLATE)

    return result

# Get the Vendor Template associated with a Service.
def vsm_get_vendor_template(serviceId, templateId):

    result = make_http_request(
        HttpVerb.GET,
        make_uri('/si/service/{0}/vendortemplate/{1}'.format(serviceId, templateId)),
        state=RunState.VSM_GET_VENDOR_TEMPLATE)

    return result

# Delete the Vendor Template associated with a Service.
def vsm_delete_vendor_template(serviceId, templateId):

    result = make_http_request(
        HttpVerb.DELETE,
        make_uri('/si/service/{0}/vendortemplate/{1}'.format(serviceId, templateId)),
        state=RunState.VSM_DELETE_VENDOR_TEMPLATE)

    return result

# ######################################################################
# vSM: Deployment Spec API-s
# ######################################################################

# Create a Depolyment Specification for the Service
def vsm_create_versioneddeploymentspec(serviceId):
    result = make_http_request(
        HttpVerb.POST,
        make_uri('/si/service/{0}/servicedeploymentspec/versioneddeploymentspec'.format(serviceId)),
        payloadFile='vsm_create_versioneddeploymentspec.xml',
        params=[
            config.get('Deployment Spec', 'id'),
            config.get('Deployment Spec', 'hostversion'),
            config.get('Deployment Spec', 'ovfurl')],
        state=RunState.VSM_CREATE_DEPLOYMENTSPEC)

    return result

# Get the Deployment Spec
def vsm_get_deploymentspec(serviceId):

    result = make_http_request(
        HttpVerb.GET,
        make_uri('/si/service/{0}/servicedeploymentspec'.format(serviceId)),
        state=RunState.VSM_GET_SERVICE_DEPLOYMENTSPEC)

    return result

# set deployment scope
def vsm_set_deployment_scope(serviceId):
    result = make_http_request(
        HttpVerb.PUT,
        make_uri('/si/service/{0}/servicedeploymentspec/deploymentscope'.format(serviceId)),
        payloadFile='vsm_set_deployment_scope.xml',
        params=[config.get('Deployment Scope', 'moid')],
        state=RunState.VSM_SET_DEPLOYMENT_SCOPE)

    return result

# install the service
def vsm_service_install(serviceId):
    result = make_http_request(
        HttpVerb.POST,
        make_uri('/si/service/{0}/config?action=install'.format(serviceId)),
        state=RunState.VSM_SERVICE_INSTALL)

    return result

# setup the service
def vsm_service_setup(serviceId):
    result = make_http_request(
        HttpVerb.POST,
        make_uri('/si/service/{0}/config?action=setup'.format(serviceId)),
        state=RunState.VSM_SERVICE_SETUP)

    return result

# cleanup the service
def vsm_service_cleanup(serviceId):
    result = make_http_request(
        HttpVerb.POST,
        make_uri('/si/service/{0}/config?action=cleanup'.format(serviceId)),
        state=RunState.VSM_SERVICE_CLEANUP)

    return result


# install the service
def vsm_service_uninstall(serviceId):
    result = make_http_request(
        HttpVerb.POST,
        make_uri('/si/service/{0}/config?action=disable'.format(serviceId)),
        state=RunState.VSM_SERVICE_DISABLE)
    result = make_http_request(
        HttpVerb.POST,
        make_uri('/si/service/{0}/config?action=uninstall'.format(serviceId)),
        state=RunState.VSM_SERVICE_UNINSTALL)

    return result

# ######################################################################
# vSM: Service Profile API-s
# ######################################################################

# Create a Service Profile associated with a Service and a Vendor Template.
def vsm_create_service_profile(serviceId, templateId, serviceInstance):

    result = make_http_request(
        HttpVerb.POST,
        make_uri('/si/serviceprofile'),
        payloadFile='vsm_create_service_profile.xml',
        params=[
            config.get('Service Profile', 'name'),
            config.get('Service Profile', 'description'),
            serviceId,
            templateId,
            config.get('Vendor Template', 'name'),
            config.get('Vendor Template', 'description'),
            serviceInstance],
        state=RunState.VSM_CREATE_SERVICE_PROFILE)

    return result

# Get the Service Profile.
def vsm_get_service_profile(profileId):

    result = make_http_request(
        HttpVerb.GET,
        make_uri('/si/serviceprofile/{0}'.format(profileId)),
        state=RunState.VSM_GET_SERVICE_PROFILE)

    return result

# Delete the Service Profile.
def vsm_delete_service_profile(profileId):

    result = make_http_request(
        HttpVerb.DELETE,
        make_uri('/si/serviceprofile/{0}'.format(profileId)),
        state=RunState.VSM_DELETE_SERVICE_PROFILE)


    return result
# Create the binding xml file to use in request
def vsm_create_binding_xml(fname):
    # read the relevent config 
    dvpg = config.get('Binding' , 'distributedvirtualportgroups')
    virtualWires = config.get('Binding' , 'virtualwires')
    excludedVnics = config.get('Binding' , 'excludedvnics')
    virtualServers = config.get('Binding' , 'virtualservers')

    # start building the xml file for binding
    file = open(fname, 'w')


    file.write('<serviceProfileBinding>\n<distributedVirtualPortGroups>\n')
    for f in dvpg.split():
        entry = ('<string>' + str(f) + '</string>\n')
        s = str(entry);
        file.write(s)

    file.write("</distributedVirtualPortGroups>\n<virtualWires>\n" )
    for f in virtualWires.split():
        entry = ('<string>' + str(f) + '</string>\n')
        s = str(entry);
        file.write(s)
    file.write("</virtualWires> \n <excludedVnics> \n" )
    for f in excludedVnics.split():
        entry = ('<string>' + str(f) + '</string>\n')
        s = str(entry);
        file.write(s)
    file.write("</excludedVnics>\n<virtualServers>\n" )
    for f in virtualServers.split():
        entry = ('<string>' + str(f) + '</string>\n')
        s = str(entry);
        file.write(s)
    file.write("</virtualServers>\n</serviceProfileBinding>\n" )

    file.close();

    return file
# Update the Service Profile status.
def vsm_update_service_profile_binding(profileId):
    fname="vsm_update_profile_binding.xml"
    file = vsm_create_binding_xml(fname)

    result = make_http_request(
        HttpVerb.PUT,
        make_uri('/si/serviceprofile/{0}/binding'.format(profileId)),
        payloadFile='{0}'.format(fname),
        state=RunState.VSM_UPDATE_SERVICE_PROFILE_BINDING)

    return result

def vsm_service_profile_unbind(profileId):
    result = make_http_request(
        HttpVerb.PUT,
        make_uri('/si/serviceprofile/{0}/binding'.format(profileId)),
        payloadFile='vsm_unbind_profile.xml',
        state=RunState.VSM_UPDATE_SERVICE_PROFILE_BINDING)

    return result

# Test: update the Service Profile status.
def vsm_update_service_profile_status(profileId):

    result = make_http_request(
        HttpVerb.PUT,
        make_uri('/si/serviceprofile/{0}/status'.format(profileId)),
        payloadFile='vsm_update_service_profile_status.xml',
        state=RunState.VSM_UPDATE_SERVICE_PROFILE_STATUS)

    return result

# add rule
def vsm_add_rule(profileId):
    result = make_http_request(
	HttpVerb.POST,
        make_uri('/si/serviceprofile/{0}/ruleset/rule'.format(profileId)),
        payloadFile='vsm_add_rule.xml',
        state=RunState.VSM_ADD_RULE)

    return result

# ######################################################################
# Verification
# ######################################################################

def check_summarize_dvf(serviceinstanceId):
    stdin, stdout, stderr = esx_handle.exec_command("summarize-dvfilter")
    command_op = stdout.read()
#    command_op = stdout.read().splitlines()
#    for line in command_op:
#        print line
    expected_string = 'agent: ' + serviceinstanceId
    match = re.search(expected_string,command_op)
    if match:
        logging.info('Found %s in summarize-dvfilter', expected_string)
    else:
	logging.info('Not Found %s in summarize-dvfilter', expected_string)

# ######################################################################
# Main entry point
# ######################################################################

# Global state tracker.
g_state = RunState.IDLE

# Initialize logger.
init_logging()

# Initialize config.
init_config()

# Initialize the HTTP/SSL server.
init_server()

# Initialize connection to esx host
init_esx_host_conn()


# Service Manager related API-s.
serviceManagerId = vsm_create_service_manager()
vsm_get_service_manager(serviceManagerId)
vsm_update_service_manager_status(serviceManagerId)

# Service related API-s.
serviceId = vsm_create_service(serviceManagerId)
vsm_get_service(serviceId)
vsm_update_service_status(serviceId)

# Vendor Template related API-s.
templateId = vsm_create_vendor_template(serviceId)
vsm_get_vendor_template(serviceId, templateId)


blocking_wait('Created Service Manager, Service, Vendor template created. Press enter to continue with deployment spec... CTRL+C to keep the config and exit the script\n')


# Service Instance Template API 
#serviceInstanceId = vsm_create_service_instance_template(serviceId)

#blocking_wait('Service profile created. Press enter for deployment spec... CTRL+C to keep the config and exit the script\n')
serviceinstanceId = vsm_get_sevice_serviceinstanceId(serviceId)
versionedSpecId = vsm_create_versioneddeploymentspec(serviceId)

blocking_wait('Deployment spec created. Press enter for deploying, creating service profile. CTRL+C to keep the config and exit the script\n')

vsm_deploy(serviceinstanceId)

# Service Profile related API-s.
profileId = vsm_create_service_profile(serviceId, templateId, serviceinstanceId)
vsm_get_service_profile(profileId)



#vsm_set_deployment_scope(serviceId)
#vsm_get_deploymentspec(serviceId)
#vsm_service_install(serviceId)

# Wait for steps on UI
g_state = RunState.VSM_USER_INTERFACE_DEMO
blocking_wait('OVF deployment in progress...... The Next step is binding service profile for the service. Press enter to continue...\n')

vsm_update_service_profile_binding(profileId)
vsm_update_service_profile_status(profileId)

# Wait, for user input
g_state = RunState.VSM_CREATION_COMPLETE

check_internal_states = True 
if check_internal_states:
    blocking_wait('The Next step is to check internal states. Please wait for sometime so that ovf deployment is done. Press enter to continue...\n')
    # Verify the status
    check_summarize_dvf(serviceinstanceId)

blocking_wait('******  PLEASE READ:   ****** . Service creation Complete and Binding done....  Press enter to destroy the configuration... CTRL+C to keep the config and exit the script\n')


# Clean-up vSM config.
vsm_service_profile_unbind(profileId)
# vsm_service_uninstall(serviceId)

#vsm_delete_serviceinstance(serviceinstanceId)
vsm_delete_cluster()
vsm_delete_service_profile(profileId)

vsm_delete_serviceinstance(serviceinstanceId)
vsm_delete_vendor_template(serviceId, templateId)

blocking_wait('Waiting before deleting the service. Does not delete the service if  vsm_delete_service is called immediately')
vsm_delete_service(serviceId)
vsm_delete_service_manager(serviceManagerId)

# Stop our HTTP/SSL web server.
stop_server()
