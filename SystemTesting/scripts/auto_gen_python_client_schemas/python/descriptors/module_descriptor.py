#!/usr/bin/env python2.6
#
# Copyright (C) 2011-2012 Nicira, Inc. All Rights Reserved.
#
# This software is provided only under the terms and conditions of a
# written license agreement with Nicira. If no such agreement applies
# to you, you are not authorized to use this software. Contact Nicira
# to obtain an appropriate license: www.nicira.com.

__all__ = ["ModuleDescriptor", "Module"]


import os
import types
import yaml

from descriptors import lg
from descriptors.descriptor import Descriptor
from descriptors.error import DescriptorException
from descriptors.type_descriptor import TypeDescriptor
from descriptors.rest_routine_descriptor \
    import RestRoutineDescriptor


ANY_VERSION = "_any_"

MODULE_SCHEMA_FILE = os.path.join(os.path.dirname(__file__),
                                  'module_descriptor.yml')
MODULE_SCHEMA = yaml.load(open(MODULE_SCHEMA_FILE))


class ModuleDescriptor(Descriptor):
    """Module meta information."""

    yaml_tag = u'!Module'

    spec_schema = MODULE_SCHEMA

    @classmethod
    def from_raw_spec(cls, raw_spec):
        params = dict([(k, v) for k, v in raw_spec.items() if k != 'id'])
        return cls(raw_spec['id'], **params)

    def __init__(self, id, description=None, revisions=None,
                 organization=None, contact=None, min_version=ANY_VERSION,
                 max_version=ANY_VERSION, snmp_oid=None):
        self.id = id
        self.description = description
        self.revisions = revisions
        self.organization = organization
        self.contact = contact
        self.min_version = str(min_version)
        self.max_version = str(max_version)
        self.snmp_oid = snmp_oid


class Module(object):
    """Bundle of interface descriptors with similar purpose and scope.
    """

    def __init__(self, module_file):
        """Initialize module from raw definition."""
        if isinstance(module_file, types.StringTypes):
            module_file = file(module_file, 'r')

        self.descriptors = {}
        self.meta = None
        module_min_version = None
        module_max_version = None
        self.components = []

        for component in self.load_descriptors(module_file):
            self.components.append(component)
            for descriptor in component['descriptors']:
                if isinstance(descriptor, ModuleDescriptor) and self.meta is None:
                    self.meta = descriptor
                    module_min_version = descriptor.min_version
                    module_max_version = descriptor.max_version
                elif descriptor.id in self.descriptors:
                    # each module should have unique descriptor names
                    # uniqueness across modules (in imports) can be
                    # enforced using the 'prefix' import option
                    err = ("Descriptor '%s' in module '%s' declared multiple "
                           "times" % (descriptor.id, module_file.name))
                    raise DescriptorException(err)
                else:
                    if isinstance(descriptor, ModuleDescriptor):
                        module_min_version = descriptor.min_version
                        module_max_version = descriptor.max_version
                    elif isinstance(descriptor, RestRoutineDescriptor):
                        descriptor.module_min_version = module_min_version
                        descriptor.module_max_version = module_max_version
                    self.descriptors[descriptor.id] = descriptor

        if self.meta is None:
            self.meta = ModuleDescriptor(id=module_file.name)
        self.id = self.meta.id


    def load_descriptors(self, module_file):
        base_path = os.path.dirname(module_file.name)
        components = []
        for mlist in yaml.load_all(module_file):
            # doc may contain a single descriptor, or a list of descriptors
            if not isinstance(mlist, list):
                mlist = [mlist]
            for mod in mlist:
                component = {}
                component["import_block"] = mod
                mod = [mod]
                component["descriptors"] = Descriptor.evaluate_markup(mod, False, base_path)
                components.append(component)

        for component in components:
            for descriptor in component['descriptors']:
                lg.debug("loaded descriptor %s from module %s"
                         %(descriptor, module_file.name))
            lg.debug("module %s parsed succesfully. %d descriptors loaded"
                 %(module_file.name, len(component['descriptors'])))
        return components


