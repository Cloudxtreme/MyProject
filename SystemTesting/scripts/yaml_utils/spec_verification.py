########################################################################
# Copyright (C) 2015 VMware, Inc.
# # All Rights Reserved
########################################################################

#
# This module validates keyword correctness of a
# VDNet Test Design Specification (Tds) compared
# with KeysDB specifications. If the keys used
# in the TDS are matching with the keys declared
# in keys database (Workloads/yaml/)
#
# The error are raised in form of error messages.
# All the errors are collected in the error_stack
# array and recorded in error_stack array which is
# used to decide if the verification process was a
# a success or failure
#
# TODO#1(prabuddh): Extend the support to verify workloads
#

import logging
import os
import yaml
import json
import sys
import vdnet_spec

TMP = '/tmp'
LOG_PREFIX = 'spec_verification'
LOG_SUFFIX = '.log'
log = logging.getLogger(LOG_PREFIX)
error_stack = None

# For unit testing
spec_json_small = \
    {'testinventory':
        {'a':
            {'testcomponent':
                {'1':
                    {'bar':
                        {'foo': 'testinventory.[1].testcomponent.[2]->ip'},
                        'reconfigure': 'true'}}}}}


def configure_logging(log_dir=TMP):
    log_file = os.path.join(log_dir, "%s%s" % (LOG_PREFIX, LOG_SUFFIX))
    formatter = logging.Formatter('%(asctime)s %(levelname)-8s %(message)s',
                                  datefmt='%Y-%m-%d %H:%M:%S')
    logging.basicConfig(level=logging.INFO)
    log.propagate = False
    # remove existing handlers to avoid PR1373949
    for handler in log.handlers:
        log.removeHandler(handler)
    fh = logging.FileHandler(log_file)
    fh.setLevel(logging.DEBUG)
    fh.setFormatter(formatter)
    log.addHandler(fh)


def add_stdout_logging():
    formatter = logging.Formatter('%(asctime)s %(levelname)-8s %(message)s',
                                  datefmt='%Y-%m-%d %H:%M:%S')
    sh = logging.StreamHandler(sys.stdout)
    formatter = logging.Formatter('%(asctime)s %(levelname)-8s %(message)s',
                                  datefmt='%Y-%m-%d %H:%M:%S')
    sh.setLevel(logging.DEBUG)
    sh.setFormatter(formatter)
    log.addHandler(sh)


def get_workload_yaml_path():
    """
    Helper function to get the path for all
    workload yamls in VDNetLib/Workloads/yaml/

    @rtype: str
    @return: return the relative patch to yaml folder
    """
    path = os.path.dirname(__file__)
    relative = '../../'
    yaml_path = os.path.join(path, relative, 'VDNetLib', 'Workloads', 'yaml')
    return yaml_path


def get_workload_keys_db(workload=None):
    """
    Helper function to convert VDNetLib/Workloads/yaml/workload.yaml
    into a python dictionary

    @type wokrload: str
    @param workload: name of the workload.yaml
    @rtype: dict
    @return: python dictionary containg the keys db of workload.yaml
    """
    yaml_path = os.path.join(get_workload_yaml_path(), workload)
    stream = open(yaml_path, 'r')
    return yaml.load(stream)


def verify_json_testbedspec(spec=None):
    """
    Helper function to call the main subroutine
    The input is json because the callers from
    vdnet send json based dictionaries

    @rtype: json dict
    @return: call on recurse_through_spec() method
    """
    dict_spec = json.loads(spec)
    return recurse_through_spec(dict_spec)


def recurse_through_spec(spec=None, workload_name=None):
    """
    Main method to verify the testbedspec

    @type spec: dict
    @param spec: python dictionary representing a spec used in TDS
    @type workload_name: string
    @param workload_name: name of the workload that will be used as reference
                          for verification of the spec
    @rtype: bool
    @return: return true
    """
    workload = None
    if workload_name is None:
        workload_name = 'RootWorkload.yaml'
        workload = get_workload_keys_db(workload_name)
    else:
        workload = get_workload_keys_db(workload_name)
        parent_workload = get_workload_keys_db('ParentWorkload.yaml')
        merged_workload = parent_workload.copy()
        merged_workload.update(workload)
        workload = merged_workload
    log.debug("Querying workload: %s for keys" % workload_name)
    for key in spec:
        verify_keys(key.lower(), workload, spec, workload_name)
    return True


def verify_keys(key=None, workload=None, spec=None, workload_name=None):
    """
    Main handler method to check keys

    @type key: string
    @param key: key that needs to be verified
    @type workload: dict
    @param workload: python diction of KeysDB
    @type spec: dict
    @param spec: python dictionary representing a spec used in TDS
    @type workload_name: string
    @param workload_name: name of the workload that will be used as reference
                          for verification of the spec
    @rtype: bool
    @return: return true
    """
    if (key in workload) and ('linkedworkload' in workload[key]):
        log.debug("Component key: '%s' exists in workload: '%s'" %
                  (key, workload_name))
        workload_name = workload[key]['linkedworkload'] + '.yaml'
        index_list = spec[key].keys()
        for index in index_list:
            log.debug("Verifying spec under index: %s" % index)
            # Recursion Point
            recurse_through_spec(spec[key][index], workload_name)
    # check for action, parameters, verification keys
    elif(key in workload):
        log.debug("Key exists = %s, doing further check" % key)
        verify_parameter_component_verification_keys(key,
                                                     workload,
                                                     spec,
                                                     workload_name)
    else:
        error_message = "Key: %s is not present in keysDB: %s" %\
                        (key, workload_name)
        log.error(error_message)
        error_stack.append(error_message)
    return True


def verify_parameter_component_verification_keys(key=None, workload=None,
                                                 spec=None,
                                                 workload_name=None):
    """
    Helper function to distribute verification
    tasks amongst various methods

    @type key: string
    @param key: key that needs to be verified
    @type workload: dict
    @param workload: python diction of keys db
    @type spec: dict
    @param spec: python dictionary representing a spec used in TDS
    @type workload_name: string
    @param workload_name: name of the workload that will be used as reference
                          for verification of the spec
    @rtype: bool
    @return: always return true
    """
    key_format = workload[key]['format']
    if (type(key_format) == type(spec[key])):
        log.debug("Object type: %s consistent for key: %s" %
                  (type(key_format), key))
    else:
        if (isinstance(spec[key], unicode)) and (isinstance(key_format, str)):
            log.debug("Object type: %s consistent for key: %s"
                      % (type(key_format), key))
        else:
            error_message = "Object type: %s inconsistent for key: %s" \
                            % (type(key_format), key)
            log.error(error_message)
            error_stack.append(error_message)
            error_message = "Object type of key in keys db: %s for key: %s" \
                            % (type(key_format), key)
            log.error(error_message)
            error_stack.append(error_message)
            error_message = "Object type of key from TDS: %s for key: %s" \
                            % (type(spec[key]), key)
            log.error(error_message)
            error_stack.append(error_message)

    if workload[key]['type'] == 'parameter':
        verify_parameter_keys(key, workload, spec, workload_name)
    if workload[key]['type'] == 'action':
        verify_action_keys(key, workload, spec, workload_name)


def verify_parameter_keys(key=None, workload=None, spec=None,
                          workload_name=None):
    """
    Method to verify parameter keys
    Verify values like vdnet index

    @type key: string
    @param key: key that needs to be verified
    @type workload: dict
    @param workload: python diction of keys db
    @type spec: dict
    @param spec: python dictionary representing a spec used in TDS
    @type workload_name: string
    @param workload_name: name of the workload that will be used as reference
                          for verification of the spec
    @rtype: bool
    @return: always return true for now. not raising exception at this point
             point of time
    """
    key_format = workload[key]['format']
    # check for vdnet index like inventory.[x].component.[y]
    if (("vdnet index" in key_format) or ("vdnet_index" in key_format)):
        log.debug("Expecting value in form inventory.[x].component.[y]")
        vdnet_index = spec[key].split(".")
        indexes = vdnet_index[1::2]
        indexes[-1] = indexes[-1].split("->")[0]
    return True


def verify_action_keys(key=None, workload=None, spec=None,
                       workload_name=None):
    """
    Method to verify action keys, verify values like vdnet index, verify
    dependency, verify manadatory paramaters

    @type key: string
    @param key: key that needs to be verified
    @type workload: dict
    @param workload: python diction of keys db
    @type spec: dict
    @param spec: python dictionary representing a spec used in TDS
    @type workload_name: string
    @param workload_name: name of the workload that will be used as reference
                          for verification of the spec
    @rtype: bool
    @return: always return true for now. not raising exception at this point
             point of time
    """
    log.debug("verifing action key: %s in workload: %s" % (key, workload_name))
    if 'params' in workload[key]:
        action_params_keysdb = workload[key]['params']
        a_p_k = action_params_keysdb
        action_params_spec = spec.keys()
        result = list(set(a_p_k).symmetric_difference(action_params_spec))
        if result == []:
            log.debug("Parameters needed for action key:%s are present" % key)
        else:
            error_message = "Parameters for action key: %s are inconsistent" \
                            % key
            log.error(error_message)
            error_stack.append(error_message)
            error_message = "From spec: %s" % action_params_spec
            log.error(error_message)
            error_stack.append(error_message)
            error_message = "From keysdb: %s" % action_params_keysdb
            log.error(error_message)
            error_stack.append(error_message)
    else:
        error_message = "Params undefined for action: %s in %s" % \
                        (key, workload_name)
        log.error(error_message)
        error_stack.append(error_message)

    return True


def verify_verification_keys(key=None, workload=None, spec=None,
                             workload_name=None):
    """
    Not Implemented
    """
    raise NotImplemented


if __name__ == "__main__":
    import argparse
    from datetime import datetime
    parser = argparse.ArgumentParser()
    parser.add_argument('-t', '--tds', nargs='+',
                        help='vdnet json spec that needs to be verified')
    parser.add_argument('--no-stdout', dest='stdout',
                        default=True,
                        help='Disable logging to stdout')
    parser.add_argument('-unit_test', '--unit_test', action='store_true',
                        help='Running unit test to check the script')
    args = parser.parse_args()
    configure_logging(TMP)
    if args.stdout:
        add_stdout_logging()
    if args.unit_test:
        recurse_through_spec(spec_json_small)
    if args.tds:
        startTime = datetime.now()
        error_stack = []
        output = vdnet_spec.resolve_tds(args.tds[0], TMP, None, None)
        for testcase in output.keys():
            if 'TestbedSpec' in output[testcase]:
                log.info("Start verification for testcase: '%s'" % testcase)
                recurse_through_spec(output[testcase]['TestbedSpec'])
                log.info("Completed verification for testcase: '%s' \n"
                         % testcase)
        time_result = datetime.now() - startTime
        log.debug("Total execution time: %s" % time_result)
        if not error_stack:
            log.info("All keys in testbedspec from TDS are valid")
        else:
            error_stack = None
            raise Exception("Keys validation failed, please fix errors")
