#!/usr/bin/python
# Copyright (C) 2010 Nicira, Inc.
#
# This is an unpublished work, is confidential and proprietary to
# Nicira, Inc. as a trade secret and is not to be used or
# disclosed without Nicira's consent.
#

import copy
import os
import re
import sys
import types

import simplejson


class SchemaException(Exception):
  pass


class _BaseJsonSchema(object):
  def __init__(self, name="Unnamed schema"):
    self._name = name
    self._type = "any"
    self._has_default = False
    self._schema = {}

  def validate(self, unused_data, unused_id_, unused_crud_op,
               unused_checked_types):
    # JSON Schema behavior is allow by default
    return (True, "success")

  def raw_schema(self):
    """Return schema definition dict.
    """
    return {}

  @property
  def schema_type(self):
    return self._type

  @property
  def schema_name(self):
    return self._name


class JsonSchema(_BaseJsonSchema):
  """A JSON Schema (Revision 3) validator

  Validates JSON data against the provided schema.

  Much, but not all, of the core specified in draft-zyp-json-schema-03 is
  supported.

  Unsupported features include:
    additionalItems
    patternProperties
  """

  META_SCHEMA_PATH = os.path.join(os.path.dirname(__file__),
                                  'json-schema.org_draft-03_schema.json')

  _uuid_re = re.compile("^[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}"
                        "-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}$")

  _json_to_python_types = {
    "string": set(types.StringTypes),
    "number": set([types.IntType, types.LongType, types.FloatType]),
    "integer": set([types.IntType, types.LongType]),
    "unsigned_integer": set([types.IntType, types.LongType]),
    "boolean": set([types.BooleanType]),
    "object": set([types.DictType]),
    "array": set([types.ListType, types.TupleType]),
    "null": set([types.NoneType]),
    "any": set([None])
  }

  @classmethod
  def _sanitize_schema(cls, schema):
    def _schema_dict_from_string(schema_str):
      if schema_str in cls._json_to_python_types:
        # "simple type definition"
        return {"type": schema_str}
      else:
        # interpret as schema passed as a string
        return simplejson.loads(schema_str)

    if type(schema) in types.StringTypes:
      ret = _schema_dict_from_string(schema)
    else:
      ret = copy.deepcopy(schema)

    if type(ret) in [types.ListType, types.TupleType]:
      # treat schema list as union
      ret = {"type": ret}
    elif type(ret) != types.DictType:
      raise TypeError("Invalid schema type %s" % str(type(ret)))
    return ret

  def __init__(self, schema, strict=False, schema_registry=None,
               type_path=None):
    """Initialize schema from raw definition

    Attributes:
        schema: a raw schema in string or dict form
        strict: if True, don't blindly validate unresolved references
        schema_registry: A dict of type_id:Schema mappings.  Optionally
            specified to support aggregation of interdependent schemas
            from multiple sources.
        type_path: A list of fragment identifiers identifying schema
            ancestry, or None for ['#']

    Raises:
        TypeError: The schema definition is invalid
    """
    _BaseJsonSchema.__init__(self)
    self._schema = self._sanitize_schema(schema)
    self._strict = strict
    self._type_path = (type_path or ['#'])[:]
    if not hasattr(self._type_path, "__iter__"):
        self._type_path = [self._type_path]
    self._path_str = '.'.join(self._type_path)
    if schema_registry is not None:
        self._schema_registry = schema_registry
    else:
        self._schema_registry = {}
    self._schema_registry[self.path] = self
    self._id = self._schema.get("id", "")
    if self._id:
      self._schema_registry[self._id] = self
      self._name = self._id
    else:
      parent_type_path = '.'.join(self._type_path[:-1])
      ptp_schema = self._schema_registry.get(parent_type_path)
      if ptp_schema:
        self._name = "%s.%s" %(ptp_schema.schema_name, self._type_path[-1])
      else:
        self._name = self.path
    self._title = self._schema.get("title", "")
    self._description = self._schema.get("description", "")
    self._has_default = "default" in self._schema
    self.default = self._schema.get("default", None)

    #
    # Initialize checks performed by this schema
    #
    self._checks = []  # Default schema accepts everything

    if "extends" in self._schema:
      def _check_extends_loop(schema, _traversed=None):
        # Loops in extends relations not only do not make sense, they
        # would result in an unbounded loop at property validation time.
        _traversed = _traversed or set([schema])
        s = self.get_type(schema)
        if isinstance(s, JsonSchema):
          if s._extends_validator_path is None:
            return
          if (s._extends_validator_path in _traversed):
            raise TypeError("Schema 'extends' cycle detected: %s %s"
                            % (s._extends_validator_path, _traversed))
          _traversed.add(s._extends_validator_path)
          return _check_extends_loop(s._extends_validator_path, _traversed)

      # RFC: "any instance that is valid according to the current schema
      # must be valid according to the referenced schema"
      if type(self._schema["extends"]) != types.DictType:
        raise TypeError("extends must be a schema")
      ev = self._init_child_schema(self._schema["extends"], "$extends")
      self._extends_validator_path = ev.path
      self._schema_registry[ev.path] = ev
      _check_extends_loop(self._extends_validator_path)
      self._checks.append(self._check_extends)
    else:
      self._extends_validator_path = None

    self._type = self._schema.get("type", "any")

    if "enum" in self._schema:
      if type(self._schema["enum"]) not in self._json_to_python_types["array"]:
        raise TypeError("enum value must be an array")
      # optimization using sets would require special case dicts and arrays
      self._enumvals = self._schema["enum"]
      self._checks.append(self._check_enum)

    if "format" in self._schema:
      if self._schema["format"] == "uuid" and self._type == "string":
        # custom format not defined in RFC - entity must be an RFC 4122
        # UUID in string form
        self._checks.append(self._check_format_uuid)

    if "additionalProperties" in self._schema:
      self._additional_properties = self._schema["additionalProperties"]
      # style says never compare boolean to False - silence pychecker
      if (isinstance(self._additional_properties, bool) and
          not self._additional_properties):
        ap_schema = _NoAdditionalPropertiesSchema(self._name, self._type_path)
      elif type(self._additional_properties) == types.DictType:
        ap_schema = self._init_child_schema(self._additional_properties,
                                            "$additionalProperties")
      else:
        raise TypeError("additionalProperties must be schema or False")
      self._ap_schema_path = ap_schema.path
      self._schema_registry[ap_schema.path] = ap_schema
    elif self._extends_validator_path is not None:
      self._ap_schema_path = "%s.%s" % (self._extends_validator_path,
                                        "$additionalProperties")
    else:
      ap_schema = _AnyAdditionalPropertiesSchema(self._name)
      self._ap_schema_path = ap_schema.path
      self._schema_registry[ap_schema.path] = ap_schema

    # Checks specific to each type
    if isinstance(self._type, (types.ListType, types.TupleType)):
      self._init_union(self._schema)
    elif isinstance(self._type, types.DictType):
      v = self._init_child_schema(self._type, '$typeref')
      self._union_schemas = [v]
      self._checks.append(self._check_union)
    else:
      # primitive type
      init_method_name = "_init_%s" % self._type
      if (not hasattr(self, init_method_name) or
          type(getattr(self, init_method_name)) != types.MethodType):
        # The RFC requires that we should treat this as "any",
        # such that we can validate more complex schema extensions.
        # We optionally break this requirement, as it is sometimes
        # convenient to be more strict (e.g. for finding typos in schemas).
        if self._strict:
          raise TypeError("unsupported schema type '%s'" % self._type)
      else:
        init_method = getattr(self, init_method_name)
        init_method(self._schema)

  def __str__(self):
    return "JsonSchema(%s)" % self.path

  def validate(self, data, id_="<root>", crud_op=None, _checked_types=None):
    """Check if data is valid according to this schema.

    Args:
      data: A JSON data object to be validated.
      crud_op: the operational context for the validation; one of:
        None: use default context
        create: use 'create' context if specified in schema, else use default
        read: use 'read' context if specified in schema, else use default
        update: use 'update' context if specified in schema, else use default
        delete: use 'delete' context if specified in schema, else use default

    Returns:
      A tuple of (validates_boolean, reason_string):
        validates_boolean: True iff data successfully validates against schema.
        reason_string: Descriptive text describing the validation error, if any.

    Raises:
      TypeError: Data is not a valid JSON object
      SchemaException: Unresolved ref encountered when 'strict' mode enabled
    """
    self._crud_op = crud_op
    self._checked_types = _checked_types or set()
    if self.path in self._checked_types:
      return (True, "success")
    else:
      self._checked_types.add(self.path)

    # HACK - due to the way that pbufs are generated from the schemas,
    # we currently use a convention where abstract base schemas are
    # represented by a schema with a 'type' property defined with an
    # enumeration of valid types.
    # TODO: investigate using a type union instead
    type_prop = self._schema.get("properties", {}).get("type")
    if (type_prop is not None
        and type_prop.get("type") == "string"
        and "enum" in type_prop
        and type_prop.get("required", False)):
      # convention - body must be an object including a 'type' paramenter
      ret = self._check_type(self._json_to_python_types["object"], data, id_)
      if not ret[0]:
        return ret
      # convention - body must validate against the specified type
      schema = self.get_type(data.get("type", "<unspecified>"))
      if schema is None:
        return (False,
                self._errstr("type must be one of %s" % type_prop["enum"]))
      if schema != self:
        (ret, msg) = schema.validate(data, id_, crud_op, _checked_types)
        if not ret:
          return (ret, msg)
    # END HACK

    for check in self._checks:
      (isvalid, msg) = check(data, id_)
      if not isvalid:
        return (isvalid, msg)
    return (True, "success")

  @property
  def path(self):
    """Return path type validated by this instance.

    Path is constructed using dot-delimited fragment resolution.
    """
    return self._path_str

  def raw_schema(self):
    """Return schema definition dict.
    """
    return copy.deepcopy(self._schema)

  def get_type(self, type_name):
    """Return schema by its dot-delimited type name.
    """
    ret = self._schema_registry.get(type_name)
    if isinstance(ret, _UnresolvedSchemaRef):
      ret = ret.resolve(self._schema_registry)
      self._schema_registry[type_name] = ret
    return ret

  def get_property_schema(self, prop_name, _use_ap=True):
    """Return child schema by its property name.
    """
    ret = self.get_type("%s.%s" % (self.path, prop_name))
    if ret is None and self._extends_validator_path:
      ev = self.get_type(self._extends_validator_path)
      if ev is not None:
        ret = ev.get_property_schema(prop_name, False)
    if ret is None and _use_ap:
      ret = (self.get_type(self._ap_schema_path) or
             self.get_type("$any_additional_properties"))
    return ret

  def schema_types(self):
    """Return dict of schema-type-name->schema in schema registry
    """
    return self._schema_registry.copy()

  def unresolved_references(self):
    """Return list of _UnresolvedSchemaRef instances in schema registry
    """
    ret = []
    for v in self._schema_registry.values():
      if isinstance(v, _UnresolvedSchemaRef):
        ret.append(v)
    return ret

  def _init_child_schema(self, raw_schema, child_path_id, as_type=None):
    """Create a type validator for the schema specified by raw_schema

    Args:
      raw_schema: a raw schema specification in dict format
      child_path_id: identifier of schema in current schema context
      as_type: if specified and raw_schema defines a union type, only
               interpret raw_schema as the specified type
    """
    if len(self._type_path) and child_path_id == self._type_path[-1]:
      # this is possible when providing a $ref with overrides
      return self
    type_path = self._type_path + [child_path_id]
    if as_type is not None:
      assert(as_type in raw_schema.get("type", []))
      raw_schema = copy.deepcopy(raw_schema)
      if (type(as_type) in types.StringTypes and
          as_type in self._json_to_python_types):
        raw_schema['type'] = as_type
      else:
        assert(type(as_type) == types.DictType)
        del raw_schema['type']
        raw_schema.update(self._sanitize_schema(as_type))

    path_key = ".".join(type_path)
    if path_key in self._schema_registry:
      return self._schema_registry[path_key]

    if '$ref' in raw_schema:
      id_ = raw_schema['$ref']

      # This schema may coexist with other schemas in the schema registry,
      # so replace references to root fragment with the ID of the root fragment.
      # Note: RFC allows both #.foo and #foo as valid fragment identifiers.
      if id_.startswith("#"):
          child_fragment = id_[2:] if id_.startswith("#.") else id_[1:]
          if child_fragment:
            id_ = "%s.%s" %(self._type_path[0], child_fragment)
          else:
            id_ = self._type_path[0]
          raw_schema['$ref'] = id_

      cschema = self.get_type(id_)
      if len(raw_schema) > 1:
        # Although the RFC gives no mention of handling of references
        # along with other property restrictions, support is implied by the
        # meta-schema.
        overrides = dict([(k, v) for k, v in raw_schema.iteritems()
                           if k not in ['$ref', 'id']])
        if not overrides and isinstance(cschema, JsonSchema):
          ret = cschema
        else:
          ret = _UnresolvedSchemaRef(type_path, id_, self._strict,
                                     overrides=overrides)
      else:
        if cschema is not None:
          ret = cschema
        ret = _UnresolvedSchemaRef(type_path, id_, self._strict)
      self._schema_registry[path_key] = ret
      # Assuming no 'id' to index since this is a ref
    else:
      ret = JsonSchema(raw_schema, strict=self._strict, type_path=type_path,
                       schema_registry=self._schema_registry)
      # will add itself to self._schema_registry in __init__
    return ret

  def _init_union(self, schema):
    self._union_schemas = []
    union_index = 0
    for t in schema["type"]:
      v = self._init_child_schema(schema, '$typeUnion.%d' % union_index,
                                  as_type=t)
      union_index += 1
      self._union_schemas.append(v)
    self._checks.append(self._check_union)

  def _init_any(self, schema):
    pass  # intentionally not adding checks

  def _init_string(self, schema):
    self._checks.append(
        lambda d, id_: self._check_type(self._json_to_python_types["string"],
                                        d, id_))
    if 'pattern' in schema:
      pattern = schema['pattern']
      if not pattern.startswith("^") or not pattern.endswith("$"):
        raise SchemaException("Failed to compile pattern %s '%s', "
                              "must start with '^' and end with '$'" %
                              (schema.get("id", ""), pattern))
      try:
        self._re = re.compile(pattern)
      except re.error, e:
        raise SchemaException("Failed to compile pattern '%s'" % pattern, e)
      self._checks.append(self._check_pattern)
    if 'minLength' in schema:
      self._minlength = schema['minLength']
      self._checks.append(self._check_minlength)
    if 'maxLength' in schema:
      self._maxlength = schema['maxLength']
      self._checks.append(self._check_maxlength)

  def _init_number(self, schema, is_integer=False, is_signed=True):
    if is_integer:
      type_ = "integer"
      if not is_signed:
          type_ = "unsigned_integer"
    else:
      type_ = "number"
    self._checks.append(
        lambda d, id_: self._check_type(self._json_to_python_types[type_],
                                        d, id_))
    if 'minimum' in schema:
      if type(schema['minimum']) not in self._json_to_python_types['number']:
        raise TypeError("minimum must be a number")
      self._minimum = schema['minimum']
      self._checks.append(self._check_minimum)
    self._exclusiveMinimum = bool(schema.get('exclusiveMinimum', False))
    if 'maximum' in schema:
      if type(schema['maximum']) not in self._json_to_python_types['number']:
        raise TypeError("maximum must be a number")
      self._maximum = schema['maximum']
      self._checks.append(self._check_maximum)
    self._exclusiveMaximum = bool(schema.get('exclusiveMaximum', False))

    if 'divisibleBy' in schema and is_integer:
      if (type(schema['divisibleBy']) not in
          self._json_to_python_types["number"]):
        raise TypeError("divisibleBy must be a number")
      self._divisibleby = schema['divisibleBy']
      self._checks.append(self._check_divisibleby)
    # assuming that all floats are divisibleBy - the RFC is ambiguous

  def _init_integer(self, schema):
    return self._init_number(schema, is_integer=True)

  def _init_unsigned_integer(self, schema):
    return self._init_number(schema, is_integer=True, is_signed=False)

  def _init_boolean(self, unused_schema):
    self._checks.append(
        lambda d, id_: self._check_type(self._json_to_python_types["boolean"],
                                   d, id_))

  def _init_object(self, schema):
    self._checks.append(
        lambda d, id_: self._check_type(self._json_to_python_types["object"],
                                   d, id_))

    self._properties = schema.get("properties", {})
    # pre-init all schemas
    for prop_name, raw_schema in self._properties.iteritems():
      self._init_child_schema(raw_schema, prop_name)

    self._dependencies = {}
    if "dependencies" in schema:
      if not isinstance(schema['dependencies'], types.DictType):
        raise TypeError("dependencies must be a dict")
      for k, v in schema['dependencies'].items():
        if isinstance(v, types.StringTypes):
          # RFC: "If the dependency value is a string, then the
          #       instance object MUST have a property with the same
          #       name as the dependency value."
          s = {"type": "object", "properties": {v: {"required": True}}}
          dschema = self._init_child_schema(s, '$dependencies.%s' % k)
          self._dependencies[k] = dschema
        elif isinstance(v, (types.ListType, types.TupleType)):
          # RFC: "If the dependency value is an array of strings,
          #       then the instance object MUST have a property with the
          #       same name as each string in the dependency value's array."
          props = {}
          for t in v:
            props[t] = {"required": True}
          s = {"type": "object", "properties": props}
          dschema = self._init_child_schema(s, '$dependencies.%s' % k)
          self._dependencies[k] = dschema
        elif isinstance(v, types.DictType):
          # RFC: "If the dependency value is a schema, then the
          #       instance object MUST be valid against the schema."
          dschema = self._init_child_schema(v, '$dependencies.%s' % k)
          self._dependencies[k] = dschema
        else:
          raise TypeError("dependency '%s' has unsupported type %s"
                          % (k, str(type(v))))
      self._checks.append(self._check_property_dependencies)

    self._checks.append(self._check_property_types)
    self._checks.append(self._check_required_properties)

  def _init_array(self, schema):
    self._checks.append(
        lambda d, id_: self._check_type(self._json_to_python_types["array"],
                                        d, id_))
    if 'minItems' in schema:
      self._minitems = schema['minItems']
      self._checks.append(self._check_minitems)
    if 'maxItems' in schema:
      self._maxitems = schema['maxItems']
      self._checks.append(self._check_maxitems)
    if 'uniqueItems' in schema:
      self._checks.append(self._check_uniqueitems)

    itemschema = schema.get('items', None)
    if type(itemschema) in self._json_to_python_types["array"]:
      self._tuple_checks = []
      idx = 0
      for rs in itemschema:
        self._tuple_checks.append(
            self._init_child_schema(rs, "$arrayitems.%d" % idx))
        idx += 1
      self._checks.append(self._check_tuple_items)
    elif itemschema is not None:
      v = self._init_child_schema(itemschema, "$arrayitems")
      self._checks.append(
          lambda data, id_: self._check_array_items(v, data, id_))
    # else no items allows everything, so no need to add check

  def _init_null(self, unused_schema):
    self._checks.append(self._check_none)

  def _errstr(self, msg):
    return "%s: %s" %(self._name, msg)

  def _check_extends(self, data, id_):
    if self._extends_validator_path:
      ev = self.get_type(self._extends_validator_path)
      return ev.validate(data, id_, self._crud_op, self._checked_types.copy())
    return (True, "success")

  def _check_enum(self, data, unused_id_):
    """Verify data is None.
    """
    if data in self._enumvals:
      return (True, "success")
    else:
      if len(self._enumvals) == 1:
        msg = "value '%s' must equal '%s'" % (data, self._enumvals[0])
      elif len(self._enumvals) < 10:
        msg = "value '%s' must be one of %s" % (data, self._enumvals)
      else:
        msg = "value '%s' must be a valid enum value" % data
      return (False, self._errstr(msg))

  def _check_none(self, data, unused_id_):
    """Verify data is None.
    """
    if data is None:
      return (True, "success")
    else:
      return (False, self._errstr("must be None"))

  def _check_union(self, data, id_):
    """Verify data is valid according to at least one of validators.
    """
    for i in range(len(self._union_schemas)):
      schema = self._union_schemas[i]
      if isinstance(schema, _UnresolvedSchemaRef):
          schema = schema.resolve(self._schema_registry)
          self._union_schemas[i] = schema
      (isvalid, msg) = schema.validate(data, id_, self._crud_op,
                                       self._checked_types.copy())
      if isvalid:
        return (True, "success")
    msg = "data '%s' does not validate against any valid types" % data
    return (False, self._errstr(msg))

  def _check_type(self, valid_types, data, id_):
    """Verify data is a valid type.
    """
    msg = ""
    isvalid = type(data) in valid_types
    if not isvalid:
      if len(valid_types) > 1:
        msg = ("property '%s' type must be one of %s (is %s)"
               % (id_, tuple(valid_types), type(data)))
      else:
        msg = ("property '%s' must be of type %s (is %s)"
               % (id_, tuple(valid_types)[0], type(data)))
    return (isvalid, self._errstr(msg))

  def _check_minimum(self, data, unused_id_):
    isvalid = True
    msg = ""
    if self._exclusiveMinimum:
      if data <= self._minimum:
        isvalid = False
        msg = "value '%s' must be greater than '%s'" % (data, self._minimum)
    elif data < self._minimum:
      isvalid = False
      msg = "value '%s' must be greater than or equal to '%s'" % (data,
                                                                  self._minimum)
    return (isvalid, self._errstr(msg))

  def _check_maximum(self, data, unused_id_):
    isvalid = True
    msg = ""
    if self._exclusiveMaximum:
      if data >= self._maximum:
        isvalid = False
        msg = "value '%s' must be less than '%s'" % (data, self._maximum)
    elif data > self._maximum:
      isvalid = False
      msg = "value '%s' must be less than or equal to '%s'" % (data,
                                                               self._maximum)
    return (isvalid, self._errstr(msg))

  def _check_minitems(self, data, unused_id_):
    if type(data) in self._json_to_python_types['array']:
      if len(data) < self._minitems:
        msg = "must contain at least %s items (value is %r)" % (self._minitems,
                                                                data)
        return (False, self._errstr(msg))
    return (True, "success")

  def _check_maxitems(self, data, unused_id_):
    if type(data) in self._json_to_python_types['array']:
      if len(data) > self._maxitems:
        msg = "must contain at most %s items (value is %r)" % (self._maxitems,
                                                               data)
        return (False, self._errstr(msg))
    return (True, "success")

  def _check_uniqueitems(self, data, unused_id_):
    if type(data) in self._json_to_python_types['array']:
      # items can be unhashable (e.g. dict), so can't use a set() here
      seen = []
      for item in data:
        if item in seen:
          msg = "duplicate item '%s' not allowed" % item
          return (False, self._errstr(msg))
        seen.append(item)
    return (True, "success")

  def _check_divisibleby(self, data, unused_id_):
    if type(data) in self._json_to_python_types['integer']:
      if data % self._divisibleby:
        msg = "value '%s' must be divisible by %s" % (data, self._divisibleby)
        return (False, self._errstr(msg))
    return (True, "success")

  def _check_pattern(self, data, unused_id_):
    if not self._re.search(data):
      msg = "value '%s' must match the regular expression '%s'" % \
         (data, self._re.pattern)
      return (False, self._errstr(msg))
    return (True, "success")

  def _check_minlength(self, data, unused_id_):
    if len(data) < self._minlength:
      msg = "length of '%s' must be at least %d characters'" % (data,
                                                                self._minlength)
      return (False, self._errstr(msg))
    return (True, "success")

  def _check_maxlength(self, data, unused_id_):
    if len(data) > self._maxlength:
      msg = "length of '%s' must be at most %d characters'" % (data,
                                                               self._maxlength)
      return (False, self._errstr(msg))
    return (True, "success")

  def _check_required_properties(self, data, unused_id_):
    """Verify data has all properties required by the schema definition.
    """
    for k in self._properties:
      prop_schema = self.get_property_schema(k)
      is_required = prop_schema._schema.get("required", False)
      if self._crud_op:
        crud_is_optional = prop_schema._schema.get(
            "optional_crud", {}).get(self._crud_op)
        if crud_is_optional is not None:
          is_required = not crud_is_optional
      if is_required and k not in data:
        msg = "missing required property '%s'" %k
        return (False, self._errstr(msg))
    return (True, "success")

  def _check_property_dependencies(self, data, id_):
    """Verify that property 'dependencies', if any, are met.
    """
    for k in data:
      dschema = self._dependencies.get(k)
      if dschema is not None:
        if isinstance(dschema, _UnresolvedSchemaRef):
          dschema = dschema.resolve(self._schema_registry)
          self._dependencies[k] = dschema
        succ, msg = dschema.validate(data, id_, self._crud_op,
            self._checked_types.copy())
        if not succ:
          msg = "unmet dependencies for property '%s': %s" % (k, msg)
          return (succ, msg)
    return (True, "success")

  def _check_property_types(self, data, unused_id_):
    """Verifies all data properties validate against their defined types
    """
    for prop_name, prop in data.iteritems():
      ps = self.get_property_schema(prop_name)
      (isvalid, msg) = ps.validate(prop, prop_name, self._crud_op, None)
      if not isvalid:
        return (isvalid, msg)
    return (True, "success")

  def _check_array_items(self, validator, data, id_):
    """Verifies all array items in data validate against the array definition
    """
    if isinstance(validator, _UnresolvedSchemaRef):
      validator = validator.resolve(self._schema_registry)
    if type(data) in self._json_to_python_types['array']:
      i = 0
      for item in data:
        (isvalid, msg) = validator.validate(item, id_, self._crud_op,
                                            self._checked_types.copy())
        if not isvalid:
          return (isvalid, "%s.$item.%d: %s" %(self._name, i, msg))
        i += 1
    return (True, "success")

  def _check_tuple_items(self, data, id_):
    """Verifies all array items in data validate against the tuple definition
    """
    if type(data) in self._json_to_python_types['array']:
      i = 0
      for item in data:
        if i < len(self._tuple_checks):
          (isvalid, msg) = self._tuple_checks[i].validate(
              item, id_, self._crud_op, self._checked_types.copy())
        else:
          ap_schema = self.get_type(self._ap_schema_path)
          if ap_schema is not None:
            (isvalid, msg) = ap_schema.validate(
                item, id_, self._crud_op, self._checked_types.copy())
          else:
            isvalid, msg = True, "success"
        if not isvalid:
          return (isvalid, "%s.$item.%d: %s" %(self._name, i, msg))
        i += 1
    return (True, "success")

  def _check_format_uuid(self, data, unused_id_):
    """Verifies data is a valid RFC 4122 UUID
    """
    if type(data) in types.StringTypes:
      if self._uuid_re.match(data):
        return (True, "success")
    return (False, self._errstr("must be an RFC 4122 UUID"))


class _AnyAdditionalPropertiesSchema(_BaseJsonSchema):
  @property
  def path(self):
      return "$any_additional_properties"


class _NoAdditionalPropertiesSchema(_BaseJsonSchema):
  def __init__(self, name, parent_path):
      super(_NoAdditionalPropertiesSchema, self).__init__(name=name)
      self._path_str = "%s.%s" % (".".join(parent_path), name)

  @property
  def path(self):
      return self._path_str

  def validate(self, data, id_, unused_crud_op, unused_checked_types):
    return (False, "invalid property '%s' (value '%s'): properties not specified "
                   "by schema are not allowed by %s" % (id_, data, self._name))


class _UnresolvedSchemaRef(_BaseJsonSchema):
  """Reference to a schema type that has not been resolved.
  """
  def __init__(self, type_path, ref, strict, overrides=None):
    super(_UnresolvedSchemaRef, self).__init__()
    self._type_path = type_path
    self._ref = ref
    self._strict = strict
    if ref != '$additionalProperties':
      self._ap_schema_path = ".".join(
          type_path + [ref, '$additionalProperties'])
    else:
      self._ap_schema_path = self.path
    self._name = self.path
    self._overrides = overrides

  def __str__(self):
    return "Unresolved reference to '%s' from '%s'" %(
        self._ref, ".".join(self._type_path))

  def _enforce_strict(self):
    if self._strict:
      raise SchemaException(
        "Strict validation forbids validation using unresolved reference to "
        "'%s' from '%s'" %(self._ref, str(self.path)))

  @property
  def path(self):
    return ".".join(self._type_path)

  def resolve(self, schema_registry):
    """Attempt to resolve reference in schema_registry

    Updates registry if reference can be resolved.

    Returns:
      The resolved schema or self if not in registry
    """
    if self._ref in schema_registry:
      if self._overrides is not None:
        rs = schema_registry[self._ref]._schema.copy()
        if 'id' in rs:
          del rs['id']
        rs.update(self._overrides)
        schema_registry[self.path] = JsonSchema(
            rs, strict=self._strict, type_path=self._type_path,
            schema_registry=schema_registry)
        return schema_registry[self.path]
      else:
        schema_registry[self.path] = schema_registry[self._ref]
        return schema_registry[self._ref]
    return self

  def validate(self, unused_data, unused_id_, unused_crud_op,
               unused_checked_types):
    self._enforce_strict()
    return (True, "success")

  def raw_schema(self):
    self._enforce_strict()
    return {}

  def get_property_schema(self, *unused_args, **unused_kwargs):
    self._enforce_strict()
    return self

  def get_type(self, *unused_args, **unused_kwargs):
    self._enforce_strict()
    return self


def main(args):
  if len(args) < 2 or len(args) > 3:
    print "Usage: %s <schemafile> [datafile]" %args[0]
    return

  schema = JsonSchema(open(args[1]).read())

  if len(args) == 3:
    validate, reason = schema.validate(simplejson.load(open(args[2])))
    if validate:
      print "%s validates against schema %s" %(args[2], args[1])
    else:
      print ("%s failed to validate against schema %s: %s"
             %(args[2], args[1], reason))
  else:
    print "Schema parsed successfully.\n  Supported types:"
    for type_, schema in sorted(schema.schema_types().items()):
      print "    %s" % type_
    urs = schema.unresolved_references()
    if urs:
      print "  Unresolved references:"
      for ur in urs:
        print "    %s" %ur


if __name__ == "__main__":
  sys.exit(main(sys.argv))

