#!/usr/bin/python2.6
#
# Copyright (C) 2011 Nicira, Inc.
#
# This is an unpublished work, is confidential and proprietary to
# Nicira, Inc. as a trade secret and is not to be used or
# disclosed without Nicira's consent.

__all__ = ["Descriptor"]


#from mako.template import Template
import os
import re
import types
import yaml

from lib.json_schema import JsonSchema
from descriptors import lg
from descriptors.error import DescriptorException


SCHEMA_REGISTRY = {}


class Descriptor(yaml.YAMLObject):
    """Descriptor specification using YAML with conditional and import support.

    This class is meant to serve as a base class for descriptors that have a
    common need for parsing conditional and import markup in YAML
    definitions.

    Attributes:
        yaml_tag (static): The YAML tag identifying this descriptor type.
        spec_schema (static): JSON schema instance used to validate raw
            descriptor spec.
        settings (static): Settings object to use when evaluating
            descriptor conditionals.
    """
    yaml_tag = u'!Descriptor'
    spec_schema = JsonSchema({})
    settings = {}

    @classmethod
    def from_yaml(cls, loader, node):
        m = loader.construct_mapping(node, deep=True)
        raw_spec = Descriptor.evaluate_markup(m, in_descriptor=True)
        is_valid, msg = cls.spec_schema.validate(raw_spec)
        if not is_valid:
            raise DescriptorException("Descriptor validation failed: %s" % msg)
        return cls.from_raw_spec(raw_spec)

    @classmethod
    def from_raw_spec(cls, raw_spec):
        if 'id' not in raw_spec:
            raise DescriptorException("Descriptor missing required 'id' attribute")
        return cls(raw_spec['id'], raw_spec)

    def __init__(self, id, raw_spec):
        super(Descriptor, self).__init__()
        self.id = id
        self.raw_spec = raw_spec

    def __unicode__(self):
        return "%s(id=%s)" %(self.__class__.__name__, self.id)

    def __str__(self):
        return self.__unicode__().encode('utf-8')

    @staticmethod
    def evaluate_markup(node, in_descriptor=False, import_base_path="."):
        """Return copy of node with all markup evaluated.

        Args:
            node: The python node to check for markup.
            in_descriptor: True if the node is within a Descriptor definition.
            import_base_path: The path to look for import files.
        """
        def _is_conditional(node):
            # relying on duck typing because isinstance thinks
            # that descriptor.descriptor._ConditionalBlock
            # != descriptor._ConditionalBlock <sigh>
            return hasattr(node, "evaluate_conditional_cases")

        def _is_import(node):
            return hasattr(node, "import_file")

        def _eval_to_list(node):
            ret = []
            if (type(node) == types.DictType and len(node) == 1 and
                _is_conditional(node.keys()[0])):
                k, v = node.items()[0]
                evaluated = k.evaluate_conditional_cases(v) or []
                # recurse to catch embedded imports
                ret.extend(Descriptor.evaluate_markup(
                    evaluated, import_base_path=import_base_path))
            elif type(node) == types.DictType or type(node) == types.ListType:
                ret.append(Descriptor.evaluate_markup(
                    node, import_base_path=import_base_path))
            elif _is_import(node):
                #if in_descriptor:
                #    raise DescriptorException(
                #        "imports may not be done inside a descriptor")
                ret.extend(node.import_file(import_base_path))
            else:
                ret.append(node)
            return ret

        def _eval_to_dict(node):
            ret = {}
            for k, v in node.iteritems():
                if _is_conditional(k):
                    ret.update(Descriptor.evaluate_markup(
                        k.evaluate_conditional_cases(v),
                        import_base_path=import_base_path) or {})
                else:
                    if isinstance(v, types.ListType):
                        ret[k] = Descriptor.evaluate_markup(
                            v, import_base_path=import_base_path)
                    elif isinstance(v, types.DictType):
                        ret[k] = _eval_to_dict(v)
                    else:
                        ret[k] = v
            return ret

        ntype = type(node)
        if ntype == types.ListType:
            ret = []
            for item in node:
                ret.extend(_eval_to_list(item))
        elif ntype == types.DictType:
            ret = _eval_to_dict(node)
        else:
            raise DescriptorException(
                "expected list or dict, but found %s" % ntype)

        return ret


class _ConditionalBlock(yaml.YAMLObject):
    """Representation of conditional metadata in Decriptor specification.

    Conditionals are represented using a '!SWITCH' YAML tag containing a
    Mako template which may reference a 'settings' variable.  The tag
    must be followed by a dict of case values.  The default case is
    hard-coded to the string "__default__".

    Example:
      !SWITCH '${settings["version"]}':
        "1.0":
          str_property: property_value_to_set
        "2.0":
          int_property: 123
          other_property_to_set: someval
        "__default__":
          str_property: foo
    """

    yaml_tag = u'!SWITCH'

    DEFAULT_VALUE = "__default__"

    @classmethod
    def from_yaml(cls, unused_loader, node):
        return cls(node.value)

    def __init__(self, condition):
        super(_ConditionalBlock, self).__init__()

        self.condition = condition
        #try:
        #    self.value = Template(condition).render(
        #        settings=Descriptor.settings)
        #except Exception, e:
        #    raise DescriptorException("Failed to evaluate conditional '%s': %s"
        #                              %(condition, e))
        if self.value == _ConditionalBlock.DEFAULT_VALUE:
            # YAML limits our choices for naming the default branch.
            # We choose a value we feel is most "readable", and catch
            # potential collisions at runtime.
            # Since conditional inputs (settings) are only provided by
            # developers, conflicts should be easy to spot during development.
            raise DescriptorException(
                "conditional evaluates to invalid value '%s'"
                % _ConditionalBlock.DEFAULT_VALUE)

    def __unicode__(self):
        cstr = self.condition
        if len(cstr) > 30:
            cstr = cstr[:27] + "..."
        return u"%s(condition=%s, value=%s)" %(self.yaml_tag, cstr, self.value)

    def __str__(self):
        return self.__unicode__().encode('utf-8')

    def evaluate_conditional_cases(self, cases):
        if cases is None:
            raise DescriptorException(
                "No cases provided for %s (missing indent?)"
                % _ConditionalBlock.yaml_tag)
        if not isinstance(cases, dict):
            raise DescriptorException(
                "%s requires cases specified as a mapping"
                % _ConditionalBlock.yaml_tag)
        for case in cases:
            if not isinstance(case, types.StringTypes):
                raise DescriptorException(
                    "Case types may only be strings, but found %s"
                    % type(case))

        if self.value in cases:
            lg.debug("applying branch '%s' of conditional %s"
                     %(self.value, self))
            match = cases[self.value]
        elif _ConditionalBlock.DEFAULT_VALUE in cases:
            lg.debug("applying branch '%s' of conditional %s"
                     %(_ConditionalBlock.DEFAULT_VALUE, self))
            match = cases[_ConditionalBlock.DEFAULT_VALUE]
        else:
            raise DescriptorException(
               "no matching branch or %s of conditional %s"
               %(_ConditionalBlock.DEFAULT_VALUE, self))

        return match


class _ImportBlock(yaml.YAMLObject):
    """Representation of import metadata in Decriptor specification.

    Imports are represented using an '!IMPORT' YAML tag containing a
    parameter set surrounded by angle brackets.  The following
    parameters are allowed:
      file (required): The file name (including relative path) to import.
      prefix (optional): If provided, all imported descriptors will have an
          ID of the form <prefix>.<imported_descriptor_id>.  If not provided,
          IDs will be imported unchanged.

    Example:
      !IMPORT <file=descriptor_base.yml, prefix=base>
    """
    yaml_tag = u'!IMPORT'

    @classmethod
    def from_yaml(cls, unused_loader, node):
        return cls(node.value.strip())

    def __init__(self, import_spec):
        super(_ImportBlock, self).__init__()

        self.import_spec = import_spec

        if import_spec.startswith("<") and import_spec.endswith(">"):
            import_spec = import_spec[1:-1].strip()
        param_pairs = [p for p in re.split(r", *", import_spec, 1) if p]
        pdict = dict([p.split("=", 1) for p in param_pairs])

        if not 'file' in pdict:
            raise DescriptorException("Missing required 'file' parameter in %s"
                                 %self.yaml_tag)
        if set(pdict.keys()) - set(["file", "prefix"]):
            raise DescriptorException("Invalid parameter in %s" %self.yaml_tag)

        self.fname = pdict['file']
        self.prefix = pdict.get('prefix')

    def __unicode__(self):
        return u"%s(file=%s, prefix=%s)" %(self.yaml_tag, self.fname,
                                           self.prefix)

    def __str__(self):
        return self.__unicode__().encode('utf-8')

    def import_file(self, import_base_path):
        ret = []
        if self.fname.startswith(os.sep):
            import_fpath = self.fname
        else:
            import_fpath = os.path.join(import_base_path, self.fname)
        with open(import_fpath, "r") as f:
            for mlist in yaml.load_all(f):
                # doc may contain a single descriptor, or a list of descriptors
                if not isinstance(mlist, list):
                    mlist = [mlist]
                ret.extend(Descriptor.evaluate_markup(
                    mlist, import_base_path=os.path.dirname(import_fpath)))

        for descriptor in ret:
            if self.prefix:
                descriptor.id = "%s.%s" %(self.prefix, descriptor.id)
            lg.debug("imported descriptor %s from module %s"
                     %(descriptor, import_fpath))
        lg.debug("imported module %s parsed succesfully. %d descriptors loaded"
                 %(import_fpath, len(ret)))
        return ret
