#!/usr/bin/env python
########################################################################
# Copyright (C) 2014 VMware, Inc.
# # All Rights Reserved
########################################################################

#
# This module resolves the vdnet spec given in yaml format
# into spec that can be processed by Testbed and Workloads module.
# TODO: Still significant code lives in Perl, move all spec resolution
# to this module
#
import glob
import logging
import os
import sys
import tempfile
import yaml

import yamlobjects
_ = yamlobjects  # Loads all yamltags into namespace

try:
    import jinja2
except ImportError:
    # TODO(Krishna): Need to resolve PATH issues in SandboxMaster, adding this
    # as a workaround for now
    my_dir = os.path.dirname(os.path.abspath(__file__))
    third_party_dir = os.path.abspath(
        os.path.join(my_dir, '../../third_party'))
    sys.path.insert(0, third_party_dir)
    import jinja2


COMMON_WORKLOADS_PATTERN = 'Common*.yaml'
TESTBED_SPEC_FILE = 'TestbedSpec.yaml'


VDNET_KEY_WORKLOADS = 'WORKLOADS'
VDNET_KEY_TESTNAME = 'testname'
VDNET_KEY_STEPSEQUENCE = 'StepSequence'
VDNET_KEY_SEQUENCE = 'Sequence'
VDNET_KEY_EXITSEQUENCE = 'ExitSequence'

YAML_INCLUDE_TAG = '!include'
JINJA_INCLUDE_TAG = '{% include'
COMMENT_TAG = '#'
NEGATION_MARKER = '~'
TMP = '/tmp'
LOG_PREFIX = 'vdnet_spec'
LOG_SUFFIX = '.log'
log = logging.getLogger(LOG_PREFIX)
ENABLE_YAML_CACHE = True
yaml_read_cache = {}
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
AUTOMATION_DIR = os.path.join(SCRIPT_DIR, "../../")


def KEY(*args):
    return str(args)


def as_list(obj):
    """
    Helper for making the object iterable as a list.

    @type obj: Any
    @param obj: Object that needs to be converted to a list.
    @rtype: list
    @return: Passed in object as a list (if it is not already a list).
    """
    if not hasattr(obj, '__iter__'):
        obj = [obj]
    return obj


class DupCheckConstructor(yaml.constructor.Constructor):
    """
    DupCheckConstructor works similar to yaml.constructor.Constructor,
    additionally it also prints warning messages for each set of duplicate keys
    being overridden during the construct_mapping call
    """
    __duplicate_key_warning = None

    def construct_mapping(self, node, deep=False):
        ret = super(DupCheckConstructor, self).construct_mapping(
            node, deep=deep)
        keys_found = {}
        for key_node, value_node in node.value:
            key = self.construct_object(key_node, deep=deep)
            if key in keys_found:
                previous = keys_found[key]
                msg = ("Duplicate keys found for key='%s'\n%s\n%s" %
                       (key, previous.start_mark, key_node.start_mark))
                log.warn(msg)
                DupCheckConstructor.__duplicate_key_warning = msg
            else:
                keys_found[key] = key_node
        return ret

    @classmethod
    def get_last_duplicate_warning(cls):
        return cls.__duplicate_key_warning


class DupCheckLoader(yaml.loader.Loader, DupCheckConstructor):
    """
    Class that warns on finding duplicate keys defined in the yaml being loaded
    using DupCheckConstructor
    >>> data = '''
    ... one: 1
    ... one: 4
    ... '''
    >>> yaml.load(data, Loader=DupCheckLoader)
    {'one': 4}
    >>> print DupCheckConstructor.get_last_duplicate_warning()
    Duplicate keys found for key='one'
      in "<string>", line 2, column 1:
        one: 1
        ^
      in "<string>", line 3, column 1:
        one: 4
        ^
    """
    def __init__(self, stream):
        super(DupCheckLoader, self).__init__(stream)
        DupCheckConstructor.__init__(self)


def read_yaml_with_includes(yaml_files, _already_included=None):
    """
    Routine to resolve all aliases and merges in the given yaml files by
    loading the required files included by using the tag YAML_INCLUDE_TAG.
    Note: YAML_INCLUDE_TAG at the start of the file are only processed for
    legibility of the yaml files
    Usage of the include tag:
        !include foo.yaml
        !include ../bar.yaml
        (or)
        !include foo.yaml ../bar.yaml

    Arguments:
        yaml_files: absolute path to one or more TDS yaml files
        _already_included: used to detect the loops in nested includes,
            this is internal and for recursive calls
    Returns:
        string: yaml with all the data (along with included yamls)
    >>> test_yaml = os.path.join(os.path.dirname(__file__), 'tests', 'a.yaml')
    >>> read_yaml_with_includes([test_yaml])  # doctest: +ELLIPSIS
    ...                                       # doctest: +NORMALIZE_WHITESPACE
    Traceback (most recent call last):
        ...
    AssertionError: Loop discovered in nested !includes:
    ...a.yaml
        |
        V
    ...b.yaml
        |
        V
    ...a.yaml
    """
    if _already_included is None:
        _already_included = []

    for yaml_file in yaml_files[:]:
        if not os.path.exists(yaml_file):
            raise RuntimeError("Yaml file %s doesn't exist" % yaml_file)

    data = []
    for yaml_file in yaml_files:
        file_start = True
        yaml_file = os.path.abspath(yaml_file)
        dir_name = os.path.dirname(yaml_file)
        if yaml_file in _already_included:
            looping_files = _already_included[:] + [yaml_file]
            raise AssertionError('Loop discovered in nested !includes:\n%s' %
                                 ('\n\t|\n\tV\n'.join(looping_files)))
        fdata = []
        cache_key = KEY(yaml_file)
        if ENABLE_YAML_CACHE and cache_key in yaml_read_cache:
            fdata = yaml_read_cache.get(cache_key)
            log.info('%s,%s: LOADING yaml_file from cache: %s' %
                     (os.getpid(), os.getppid(), yaml_file))
        else:
            with open(yaml_file, 'r') as yaml_file_handle:
                log.debug("Reading from the yaml file: %s" % yaml_file)
                _already_included.append(yaml_file)
                for line in yaml_file_handle.read().splitlines():
                    if file_start and (line.startswith(COMMENT_TAG) or
                                       len(line.strip()) == 0):
                        continue
                    elif file_start and line.startswith(YAML_INCLUDE_TAG):
                        include_files = line.split()[1:]
                        for include_file in include_files:
                            path = os.path.join(dir_name, include_file)
                            fdata.append(read_yaml_with_includes(
                                [path], _already_included=_already_included))
                    else:
                        fdata.append(line)
                        file_start = False
                log.info('%s,%s: SAVING yaml_file to cache: %s' %
                         (os.getpid(), os.getppid(), yaml_file))
                if ENABLE_YAML_CACHE:
                    yaml_read_cache[cache_key] = fdata
                _already_included.pop()
        data.extend(fdata)
    return os.linesep.join(data)


def override_key(yaml_dict, custom_yaml, override_key):
    """ Routine to override specific key options in the deploy yaml from a
    custom options file if it exists.

    @type yaml_dict: dict
    @param yaml_dict: python dictionary containing the dict loaded from the
                      original yaml
    @type custom_yaml: filename
    @param custom_yaml: yaml file containing the override value/dict for
                            the specified override_key
    @type override_key: string
    @param override_key: name of the key that needs to be overriden
    @rtype: dict
    @return: original python dictionary with the override_key updated witho
             the values from the custom_yaml if it exists.
    >>> d = os.path.dirname(__file__)
    >>> a = {'foo': 'null'}
    >>> override_key(a, '_nonexistent_.yaml', 'foo')
    {'foo': 'null'}

    >>> a = {'foo': 'null'}
    >>> f = os.path.join(d, 'tests', 'test_override_key_positive.yaml')
    >>> override_key(a, f, 'foo')
    {'foo': 'bar'}

    >>> a = {}
    >>> f = os.path.join(d, 'tests', 'test_override_key_positive.yaml')
    >>> override_key(a, f, 'foo')
    {'foo': 'bar'}

    >>> a = {'foo': 'null'}
    >>> f = os.path.join(d, 'tests', 'test_override_key_negative.yaml')
    >>> override_key(a, f, 'foo')
    {'foo': 'null'}
    """
    if bool(custom_yaml) and os.path.exists(custom_yaml):
        log.info("Overriding options from file: %s" % custom_yaml)
        with open(custom_yaml, 'r') as custom_yaml_handle:
            custom_options_dict = yaml.load(custom_yaml_handle)
            if override_key not in yaml_dict:
                yaml_dict[override_key] = {}
            if override_key in custom_options_dict:
                if ((type(yaml_dict[override_key]) is dict and
                     type(custom_options_dict[override_key]) is dict)):
                    yaml_dict[override_key].update(
                        custom_options_dict[override_key])
                else:
                    yaml_dict[override_key] = custom_options_dict[override_key]
    return yaml_dict


def MOD(x, y):
    """
    Modulo with starting index as 1 instead of 0
    """
    return int(1 + (x-1) % y)


def DIV(x, y):
    """
    Division with starting index as 1 instead of 0
    """
    return int(1 + (x-1)/y)


def RANGE(length, offset=0):
    """
    Range with given starting offset and starting index as 1
    instead of 0
    """
    return range(1+offset, 1+offset+length)


def load_yaml(yaml_file, dst_dir):
    """
    Routine to resolve all aliases and merges in the given yaml file by loading
    the required files included by using the YAML_INCLUDE_TAG

    Arguments:
        yaml_file: absolute path to TDS yaml file
        dst_dir: destination dir to create merged file
    Returns:
        dict: python dict representation (along with included yamls)
    """
    yaml_files = as_list(yaml_file)
    data = read_yaml_with_includes(yaml_files)

    if dst_dir is None:
        dst_dir = TMP

    prefix = os.path.basename(yaml_files[-1])
    kw = dict(delete=False, dir=dst_dir, prefix=prefix)
    try:
        loader = jinja2.FileSystemLoader(AUTOMATION_DIR)
        ENV = jinja2.Environment(loader=loader)
        tmpl = ENV.from_string(data)
        tmpl.globals.update(int=int)
        tmpl.globals.update(range=range)
        tmpl.globals.update(MOD=MOD)
        tmpl.globals.update(DIV=DIV)
        tmpl.globals.update(RANGE=RANGE)
        yaml_data = tmpl.render()
    except Exception:
        # Write temporay yaml to a file only when yaml loading fails
        with tempfile.NamedTemporaryFile(**kw) as f:
            log.info("Jinja2 expanded yaml written to %s" % f.name)
            f.write(repr(data))
            loader = jinja2.FileSystemLoader(AUTOMATION_DIR)
            ENV = jinja2.Environment(loader=loader)
            tmpl = ENV.from_string(data)
            tmpl.globals.update(int=int)
            tmpl.globals.update(range=range)
            tmpl.globals.update(MOD=MOD)
            tmpl.globals.update(DIV=DIV)
            tmpl.globals.update(RANGE=RANGE)
            yaml_data = tmpl.render()

    yaml_dict = {}
    try:
        yaml_dict = yaml.load(yaml_data, Loader=DupCheckLoader)
    except Exception:
        # Write temporay yaml to a file only when yaml loading fails
        with tempfile.NamedTemporaryFile(**kw) as f:
            f.write(yaml_data)
            f.seek(0)
            yaml_dict = yaml.load(f, Loader=DupCheckLoader)
    return yaml_dict


def load_yaml_with_overrides(yaml_file, dst_dir, override_option=None,
                             custom_yaml=None, overriding_key=None):
    """
    Wrapper that will call load_yaml to resolve all aliases and merges in the
    given yaml file. It will also override the value of the key specified by
    the overriding_key in the deployment YAML with the one present in the
    custom_yaml file.

    Arguments:
        yaml_file: absolute path to TDS yaml file
        dst_dir: destination dir to create merged file
        override_option: flag to enabled/disable overriding options in
                         deployment yaml
        custom_yaml: user created file from which the options would be picked
                     and would override the options in the deployment yaml when
                     override_option flag is set to 1.
        overriding_key: key in the deployment yaml that needs to be overriden
                        from custom_yaml if present.
    Returns:
        dict: python dict representation (along with included yamls)
    """
    tds_dict = {}
    tds_dict = load_yaml(yaml_file, dst_dir)
    if bool(override_option):
        return override_key(tds_dict, custom_yaml, overriding_key)
    else:
        return tds_dict


def configure_logging(log_dir=TMP):
    log_file = os.path.join(log_dir, "%s%s" % (LOG_PREFIX, LOG_SUFFIX))
    formatter = logging.Formatter('%(asctime)s %(levelname)-8s %(message)s',
                                  datefmt='%Y-%m-%d %H:%M:%S')
    logging.basicConfig(level=logging.DEBUG)
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


def csv2list_simple(csv_string):
    """
    Routine to convert as csv to list and normalize the list to lower case,
    does not support single or double quotes in the string
    >>> csv2list_simple('a,b,c')
    ['a', 'b', 'c']
    >>> csv2list_simple("This is'nt supported csv string, 'a,b', 'c'")
    ["this is'nt supported csv string", "'a", "b'", "'c'"]
    """
    if csv_string is None:
        return []
    if type(csv_string) is not str:
        raise AssertionError(
            "Invalid param %s provided, should be csv string" % csv_string)
    lst = [x.strip().lower() for x in csv_string.split(',')]
    return lst


def get_normalized_priority(priority):
    return csv2list_simple(priority)


def get_normalized_usertags(usertags):
    return csv2list_simple(usertags)


def is_not_matching_filter(input_values, filter_values):
    """
    Routine to check filter doesn't apply for a list of values|strings

    @type input_values: list of strings
    @param input_values: list of tags/priority that are in tds
    @type filter_values: list of strings
    @param filter_values: list of tags/params that are useds for filtering
    @rtype: boolean
    @return: returns True if the filter doesn't match else False
    >>> is_not_matching_filter(['a', 'b', 'c'], ['a'])
    False
    >>> is_not_matching_filter(['a', 'b', 'c'], ['~a'])
    True
    >>> is_not_matching_filter(['a', 'b', 'c'], ['~a', 'b'])
    True
    >>> is_not_matching_filter(['a', 'b', 'c'], ['a', 'd'])
    False
    >>> is_not_matching_filter(['a', 'b', 'c'], ['d', 'e'])
    True
    """
    if not filter_values:
        return False  # No filter is applied
    positive_match = False
    negative_match = False
    for x in filter_values:
        negate = x.startswith(NEGATION_MARKER)
        if negate and x[1:] in input_values:
            negative_match = True
            break  # break on negative match
        if not negate and x in input_values:
            positive_match = True
            continue  # for negative filtering
    return negative_match or not positive_match


def resolve_aliases_and_merges(tds_yaml, dst_dir):
    """
    Routine to resolve all aliases and merges in the given Tds yaml file.

    @type tds_yaml: string
    @param tds_yaml: Absolute path to TDS yaml
    @type dst_dir: string
    @param dst_dir: Destination dir to create merged file, defaults to TMP
    @rtype: dict
    @return: Returns the tds dict loaded from the tds yaml or
    @raise: AssertionError on invalid yaml syntax or missing aliases etc
    """
    #
    # Yaml allows anchors, aliases and merges within one file.
    # This routine takes care of combining 3 files (Tds.yaml,
    # TestbedSpec.yaml, CommonWorkloads.yaml) into one temporary
    # file and loads them using Yaml parser (loading just one file at a time
    # would throw error since there are no references for aliases).
    # In order to avoid duplication of test data, and at the same
    # time to restrict the scope of reusing shared data, in vdnet,
    # TestbedSpec.yaml and CommonWorkload.yaml within the same directory
    # as *Tds.yaml are allowed to reuse data.
    #
    if dst_dir is None:
        dst_dir = TMP

    # Check for YAML_INCLUDE_TAG at the top of the file allowing comments
    # starting with '#' only to be before the include tags for legibility
    yaml_file_list = None
    with open(tds_yaml, 'r') as f:
        for line in f.read().splitlines():
            if ((line.startswith(YAML_INCLUDE_TAG) or
                 line.startswith(JINJA_INCLUDE_TAG))):
                yaml_file_list = tds_yaml
                break
            elif line.startswith(COMMENT_TAG):
                continue
            else:
                break
    if yaml_file_list is None:
        log.debug("Loading yaml without !includes: %s" % tds_yaml)
        dir_name = os.path.dirname(os.path.abspath(tds_yaml))
        yaml_file_list = glob.glob(os.path.join(dir_name,
                                                COMMON_WORKLOADS_PATTERN))
        testbedspec_file = os.path.join(dir_name, TESTBED_SPEC_FILE)
        if os.path.exists(testbedspec_file):
            yaml_file_list.append(testbedspec_file)
        else:
            log.warn("TestbedSpec file not found, ignoring: %s" %
                     testbedspec_file)
        yaml_file_list.append(tds_yaml)

    tds_dict = load_yaml(yaml_file_list, dst_dir)
    return expand_step_sequence(tds_dict)


def expand_step_sequence(tds_dict):
    """
    Returns tds_dict with StepSequence expanded into Sequence/ExitSequences.
    >>> test_yaml = os.path.join(os.path.dirname(__file__), 'tests',
    ...                          'StepSequenceTds.yaml')
    >>> resolve_aliases_and_merges(
    ...     test_yaml, TMP)['T1']['WORKLOADS']['Sequence']
    [['s1'], ['s2'], ['s3'], ['v3'], ['s4'], ['s5']]
    >>> resolve_aliases_and_merges(
    ...     test_yaml, TMP)['T1']['WORKLOADS']['ExitSequence']
    [['c5'], ['c4'], ['c3'], ['c2'], ['c1']]
    """
    for t in tds_dict:
        if not is_a_test(tds_dict[t]):
            continue
        workloads = tds_dict[t].get(VDNET_KEY_WORKLOADS, {})
        if (((VDNET_KEY_SEQUENCE in workloads or
              VDNET_KEY_EXITSEQUENCE in workloads) and
             VDNET_KEY_STEPSEQUENCE in workloads)):
            raise ValueError("Cannot specify StepSequence with Sequence "
                             "or ExitSquence in test '%s'" % t)
        stepsequence = workloads.get(VDNET_KEY_STEPSEQUENCE)
        if stepsequence:
            seq = []
            exitseq = []
            for w in stepsequence:
                step = workloads.get(w)
                if step.setup:
                    seq.extend(step.setup)
                if step.verify:
                    seq.extend(step.verify)
                if step.cleanup:
                    # Reverse the cleanup workloads for merging multiple steps
                    # in proper order
                    exitseq.extend(step.cleanup[::-1])
            # Finally reverse the workloads to get the right cleanup order
            exitseq = exitseq[::-1]
            workloads[VDNET_KEY_SEQUENCE] = seq
            workloads[VDNET_KEY_EXITSEQUENCE] = exitseq
            log.info("Updated test %s with Sequence:\n%s" %
                     (t, yaml.dump(seq, default_flow_style=False,
                                   default_style=False, indent=4)))
            log.info("Updated test %s with ExitSequence:\n%s" %
                     (t, yaml.dump(exitseq, default_flow_style=False,
                                   default_style=False, indent=4)))
        else:
            log.debug("No StepSequence found in %s" % workloads.keys)
    return tds_dict


def get_missing_workloads(tds_dict):
    missing_workloads = []
    try:
        for name, test in tds_dict.iteritems():
            if not is_a_test(test):
                continue
            for sequence in (VDNET_KEY_SEQUENCE, VDNET_KEY_EXITSEQUENCE):
                missing_workloads += resolve_custom_sequences(
                    tds_dict, test, sequence)
    except AssertionError:
        raise
    except Exception:
        log.exception('Unhandled exception')
    return missing_workloads


def filter_by_tags_priority(tds_dict, usertags, priority):
    """
    @type usertags: csv string
    @param usertags: Filter by the tags field in TDS
    @type priority: string
    @param priority: Filter by the priority field in TDS
    @return: Returns the tds dict filtered by usertags and priority
    """
    if priority is not None or usertags is not None:
        priority = get_normalized_priority(priority)
        usertags = get_normalized_usertags(usertags)
        for name, test in tds_dict.items():
            if not is_a_test(test):
                continue
            test_priority = test.get('Priority', test.get('priority'))
            test_usertags = test.get('Tags', test.get('tags'))

            test_priority = get_normalized_priority(test_priority)
            test_usertags = get_normalized_usertags(test_usertags)
            if ((is_not_matching_filter(test_priority, priority) or
                 is_not_matching_filter(test_usertags, usertags))):
                log.info('Skipping test %s with priority %s, '
                         'filtering for %s' %
                         (name, test_priority, priority))
                del tds_dict[name]
    return tds_dict


def resolve_custom_sequences(
        tds_dict, test, sequence,
        _known_workload_lists=None, _missing_workloads=None):
    """
    Verifies that all the workloads used in the SEQUENCE and
    nested sequences are defined
    @type tds_dict: dict
    @param tds_dict: TDS loaded from the yaml file
    @type test: test
    @param test: Test case dictionary
    @type sequence: list of lists
    @param sequence: Name of the sequence
    @type _known_workload_lists: list
    @param _known_workload_lists: Tracker for nested workload lists, supports
        loop detection.
    @type _missing_workloads: list
    @param _missing_workloads: List to accumulate all the missing workloads
    @rtype: list
    @return: Returns a list of workload names whose definitions are not found
    @raise: Raises AssertionError if group workload name is not str
    """
    test_workloads = test[VDNET_KEY_WORKLOADS]
    tds_workloads = tds_dict.get(VDNET_KEY_WORKLOADS, [])
    if _known_workload_lists is None:
        _known_workload_lists = []
    if _missing_workloads is None:
        _missing_workloads = []
    if not test_workloads.get(sequence):
        # FIXME(Giri): shouldn't we raise error here?
        return []

    log.info('Resolving sequence %s' % sequence)
    for workload_set in test_workloads[sequence]:
        if isinstance(workload_set, str):
            raise AssertionError(
                "Sequence workloads must be a nested list, got list: "
                "%s -> %s" % (sequence, test_workloads[sequence]))
        for workload in workload_set:
            # workload would be None in empty sequence case - []
            if workload is None:
                continue
            if type(workload) is not str:
                raise AssertionError(
                    "Non string workload names are not supported: %s" %
                    workload)
            if workload not in test_workloads:
                if workload not in tds_workloads:
                    _missing_workloads.append(workload)
                    continue
                else:
                    test_workloads[workload] = tds_workloads[workload]
            if isinstance(test_workloads[workload], dict):
                # We are down to actual workload definition
                continue
            elif isinstance(test_workloads[workload], list):
                workload_list_id = workload
                if workload_list_id in _known_workload_lists:
                    raise AssertionError(
                        "Nested workload creates a loop: %s" %
                        " -> ".join(_known_workload_lists + [workload]))
                else:
                    _known_workload_lists.append(workload_list_id)
                resolve_custom_sequences(
                    tds_dict, test, workload,
                    _known_workload_lists=_known_workload_lists,
                    _missing_workloads=_missing_workloads)
                _known_workload_lists.remove(workload_list_id)
            else:
                raise AssertionError(
                    "Sequence workloads must be a nested list, got string: "
                    "%s -> %s" % (workload, test_workloads[workload]))
    return _missing_workloads


def is_a_test(test):
    if type(test) is dict:
        if VDNET_KEY_WORKLOADS in test:
            if VDNET_KEY_TESTNAME not in [x.lower() for x in test.keys()]:
                log.warn("Missing testname for test %s" % test)
            return True


def resolve_tds(tds_yaml, dst_dir, usertags, priority,
                assert_missing_workloads=True):
    """ Routine to resolve all vdnet specific notations
    in the given Tds yaml file.

    @type tds_yaml: string
    @param tds_yaml: Absolute path of YAML TDS file.
    @type dst_dir: string
    @param dst_dir: Destination directory for created of merged TDS file.
    @type usertags: csv string
    @param usertags: Filter by the tags field in TDS
    @type priority: string
    @param priority: Filter by the priority field in TDS
    @type assert_missing_workloads: boolean
    @param assert_missing_workloads: Asserts on missing workload definitions
    @rtype: dict
    @return: Resolved TDS.

    TDS sequences that result in a loop cause exception.
    >>> test_yaml = os.path.join(os.path.dirname(__file__), 'tests',
    ...                          'LoopedSequenceTds.yaml')
    >>> resolve_tds(test_yaml, TMP, None, None)
    Traceback (most recent call last):
        ...
    AssertionError: ... LoopEntry -> Node1 -> Node2 -> LoopEntry
    >>> test_yaml = os.path.join(os.path.dirname(__file__), 'tests',
    ...                          'BadWorkloadNameTds.yaml')
    >>> resolve_tds(test_yaml, TMP, None, None)
    Traceback (most recent call last):
        ...
    AssertionError: Non string workload ... {'badworkloadname': None}
    >>> test_yaml = os.path.join(os.path.dirname(__file__), 'tests',
    ...                          'BadSequenceTds.yaml')
    >>> resolve_tds(test_yaml, TMP, None, None)
    Traceback (most recent call last):
        ...
    AssertionError: ... non_nested_list_not_allowed_in_sequence -> ['w1']
    >>> test_yaml = os.path.join(os.path.dirname(__file__), 'tests',
    ...                          'BadSequence2Tds.yaml')
    >>> resolve_tds(test_yaml, TMP, None, None)
    Traceback (most recent call last):
        ...
    AssertionError: ... string_not_allowed_in_sequence -> w1
    """
    tds_dict = resolve_aliases_and_merges(tds_yaml, dst_dir)
    missing_workloads = get_missing_workloads(tds_dict)
    if missing_workloads and assert_missing_workloads:
        raise AssertionError(
            "%s: Following workloads are not defined:\n%s" %
            (tds_yaml, sorted(list(set(missing_workloads)))))
    return filter_by_tags_priority(tds_dict, usertags, priority)


def tdstotestid(tds_file, name):
    if os.path.exists(tds_file):
        parts = os.path.abspath(tds_file).split(os.sep)
        tds_path = ".".join(parts[parts.index('TDS')+1:])
        if tds.endswith('Tds.yaml'):
            tds_path = tds_path[:-len('Tds.yaml')]
    return tds_path + "." + name

if __name__ == '__main__':
    import argparse
    import doctest

    parser = argparse.ArgumentParser()
    parser.add_argument('--doctest', action='store_true', default=False)
    parser.add_argument('-t', '--tds', action='append', nargs='+',
                        help='List of tds yaml files to check')
    parser.add_argument('--print-missing-workloads', action='store_true',
                        default=False,
                        help='Print list of workloads with missing definition')
    parser.add_argument('--no-stdout', dest='stdout', action='store_false',
                        default=True,
                        help='Disable logging to stdout')
    parser.add_argument('--priority', dest='priority')
    parser.add_argument('--tags', dest='tags')
    parser.add_argument('-l', '--list', dest='list_tds_ids',
                        action='store_true', default=False,
                        help='Print out the tds ids only')
    args = parser.parse_args(sys.argv[1:])
    if args.doctest:
        doctest.testmod(optionflags=doctest.ELLIPSIS)
        sys.exit(0)
    else:
        configure_logging(TMP)
        if args.stdout:
            add_stdout_logging()
    tds_dicts = {}
    for lst in args.tds:
        for tds in lst:
            if not os.path.exists(tds):
                log.warn("Skipping unresolved tds param: %s" % tds)
                continue
            spec_check = (not args.print_missing_workloads and
                          not args.list_tds_ids)
            out = resolve_tds(
                tds, TMP, args.tags, args.priority,
                assert_missing_workloads=spec_check)
            tds_dicts[tds] = out

    tds_ids = []
    for tds, dct in tds_dicts.iteritems():
        if args.print_missing_workloads:
            print "%s: %s" % (tds, get_missing_workloads(dct))
        else:
            for test in dct:
                if args.list_tds_ids:
                    if is_a_test(dct[test]):
                        tds_ids.append(tdstotestid(tds, test))
            if not args.list_tds_ids and args.stdout:
                tds_yaml = yaml.dump(dct, default_flow_style=False,
                                     default_style=False, indent=4)
                log.info("Loaded TDS %s successfully:\n%s" %
                         (tds, tds_yaml))
    if args.list_tds_ids:
        for x in sorted(tds_ids):
            print x
