#!/usr/bin/env python2.6
#
# Copyright (C) 2011-2012 Nicira, Inc.
#
# This is an unpublished work, is confidential and proprietary to
# Nicira, Inc. as a trade secret and is not to be used or
# disclosed without Nicira's consent.

import argparse
from copy import copy
import logging
import re
import sys
import traceback
import types
import yaml

from descriptors import lg
from descriptors.descriptor import Descriptor
from descriptors.error import DescriptorException
from descriptors.module_descriptor import ANY_VERSION
from descriptors.module_descriptor import Module
from descriptors.module_descriptor import ModuleDescriptor
from descriptors.rest_routine_descriptor import \
    RestRoutineDescriptor
from descriptors.type_descriptor import TypeDescriptor
from descriptors.system_state_manager_descriptor import \
    SystemStateManagerDescriptor


__all__ = ["Module", "DescriptorFactory"]


class SystemStateManagerDescriptorDirectory(object):
    def __init__(self):
        """Initialize the SystemStateManagerDescriptorDirectory."""
        self._system_state_manager_descriptors = {}

    def add(self, system_state_manager_desc):
        key = system_state_manager_desc.config_path_schema
        if (key in self._system_state_manager_descriptors.keys()):
            raise DescriptorException(
                "Failed to add SystemStateManagerDescriptor: %s. "
                "Cannot have multiple SystemStateManagerDescriptors's "
                "serving the same path" % system_state_manager_desc.id)
        self._system_state_manager_descriptors[key] = (
            system_state_manager_desc)
        lg.debug("Added SystemStateManagerDescriptor: %s for path: %s" %
                 (system_state_manager_desc.id,
                  key))

    def get_manager_for_path(self, config_path):
        for ssmd in self._system_state_manager_descriptors.values():
            if ssmd.match_path(config_path):
                return ssmd.get_provider_instance(config_path)

    def get_all_descriptors(self):
        return self._system_state_manager_descriptors.values()


class DescriptorFactory(object):
    def __init__(self, module_files, settings_file=None):
        """Initialize module from raw definition."""
        self._modules = {}      # key=module.id, val=Module
        self._descriptors = {}  # key=descriptor.id, val=Descriptor
        self._routines = {}     # key=(method, version), val=[RoutineDescriptor]
        self._types = {}        # key=descriptor.id, val=TypeDescriptor
        self.components = []    # List of types, rest routines in one import file
        self._system_state_manager_directory = (
            SystemStateManagerDescriptorDirectory())

        if settings_file:
            if isinstance(settings_file, types.StringTypes):
                settings_file = file(settings_file, 'r')
            # else it should be a file-like object
            Descriptor.settings = yaml.load(settings_file)

        if not isinstance(module_files, (types.ListType, types.TupleType)):
            module_files = [module_files]
        versions = [str(x) for x in Descriptor.settings.get("ALL_VERSIONS", [])]
        if ANY_VERSION not in versions:
            versions.append(ANY_VERSION)
        for module_file in module_files:
            module = Module(module_file)
            if module.meta.id in self._modules:
                err = "Module '%s' imported multiple times" % module.meta.id
                raise DescriptorException(err)
            # verify module min/max_version make sense, ignore module if:
            # 1. both min/max_version not (e.g. no longer) in supported versions
            # raise exception if:
            # 2. both min/max in supported versions, but min pos > max pos
            # 3. min_version in supported versions but max_version not.
            min_version = module.meta.min_version
            max_version = module.meta.max_version
            # case 1
            if min_version not in versions and max_version not in versions:
                continue
            # case 2
            elif (min_version in versions and max_version in versions and
                  versions.index(min_version) > versions.index(max_version)):
                err = ("Module '%s' specifies a min_version that is greater "
                       "than max_version"  % module.meta.id)
                raise DescriptorException(err)
            # case 3
            elif min_version in versions and max_version not in versions:
                err = ("Module '%s' specifies an invalid max_version" %
                       module.meta.id)
                raise DescriptorException(err)
            self._modules[module.meta.id] = module
            self._descriptors.update(module.descriptors)
            for _id, descriptor in self._descriptors.iteritems():
                self._add_routine(descriptor)
                self._add_system_state_manager_desc(descriptor)
            for component in module.components:
                self._add_component(component)


        # Tag each descriptor with the factory that constructed it
        # and map type_ids to TypeDescriptors
        for descriptor in self._descriptors.values():
            descriptor.descriptor_factory = self
            if isinstance(descriptor, TypeDescriptor):
                self._types[descriptor.meta_spec["id"]] = descriptor

    @property
    def modules(self):
        return self._modules

    @property
    def descriptors(self):
        return self._descriptors

    @property
    def routines(self):
        return self._routines

    def get_type(self, typename):
        return self._types.get(typename)

    def get_routine_stats(self):
        """Get routine statistics.

        Returns:
             List of tuples: (method, versions, path, call_count, time_spent)
        """
        stats = []
        for descriptor in self._descriptors.itervalues():
            if not isinstance(descriptor, RestRoutineDescriptor):
                continue
            stat = (descriptor.method, descriptor.supported_versions,
                    descriptor.path, descriptor.call_count,
                    descriptor.time_spent)
            stats.append(stat)
        return stats

    def get_routine_from_id(self, routine_id):
        """Return the RestRoutineDescriptor registered for the id.

        Returns:
            A RestRoutineDescriptor instance or None if no matching routine.
        """
        routine = self._descriptors.get(routine_id)
        if not isinstance(routine, RestRoutineDescriptor):
            routine = None
        return routine

    def get_routine(self, method, version, path):
        """Return the RestRoutineDescriptor registered for the request.

        Returns:
            A RestRoutineDescriptor instance or None if no matching routine.
        """
        routines = self._routines.get((method, version))
        if not routines:
            return None
        for r in routines:
            if r.match_path(path):
                return r
        return None

    def get_all_write_routines(self):
        """Return all write RestRoutineDescriptors

        Returns:
            A list of RestRoutineDescriptors or [] if none exist
        """
        routines = []

        for ((method, version), value) in self._routines.items():
            if method not in ["POST", "PUT", "DELETE"]:
                continue
            routines += value
        return routines

    def get_path_routines(self, version, path):
        """Return the RestRoutineDescriptors directly under path.

        Args:
            version: version of RestRoutineDescriptor.
            path: path of RestRoutineDescriptors, must end with "/".

        Return:
            List of RestRoutineDescriptors and strings denoting a "directory";
            otherwise, an emtpy list.  RestRoutineDescriptors, if any, are
            always listed before directories.
        """
        result = []
        if path[-1] != "/":
            return result
        path_re = re.compile("^%s[^\/]*$" % path)
        subdir_re = re.compile("^%s([^\/]*)/.*$" % path)
        subdirs = {}
        for method in ["POST", "GET", "PUT", "DELETE"]:
            for r in self._routines.get((method, version), []):
                if path_re.match(r.path):
                    result.append(r)
                else:
                    m = subdir_re.match(r.path)
                    if m:
                        subdirs[m.group(1)] = True
        for subdir_name in subdirs.keys():
            result.append(subdir_name)
        return result

    def _add_routine(self, descriptor):
        if not isinstance(descriptor, RestRoutineDescriptor):
            return
        versions = [str(x) for x in Descriptor.settings.get("ALL_VERSIONS", [])]
        start_index = 0
        if descriptor.module_min_version in versions:
            start_index = versions.index(descriptor.module_min_version)
        for ver in versions[start_index:]:
            key = (descriptor.method, ver)
            if key not in self._routines:
                self._routines[(descriptor.method, ver)] = []
            self._routines[(descriptor.method, ver)].append(descriptor)
            descriptor.supported_versions.append(ver)
            if ver == descriptor.module_max_version:
                break

    def _add_component(self, component):
        self.components.append(component)

    def _add_system_state_manager_desc(self, descriptor):
        if not isinstance(descriptor, SystemStateManagerDescriptor):
            return
        self._system_state_manager_directory.add(descriptor)

    def get_system_state_manager(self, path):
        return (self._system_state_manager_directory.
                    get_manager_for_path(path))

    def get_system_state_manager_descriptors(self):
        return (self._system_state_manager_directory.
                    get_all_descriptors())


def main(argv):
    parser = argparse.ArgumentParser(
        description="Load and validate descriptors.")
    parser.add_argument("-m", "--module", required=True,
                        nargs="*", action="append",
                        help="module file(s) to load (may be repeated)")
    parser.add_argument("-s", "--settings", default="settings.yml",
                        help="settings file name or '-' for no settings"
                             "(default: %(default)s)")
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="verbose output")
    args = parser.parse_args()

    modules = []
    for module in args.module:
        # flatten arguments if multiple were provided per flag
        modules += module if hasattr(module, '__iter__') else [module]

    settings = args.settings if args.settings != '-' else None

    fmt="%(asctime)s %(name)s %(levelname)s %(message)s"
    logging.basicConfig(stream=sys.stdout, format=fmt)
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    else:
        logging.getLogger().setLevel(logging.INFO)

    try:
        descriptor_factory = DescriptorFactory(modules, settings)
    except Exception, e:
        print "Failed to load descriptors:"
        print "\n".join(["  %s" % l for l in e.__unicode__().splitlines()])
        traceback.print_exc(file=sys.stdout)
        return 1

    count = len(descriptor_factory.modules)
    print "%d module%s parsed successfully:" %(count, "" if count ==1 else "s")
    for module_id, module in sorted(descriptor_factory.modules.items()):
        print "  %s (%d descriptors):" % (module.meta.id,
                                          len(module.descriptors))
        for descriptor in module.descriptors.values():
            print "    %s" % descriptor


if __name__ == '__main__':
    main(sys.argv)
