#!/usr/bin/python2.6
#
# Copyright (C) 2011-2012 Nicira, Inc.
#
# This is an unpublished work, is confidential and proprietary to
# Nicira, Inc. as a trade secret and is not to be used or
# disclosed without Nicira's consent.

__all__ = ["SystemStateManagerDescriptor"]


import os
import re
import time
import yaml

from lib.json_schema import JsonSchema
from descriptors.descriptor import Descriptor
from descriptors.descriptor import SCHEMA_REGISTRY
from descriptors.rest_routine_descriptor import PathArgument
from descriptors.rest_routine_descriptor \
    import REST_ROUTINE_AUTO_RELOAD_KEY


SYSTEM_STATE_MANAGER_SCHEMA_FILE = (
    os.path.join(os.path.dirname(__file__),
                 'system_state_manager_descriptor.yml'))


SYSTEM_STATE_MANAGER_TYPES = (
    dict((r.id, r) for r in yaml.load(
          open(SYSTEM_STATE_MANAGER_SCHEMA_FILE))))


SYSTEM_STATE_MANAGER_RAW_SCHEMA = (
    SYSTEM_STATE_MANAGER_TYPES['SystemStateManager'].raw_schema)


SYSTEM_STATE_MANAGER_SCHEMA = JsonSchema(
    SYSTEM_STATE_MANAGER_RAW_SCHEMA, strict=True,
    type_path=["SystemStateManager"], schema_registry=SCHEMA_REGISTRY)


class _PythonProvider(object):
    def __init__(self, module, class_name):
        self.module = module
        self.module_obj = None
        self.class_name = class_name

    # XXX Code adapted from:
    # rest_routine_descriptor._PythonProvider.resolve_handler
    def get_instance(self, config_path, config_path_args):
        """Constructs and returns an instance of the class
        represented by the provider.

        Args:
            config_path: The configuration path to construct the instance
                         with.
            config_path_args: The configuration path arguments to construct
                              the instance with.

        Returns:
            Constructed instance of an instance represented by the
            provider.
        """
        cls = self.get_class()
        assert cls, ("Unable to resolve class(%s.%s)" %
                      (self.module, self.class_name))
        return (cls(config_path, config_path_args))

    def get_class(self):
        """Returns the class represented by the python provider.

        Returns:
            Class represented by the python provider.
        """
        if self.module_obj is None:
            module_name = self.module.split(".")[-1]
            self.module_obj = __import__(self.module, globals(), locals(),
                                         [module_name])
            self.import_time = time.time()
        elif os.environ.get(REST_ROUTINE_AUTO_RELOAD_KEY, "") == "TRUE":
            source_file = re.sub("py.$", "py", self.module_obj.__file__)
            if os.stat(source_file).st_mtime > self.import_time:
                reload(self.module_obj)
                self.import_time = time.time()
        return getattr(self.module_obj, self.class_name)


class _ProtobufRpcProvider(object):
    def __init__(self, service, class_name):
        raise Exception("Not implemented yet")


class SystemStateManagerDescriptor(Descriptor):
    """Descriptor specification of a system state manager.

    This class provides a class for representing system state managers
    defined in YAML Descriptor format.
    """

    yaml_tag = u'!SystemStateManager'
    spec_schema = SYSTEM_STATE_MANAGER_SCHEMA

    @classmethod
    def from_raw_spec(cls, raw_spec):
        config_path_arguments = [
            PathArgument(**p)
            for p in raw_spec.get('config_path_arguments', [])]
        return cls(raw_spec['id'], raw_spec['config_path'],
                   config_path_arguments, raw_spec['provider'])

    def __init__(self, id, config_path, config_path_arguments, provider):
        self.id = id
        self.config_path_schema = config_path
        self.config_path_arguments_schema = config_path_arguments
        self.provider = self.resolve_provider(**provider)
        self._path_re = self._resolve_path_re()

    def resolve_provider(self, type, **kwargs):
        if type == 'local_python':
            return _PythonProvider(**kwargs)
        elif type == 'protobuf_rpc':
            return _ProtobufRpcProvider(**kwargs)
        else:
            raise TypeError("Unknown provider type: '%s'" % type)

    def get_provider_instance(self, config_path):
        """Returns an instance of the class represented by the descriptor.

        Args:
            config_path: The configuration path to construct the
                         SystemStateManager instance with.

        Returns:
            An instance of the class represented by the descriptor.
        """
        config_path_args = self.get_path_args(config_path)
        return self.provider.get_instance(config_path, config_path_args)

    def get_provider_class(self):
        """Returns the SystemStateManager class represented by the descriptor.

        Returns:
            The SystemStateManager class represented by the descriptor.
        """
        return self.provider.get_class()

    def generate_path(self, path_args):
        """Generates a path from the config path schema given a
        dictionary of path args.

        Args:
            path_args: dictionary of path arguments

        Returns:
            Generated path from the config path schema and path arguments
        """
        path = str(self.config_path_schema)
        for k, v in path_args.items():
            sub = "<%s>" % k
            path = path.replace(sub, v)
        return path

    # XXX _resolve_path_re, match_path, and get_path_args are
    # taken from rest_routine_descriptor.py
    def _resolve_path_re(self):
        pattern = "^%s$" % self.config_path_schema
        for arg in self.config_path_arguments_schema:
            assert pattern.find("<%s>" % arg.name) != -1, \
                "SystemStateManagerDescriptor path missing required path argument"
            # Regex group names have to be valid Python identifiers, since REST
            # and the control API uses dashes we substitute with underscores.
            # We'll have to account for the substitution when extracting the
            # groups from match objects
            _name = arg.name.replace("-", "_")
            _arg_pattern = arg.pattern
            if _arg_pattern.startswith("^"):
                _arg_pattern = _arg_pattern[1:]
            if _arg_pattern.endswith("$"):
                _arg_pattern = _arg_pattern[:-1]
            pattern = pattern.replace("<%s>" % arg.name,
                                      "(?P<%s>%s)" % (_name, _arg_pattern))
        return re.compile(pattern)

    def match_path(self, path):
        """Determine if specified path matches SystemStateManager's path.

        Args:
            path: Path to match.

        Returns:
            True if specified path matches SystemStateManager's path.
            False if not.
        """
        result = {}
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
            for arg in self.config_path_arguments_schema:
                group_name = arg.name.replace("-", "_")
                result[arg.name] = m.group(group_name)
        return result


