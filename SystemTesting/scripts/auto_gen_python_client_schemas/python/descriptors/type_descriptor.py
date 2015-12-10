#!/usr/bin/python2.6
#
# Copyright (C) 2011 Nicira, Inc.
#
# This is an unpublished work, is confidential and proprietary to
# Nicira, Inc. as a trade secret and is not to be used or
# disclosed without Nicira's consent.

__all__ = ["TypeDescriptor", "TYPE_SCHEMA"]


import os
import yaml

from lib.json_schema import JsonSchema
from descriptors.descriptor import Descriptor
from descriptors.descriptor import SCHEMA_REGISTRY


JSON_META_RAW_SCHEMA = yaml.load(open(JsonSchema.META_SCHEMA_PATH, 'r').read())
JSON_META_SCHEMA = JsonSchema(
    JSON_META_RAW_SCHEMA, strict=True,
    type_path=["http://json-schema.org/draft-03/schema#"],
    schema_registry=SCHEMA_REGISTRY)

TYPE_SCHEMA_FILE = os.path.join(os.path.dirname(__file__),
                                  'type_descriptor.yml')
TYPE_RAW_SCHEMA = yaml.load(open(TYPE_SCHEMA_FILE)).raw_spec
TYPE_SCHEMA = JsonSchema(TYPE_RAW_SCHEMA, schema_registry=SCHEMA_REGISTRY,
                         type_path=["Type"], strict=True)


class TypeDescriptor(Descriptor):
    """Descriptor specification of a data type.

    This class provides a class for representing data types defined by
    a JsonSchema in YAML Descriptor format.
    """

    yaml_tag = u'!Type'

    spec_schema = TYPE_SCHEMA

    def __init__(self, id, schema_spec):
        super(TypeDescriptor, self).__init__(id, schema_spec)
        self._schema = JsonSchema(schema_spec, strict=True,
                                  schema_registry=SCHEMA_REGISTRY,
                                  type_path=['#', id])

    @property
    def raw_schema(self):
        return self._schema.raw_schema()

    @property
    def meta_spec(self):
        return self._schema.raw_schema()

    def validate(self, data):
        """Validate that data conforms to the type schema.

        Returns:
            A tuple of (validates_boolean, reason_string):
                validates_boolean: True iff data successfully validates
                    against type.
                reason_string: Descriptive text describing the validation
                    error, if any.
        """
        return self._schema.validate(data)

