#
#  Auto generated vAPI interface file from Strata.java
#  DO NOT MODIFY!
#
__author__ = 'VMware, Inc.'
__docformat__ = 'epytext en'

from vmware.vapi.bindings.struct import VapiStruct
from vmware.vapi.bindings.enum import Enum
from vmware.vapi.bindings.stub import (VapiInterface, ApiInterfaceStub,
    ApiMethodStub)
from vmware.vapi.bindings.type import (IntegerType, DoubleType, ReferenceType,
    BooleanType, StringType, BlobType, VoidType, DateTimeType, URIType,
    OpaqueType, ListType, StructType, OptionalType, SecretType, EnumType)

# Usage:
#
# import connect
# from com.vmware.loginsight.api.strata_client import Strata
#
# connector = connect.get_connector(...)
# instance = Strata(connector)
#
# # use instance to execute methods
#


class Strata(VapiInterface):
    """
    Strata API, Copyright (c) 2014 VMware, Inc. All rights reserved.
    """
    def __init__(self, connector):
        VapiInterface.__init__(self, connector, StrataStub)

    class StrataMatchingTerm(VapiStruct):
        """
        A term in the message that matches the query.
        Can be used to implement highlighting.

        @type start_offset: C{long}
        @ivar start_offset: 0-based position of the location of the term in the message
        @type value: C{str}
        @ivar value: The value of term
        """
        def __init__(self, **kwargs):
            """
            Initialize StrataMatchingTerm

            @type start_offset: C{long}
            @kwarg start_offset: 0-based position of the location of the term in the message
            @type value: C{str}
            @kwarg value: The value of term
            """

            self.start_offset = kwargs.get('start_offset')
            self.value = kwargs.get('value')
            VapiStruct.__init__(self, {})

    class StrataValue(VapiStruct):
        """
        The value of a log field.

        @type type: L{com.vmware.loginsight.api.types.Strata.StrataType}
        @ivar type: The type of this value
        @type value: C{str}
        @ivar value: This value will always be set.
        @type numeric_value: C{float} or C{None}
        @ivar numeric_value: This value will also be set if the field is a number.
        """
        def __init__(self, **kwargs):
            """
            Initialize StrataValue

            @type type: L{com.vmware.loginsight.api.types.Strata.StrataType}
            @kwarg type: The type of this value
            @type value: C{str}
            @kwarg value: This value will always be set.
            @type numeric_value: C{float} or C{None}
            @kwarg numeric_value: This value will also be set if the field is a number.
            """

            self.type = kwargs.get('type')
            self.value = kwargs.get('value')
            self.numeric_value = kwargs.get('numeric_value')
            VapiStruct.__init__(self, {})

    class StrataField(VapiStruct):
        """
        Represents a log field.

        @type name: C{str}
        @ivar name: The name of this field
        @type value: L{com.vmware.loginsight.api.types.Strata.StrataValue}
        @ivar value: The value of this field
        @type is_extracted: C{bool} or C{None}
        @ivar is_extracted: True if this field was extracted dynamically via regex
        @type start_offset: C{long} or C{None}
        @ivar start_offset: The 0-based position of this field in the message (-1 if field is metadata only)
        """
        def __init__(self, **kwargs):
            """
            Initialize StrataField

            @type name: C{str}
            @kwarg name: The name of this field
            @type value: L{com.vmware.loginsight.api.types.Strata.StrataValue}
            @kwarg value: The value of this field
            @type is_extracted: C{bool} or C{None}
            @kwarg is_extracted: True if this field was extracted dynamically via regex
            @type start_offset: C{long} or C{None}
            @kwarg start_offset: The 0-based position of this field in the message (-1 if field is metadata only)
            """

            self.name = kwargs.get('name')
            self.value = kwargs.get('value')
            self.is_extracted = kwargs.get('is_extracted')
            self.start_offset = kwargs.get('start_offset')
            VapiStruct.__init__(self, {})

    class StrataFacetingField(VapiStruct):
        """
        Represents a faceting field. These are fields that are
        present anywhere in the returned messages or the query itself.

        @type name: C{str}
        @ivar name: Name of the field
        @type is_number: C{bool}
        @ivar is_number: True if this field is an integer or floating point number
        @type is_extracted: C{bool}
        @ivar is_extracted: True if this field was extracted dynamically via regex
        """
        def __init__(self, **kwargs):
            """
            Initialize StrataFacetingField

            @type name: C{str}
            @kwarg name: Name of the field
            @type is_number: C{bool}
            @kwarg is_number: True if this field is an integer or floating point number
            @type is_extracted: C{bool}
            @kwarg is_extracted: True if this field was extracted dynamically via regex
            """

            self.name = kwargs.get('name')
            self.is_number = kwargs.get('is_number')
            self.is_extracted = kwargs.get('is_extracted')
            VapiStruct.__init__(self, {})

    class StrataQueryConstraint(VapiStruct):
        """
        Represents a single field constraint.

        @type field_name: C{str}
        @ivar field_name: Name of the field to constrain
        @type field_val: C{str}
        @ivar field_val: Value of the constraint
        @type operator: L{com.vmware.loginsight.api.types.Strata.StrataConstraintOperator}
        @ivar operator: Operator for the constraint (e.g., equals)
        """
        def __init__(self, **kwargs):
            """
            Initialize StrataQueryConstraint

            @type field_name: C{str}
            @kwarg field_name: Name of the field to constrain
            @type field_val: C{str}
            @kwarg field_val: Value of the constraint
            @type operator: L{com.vmware.loginsight.api.types.Strata.StrataConstraintOperator}
            @kwarg operator: Operator for the constraint (e.g., equals)
            """

            self.field_name = kwargs.get('field_name')
            self.field_val = kwargs.get('field_val')
            self.operator = kwargs.get('operator')
            VapiStruct.__init__(self, {})

    class StrataQueryConstraints(VapiStruct):
        """
        Contains the field constraints for the query.

        @type constraints: C{list} of C{list} of L{com.vmware.loginsight.api.types.Strata.StrataQueryConstraint} or C{None}
        @ivar constraints: Constraints are represented in a two dimensional list:
        - first dimension is AND
        - second dimension is OR
        Example:
        [[source:"source1", source:"source2"],
        [host:"1.1.1.1", host:"2.2.2.2"],
        [http_status:200],
        [referer:"foo"]]
        Translates to:
        (source="source1" OR source="source2") AND
        (host=1.1.1.1 OR host=2.2.2.2) AND
        (http_status=200) AND
        (referer="foo")
        """
        def __init__(self, **kwargs):
            """
            Initialize StrataQueryConstraints

            @type constraints: C{list} of C{list} of L{com.vmware.loginsight.api.types.Strata.StrataQueryConstraint} or C{None}
            @kwarg constraints: Constraints are represented in a two dimensional list:
            - first dimension is AND
            - second dimension is OR
            Example:
            [[source:"source1", source:"source2"],
            [host:"1.1.1.1", host:"2.2.2.2"],
            [http_status:200],
            [referer:"foo"]]
            Translates to:
            (source="source1" OR source="source2") AND
            (host=1.1.1.1 OR host=2.2.2.2) AND
            (http_status=200) AND
            (referer="foo")
            """

            self.constraints = kwargs.get('constraints')
            VapiStruct.__init__(self, {})

    class StrataQueryId(VapiStruct):
        """
        ID used for cancellation and streaming queries

        @type id: C{str}
        @ivar id: ID value
        """
        def __init__(self, **kwargs):
            """
            Initialize StrataQueryId

            @type id: C{str}
            @kwarg id: ID value
            """

            self.id = kwargs.get('id')
            VapiStruct.__init__(self, {})

    class StrataQueryStatus(VapiStruct):
        """
        Status of a running query

        @type id: L{com.vmware.loginsight.api.types.Strata.StrataQueryId}
        @ivar id: 
        @type elapse: C{long}
        @ivar elapse: 
        @type pending: C{bool}
        @ivar pending: Whether the query is pending in backend queue
        """
        def __init__(self, **kwargs):
            """
            Initialize StrataQueryStatus

            @type id: L{com.vmware.loginsight.api.types.Strata.StrataQueryId}
            @kwarg id: 
            @type elapse: C{long}
            @kwarg elapse: 
            @type pending: C{bool}
            @kwarg pending: Whether the query is pending in backend queue
            """

            self.id = kwargs.get('id')
            self.elapse = kwargs.get('elapse')
            self.pending = kwargs.get('pending')
            VapiStruct.__init__(self, {})

    class StrataMessageId(VapiStruct):
        """
        Globally unique message ID

        @type bucket_high: C{long}
        @ivar bucket_high: 
        @type bucket_low: C{long}
        @ivar bucket_low: 
        @type segment_offset: C{long}
        @ivar segment_offset: 
        @type message_index: C{long}
        @ivar message_index: 
        """
        def __init__(self, **kwargs):
            """
            Initialize StrataMessageId

            @type bucket_high: C{long}
            @kwarg bucket_high: 
            @type bucket_low: C{long}
            @kwarg bucket_low: 
            @type segment_offset: C{long}
            @kwarg segment_offset: 
            @type message_index: C{long}
            @kwarg message_index: 
            """

            self.bucket_high = kwargs.get('bucket_high')
            self.bucket_low = kwargs.get('bucket_low')
            self.segment_offset = kwargs.get('segment_offset')
            self.message_index = kwargs.get('message_index')
            VapiStruct.__init__(self, {})

    class StrataMessage(VapiStruct):
        """
        A single log message

        @type message_text: C{str}
        @ivar message_text: Raw text of this message
        @type message_id: L{com.vmware.loginsight.api.types.Strata.StrataMessageId} or C{None}
        @ivar message_id: Globally unique message ID
        @type message_timestamp: C{long} or C{None}
        @ivar message_timestamp: Timestamp contained in the message (in milliseconds)
        @type arrival_timestamp: C{long} or C{None}
        @ivar arrival_timestamp: Timestamp of arrival into the system (in milliseconds)
        @type matching_terms: C{list} of L{com.vmware.loginsight.api.types.Strata.StrataMatchingTerm} or C{None}
        @ivar matching_terms: The terms in this message that matched the query
        @type fields: C{list} of L{com.vmware.loginsight.api.types.Strata.StrataField} or C{None}
        @ivar fields: Fields in this message
        """
        def __init__(self, **kwargs):
            """
            Initialize StrataMessage

            @type message_text: C{str}
            @kwarg message_text: Raw text of this message
            @type message_id: L{com.vmware.loginsight.api.types.Strata.StrataMessageId} or C{None}
            @kwarg message_id: Globally unique message ID
            @type message_timestamp: C{long} or C{None}
            @kwarg message_timestamp: Timestamp contained in the message (in milliseconds)
            @type arrival_timestamp: C{long} or C{None}
            @kwarg arrival_timestamp: Timestamp of arrival into the system (in milliseconds)
            @type matching_terms: C{list} of L{com.vmware.loginsight.api.types.Strata.StrataMatchingTerm} or C{None}
            @kwarg matching_terms: The terms in this message that matched the query
            @type fields: C{list} of L{com.vmware.loginsight.api.types.Strata.StrataField} or C{None}
            @kwarg fields: Fields in this message
            """

            self.message_text = kwargs.get('message_text')
            self.message_id = kwargs.get('message_id')
            self.message_timestamp = kwargs.get('message_timestamp')
            self.arrival_timestamp = kwargs.get('arrival_timestamp')
            self.matching_terms = kwargs.get('matching_terms')
            self.fields = kwargs.get('fields')
            VapiStruct.__init__(self, {})

    class StrataTable(VapiStruct):
        """
        Structure for holding tabular data, e.g.
        Hostname     COUNT(m)
        ---------------------
        host1        183
        host2        12
        host3        0
        Would translate to:
        headers:["Hostname", "COUNT(m)"]
        values:[["host1", 183],
        ["host2", 12],
        ["host3", 0]]

        @type headers: C{list} of C{str}
        @ivar headers: 
        @type values: C{list} of C{list} of L{com.vmware.loginsight.api.types.Strata.StrataValue}
        @ivar values: 
        """
        def __init__(self, **kwargs):
            """
            Initialize StrataTable

            @type headers: C{list} of C{str}
            @kwarg headers: 
            @type values: C{list} of C{list} of L{com.vmware.loginsight.api.types.Strata.StrataValue}
            @kwarg values: 
            """

            self.headers = kwargs.get('headers')
            self.values = kwargs.get('values')
            VapiStruct.__init__(self, {})

    class StrataQueryResult(VapiStruct):
        """
        The response object for a message query.

        @type query_id: L{com.vmware.loginsight.api.types.Strata.StrataQueryId}
        @ivar query_id: The query ID for this request. Can be used
        to retrieve more incremental results or to cancel
        long running queries.
        @type messages: C{list} of L{com.vmware.loginsight.api.types.Strata.StrataMessage}
        @ivar messages: List of messages that match the query
        @type faceting_fields: C{list} of L{com.vmware.loginsight.api.types.Strata.StrataFacetingField}
        @ivar faceting_fields: Faceting fields for this set of results
        @type table: L{com.vmware.loginsight.api.types.Strata.StrataTable} or C{None}
        @ivar table: Table containing "group by" (aggregate) results
        @type more_incremental_results: C{bool}
        @ivar more_incremental_results: True if additional incremental calls are needed to retrieve the full
        set of query results
        @type total: C{long}
        @ivar total: Total number of messages that match the given query
        """
        def __init__(self, **kwargs):
            """
            Initialize StrataQueryResult

            @type query_id: L{com.vmware.loginsight.api.types.Strata.StrataQueryId}
            @kwarg query_id: The query ID for this request. Can be used
            to retrieve more incremental results or to cancel
            long running queries.
            @type messages: C{list} of L{com.vmware.loginsight.api.types.Strata.StrataMessage}
            @kwarg messages: List of messages that match the query
            @type faceting_fields: C{list} of L{com.vmware.loginsight.api.types.Strata.StrataFacetingField}
            @kwarg faceting_fields: Faceting fields for this set of results
            @type table: L{com.vmware.loginsight.api.types.Strata.StrataTable} or C{None}
            @kwarg table: Table containing "group by" (aggregate) results
            @type more_incremental_results: C{bool}
            @kwarg more_incremental_results: True if additional incremental calls are needed to retrieve the full
            set of query results
            @type total: C{long}
            @kwarg total: Total number of messages that match the given query
            """

            self.query_id = kwargs.get('query_id')
            self.messages = kwargs.get('messages')
            self.faceting_fields = kwargs.get('faceting_fields')
            self.table = kwargs.get('table')
            self.more_incremental_results = kwargs.get('more_incremental_results')
            self.total = kwargs.get('total')
            VapiStruct.__init__(self, {})

    class StrataVersionInfo(VapiStruct):
        """
        Information about the version of the server application.

        @type version: C{str}
        @ivar version: Version string (usually major.minor.revision-build)
        @type major: C{long}
        @ivar major: Major version number
        @type minor: C{long}
        @ivar minor: Minor version number
        @type revision: C{long}
        @ivar revision: Revision number
        @type build: C{str}
        @ivar build: Build string
        @type packager: C{str}
        @ivar packager: Packager
        @type timestamp: C{long}
        @ivar timestamp: Time of build (milliseconds since the epoch)
        """
        def __init__(self, **kwargs):
            """
            Initialize StrataVersionInfo

            @type version: C{str}
            @kwarg version: Version string (usually major.minor.revision-build)
            @type major: C{long}
            @kwarg major: Major version number
            @type minor: C{long}
            @kwarg minor: Minor version number
            @type revision: C{long}
            @kwarg revision: Revision number
            @type build: C{str}
            @kwarg build: Build string
            @type packager: C{str}
            @kwarg packager: Packager
            @type timestamp: C{long}
            @kwarg timestamp: Time of build (milliseconds since the epoch)
            """

            self.version = kwargs.get('version')
            self.major = kwargs.get('major')
            self.minor = kwargs.get('minor')
            self.revision = kwargs.get('revision')
            self.build = kwargs.get('build')
            self.packager = kwargs.get('packager')
            self.timestamp = kwargs.get('timestamp')
            VapiStruct.__init__(self, {})

    class StrataGroupByField(VapiStruct):
        """
        Info for describing how a field will be aggregated

        @type field_name: C{str}
        @ivar field_name: Name of the field that is being grouped
        @type group_by_type: L{com.vmware.loginsight.api.types.Strata.StrataGroupByType}
        @ivar group_by_type: Value for increments of group by
        @type group_by_value: C{str}
        @ivar group_by_value: For custom buckets and fixed buckets
        """
        def __init__(self, **kwargs):
            """
            Initialize StrataGroupByField

            @type field_name: C{str}
            @kwarg field_name: Name of the field that is being grouped
            @type group_by_type: L{com.vmware.loginsight.api.types.Strata.StrataGroupByType}
            @kwarg group_by_type: Value for increments of group by
            @type group_by_value: C{str}
            @kwarg group_by_value: For custom buckets and fixed buckets
            """

            self.field_name = kwargs.get('field_name')
            self.group_by_type = kwargs.get('group_by_type')
            self.group_by_value = kwargs.get('group_by_value')
            VapiStruct.__init__(self, {})


    class StrataType(Enum):
        """
        A value type for log fields.

        @type NUMERIC: L{StrataType}
        @cvar NUMERIC: Integer or floating point values
        @type STRING: L{StrataType}
        @cvar STRING: Any other values
        """
        NUMERIC = None
        STRING = None

        def __init__(self, s=''):
            Enum.__init__(s)

    StrataType.NUMERIC = StrataType('NUMERIC')
    StrataType.STRING = StrataType('STRING')

    class StrataConstraintOperator(Enum):
        """
        Operators used for defining field constraints.
        The applicability of operators depends on the field type.

        @type EQUALS: L{StrataConstraintOperator}
        @cvar EQUALS: Applicable for numeric fields only
        @type NOT_EQUALS: L{StrataConstraintOperator}
        @cvar NOT_EQUALS: Applicable for numeric fields only
        @type GREATER_THAN: L{StrataConstraintOperator}
        @cvar GREATER_THAN: Applicable for numeric fields only
        @type LESS_THAN: L{StrataConstraintOperator}
        @cvar LESS_THAN: Applicable for numeric fields only
        @type GREATER_OR_EQUAL: L{StrataConstraintOperator}
        @cvar GREATER_OR_EQUAL: Applicable for numeric fields only
        @type LESS_OR_EQUAL: L{StrataConstraintOperator}
        @cvar LESS_OR_EQUAL: Applicable for numeric fields only
        @type CONTAINS_TOKENS: L{StrataConstraintOperator}
        @cvar CONTAINS_TOKENS: Applicable for string fields only.
        A token refers to a section of text separated by
        certain characters like spaces. E.g., in the string
        "foo bar", the tokens are "foo" and "bar".
        @type NOT_CONTAINS_TOKENS: L{StrataConstraintOperator}
        @cvar NOT_CONTAINS_TOKENS: Applicable for string fields only
        @type MATCHES_REGEX: L{StrataConstraintOperator}
        @cvar MATCHES_REGEX: Regex matching. Applicable for string fields only
        @type STARTS_WITH: L{StrataConstraintOperator}
        @cvar STARTS_WITH: Applicable for string and numeric fields
        @type NOT_STARTS_WITH: L{StrataConstraintOperator}
        @cvar NOT_STARTS_WITH: Applicable for string and numeric fields
        """
        EQUALS = None
        NOT_EQUALS = None
        GREATER_THAN = None
        LESS_THAN = None
        GREATER_OR_EQUAL = None
        LESS_OR_EQUAL = None
        CONTAINS_TOKENS = None
        NOT_CONTAINS_TOKENS = None
        MATCHES_REGEX = None
        STARTS_WITH = None
        NOT_STARTS_WITH = None

        def __init__(self, s=''):
            Enum.__init__(s)

    StrataConstraintOperator.EQUALS = StrataConstraintOperator('EQUALS')
    StrataConstraintOperator.NOT_EQUALS = StrataConstraintOperator('NOT_EQUALS')
    StrataConstraintOperator.GREATER_THAN = StrataConstraintOperator('GREATER_THAN')
    StrataConstraintOperator.LESS_THAN = StrataConstraintOperator('LESS_THAN')
    StrataConstraintOperator.GREATER_OR_EQUAL = StrataConstraintOperator('GREATER_OR_EQUAL')
    StrataConstraintOperator.LESS_OR_EQUAL = StrataConstraintOperator('LESS_OR_EQUAL')
    StrataConstraintOperator.CONTAINS_TOKENS = StrataConstraintOperator('CONTAINS_TOKENS')
    StrataConstraintOperator.NOT_CONTAINS_TOKENS = StrataConstraintOperator('NOT_CONTAINS_TOKENS')
    StrataConstraintOperator.MATCHES_REGEX = StrataConstraintOperator('MATCHES_REGEX')
    StrataConstraintOperator.STARTS_WITH = StrataConstraintOperator('STARTS_WITH')
    StrataConstraintOperator.NOT_STARTS_WITH = StrataConstraintOperator('NOT_STARTS_WITH')

    class StrataGroupByType(Enum):
        """
        A value type for selecting increments for aggregation

        @type EACH_VALUE: L{StrataGroupByType}
        @cvar EACH_VALUE: Values are grouped individually
        @type FIXED_BUCKET: L{StrataGroupByType}
        @cvar FIXED_BUCKET: Values are grouped in consistent intervals
        @type CUSTOM_BUCKET: L{StrataGroupByType}
        @cvar CUSTOM_BUCKET: A comma seperated list of values
        """
        EACH_VALUE = None
        FIXED_BUCKET = None
        CUSTOM_BUCKET = None

        def __init__(self, s=''):
            Enum.__init__(s)

    StrataGroupByType.EACH_VALUE = StrataGroupByType('EACH_VALUE')
    StrataGroupByType.FIXED_BUCKET = StrataGroupByType('FIXED_BUCKET')
    StrataGroupByType.CUSTOM_BUCKET = StrataGroupByType('CUSTOM_BUCKET')

    class StrataAggregationFunction(Enum):
        """
        Value to group a query by

        @type COUNT: L{StrataAggregationFunction}
        @cvar COUNT: The number of items with the field
        @type UNIQUE_COUNT: L{StrataAggregationFunction}
        @cvar UNIQUE_COUNT: The number of unique values of the field
        @type AVERAGE: L{StrataAggregationFunction}
        @cvar AVERAGE: Average value of the field
        @type MIN: L{StrataAggregationFunction}
        @cvar MIN: Minimum value of the field
        @type MAX: L{StrataAggregationFunction}
        @cvar MAX: Maximum value of the field
        @type SUM: L{StrataAggregationFunction}
        @cvar SUM: Summation of the field values
        @type STD_DEV: L{StrataAggregationFunction}
        @cvar STD_DEV: Standard deviation of the field values
        @type VARIANCE: L{StrataAggregationFunction}
        @cvar VARIANCE: Variance of the field values
        """
        COUNT = None
        UNIQUE_COUNT = None
        AVERAGE = None
        MIN = None
        MAX = None
        SUM = None
        STD_DEV = None
        VARIANCE = None

        def __init__(self, s=''):
            Enum.__init__(s)

    StrataAggregationFunction.COUNT = StrataAggregationFunction('COUNT')
    StrataAggregationFunction.UNIQUE_COUNT = StrataAggregationFunction('UNIQUE_COUNT')
    StrataAggregationFunction.AVERAGE = StrataAggregationFunction('AVERAGE')
    StrataAggregationFunction.MIN = StrataAggregationFunction('MIN')
    StrataAggregationFunction.MAX = StrataAggregationFunction('MAX')
    StrataAggregationFunction.SUM = StrataAggregationFunction('SUM')
    StrataAggregationFunction.STD_DEV = StrataAggregationFunction('STD_DEV')
    StrataAggregationFunction.VARIANCE = StrataAggregationFunction('VARIANCE')


    def generate_query_id(self):
        """
        Generate an ID to use for a new incremental query and/or
        a cancellable query.

        @rtype: L{com.vmware.loginsight.api.types.Strata.StrataQueryId}
        @return: StrataQueryId
        @raise L{vmware.vapi.bindings.error.InternalServerError}: 
        """
        return self._invoke('generate_query_id')

    def cancel_query(self, **kwargs):
        """
        Cancel a currently running query. This call is asynchronous so it will
        return immediately. Cancellation is best-effort; there is no guarantee
        that a query will actually be cancelled.

        @type query_id: L{com.vmware.loginsight.api.types.Strata.StrataQueryId}
        @kwarg query_id: ID of the query to cancel.
        @raise L{vmware.vapi.bindings.error.InvalidRequest}: 
        @raise L{vmware.vapi.bindings.error.TimedOut}: 
        @raise L{vmware.vapi.bindings.error.InternalServerError}: 
        """
        self._validate_kwargs('cancel_query', kwargs)
        return self._invoke('cancel_query',
                            query_id=kwargs.get('query_id'),
                           )

    def list_queries(self):
        """
        List all running queries.

        @rtype: C{list} of L{com.vmware.loginsight.api.types.Strata.StrataQueryStatus}
        @return: 
        @raise L{vmware.vapi.bindings.error.InternalServerError}: 
        """
        return self._invoke('list_queries')

    def piql_query(self, **kwargs):
        """
        Perform a PIQL query.

        @type query: C{str}
        @kwarg query: PIQL query string
        @type wait_millis: C{long} or C{None}
        @kwarg wait_millis: Amount of time to wait for results to return
        @type from_result: C{long} or C{None}
        @kwarg from_result: For pagination, starts at 1 (queries are not stateful, so pagination may change between calls
        if underlying data changes). Not applicable for aggregation queries.
        @type count: C{long} or C{None}
        @kwarg count: Number of results to return (defaults to 10). Not applicable for aggregation queries.
        @type query_id: L{com.vmware.loginsight.api.types.Strata.StrataQueryId} or C{None}
        @kwarg query_id: Optional ID to use for this query (for cancellation or incremental queries)
        @rtype: L{com.vmware.loginsight.api.types.Strata.StrataQueryResult}
        @return: StrataQueryResult
        @raise L{vmware.vapi.bindings.error.InvalidRequest}: 
        @raise L{vmware.vapi.bindings.error.TimedOut}: 
        @raise L{vmware.vapi.bindings.error.InternalServerError}: 
        """
        self._validate_kwargs('piql_query', kwargs)
        return self._invoke('piql_query',
                            query=kwargs.get('query'),
                            wait_millis=kwargs.get('wait_millis'),
                            from_result=kwargs.get('from_result'),
                            count=kwargs.get('count'),
                            query_id=kwargs.get('query_id'),
                           )

    def message_query(self, **kwargs):
        """
        Perform a message query.

        @type query: C{str} or C{None}
        @kwarg query: Keyword query (supports multiple terms separated by whitespace, quoted phrase queries, and wildcards ? *)
        @type wait_millis: C{long} or C{None}
        @kwarg wait_millis: Amount of time to wait for results to return
        @type from_result: C{long} or C{None}
        @kwarg from_result: For pagination, starts at 1 (queries are not stateful, so pagination may change between calls if underlying data changes)
        @type count: C{long} or C{None}
        @kwarg count: Number of results to return (defaults to 10)
        @type start_time_millis: C{long} or C{None}
        @kwarg start_time_millis: Only return messages starting from this time
        @type end_time_millis: C{long} or C{None}
        @kwarg end_time_millis: Only return messages up to this time
        @type constraints: L{com.vmware.loginsight.api.types.Strata.StrataQueryConstraints} or C{None}
        @kwarg constraints: 
        @type query_id: L{com.vmware.loginsight.api.types.Strata.StrataQueryId} or C{None}
        @kwarg query_id: Optional ID to use for this query (for cancellation or incremental queries)
        @rtype: L{com.vmware.loginsight.api.types.Strata.StrataQueryResult}
        @return: StrataQueryResult
        @raise L{vmware.vapi.bindings.error.InvalidRequest}: 
        @raise L{vmware.vapi.bindings.error.TimedOut}: 
        @raise L{vmware.vapi.bindings.error.InternalServerError}: 
        """
        self._validate_kwargs('message_query', kwargs)
        return self._invoke('message_query',
                            query=kwargs.get('query'),
                            wait_millis=kwargs.get('wait_millis'),
                            from_result=kwargs.get('from_result'),
                            count=kwargs.get('count'),
                            start_time_millis=kwargs.get('start_time_millis'),
                            end_time_millis=kwargs.get('end_time_millis'),
                            constraints=kwargs.get('constraints'),
                            query_id=kwargs.get('query_id'),
                           )

    def incremental_message_query(self, **kwargs):
        """
        Continue a query

        @type query_id: L{com.vmware.loginsight.api.types.Strata.StrataQueryId}
        @kwarg query_id:  ID of this query
        @type wait_millis: C{long} or C{None}
        @kwarg wait_millis:  Amount of time to wait for results to return
        @rtype: L{com.vmware.loginsight.api.types.Strata.StrataQueryResult}
        @return: StrataQueryResult
        @raise L{vmware.vapi.bindings.error.InvalidRequest}: 
        @raise L{vmware.vapi.bindings.error.TimedOut}: 
        @raise L{vmware.vapi.bindings.error.InternalServerError}: 
        """
        self._validate_kwargs('incremental_message_query', kwargs)
        return self._invoke('incremental_message_query',
                            query_id=kwargs.get('query_id'),
                            wait_millis=kwargs.get('wait_millis'),
                           )

    def aggregation_query(self, **kwargs):
        """
        

        @type query: C{str} or C{None}
        @kwarg query: Keyword query
        @type wait_millis: C{long} or C{None}
        @kwarg wait_millis: Amount of time to wait for results to return
        @type start_time_millis: C{long} or C{None}
        @kwarg start_time_millis: Only return messages starting from this time
        @type end_time_millis: C{long} or C{None}
        @kwarg end_time_millis: Only return messages up to and including this time
        @type constraints: L{com.vmware.loginsight.api.types.Strata.StrataQueryConstraints} or C{None}
        @kwarg constraints: Log field constraints
        @type group_by_fields: C{list} of L{com.vmware.loginsight.api.types.Strata.StrataGroupByField} or C{None}
        @kwarg group_by_fields: The fields that the query will be grouped by (required if no timeSeries)
        @type time_series: C{bool} or C{None}
        @kwarg time_series: If the query will be grouped by time also (required if no groupByFields)
        @type time_window_grouping: C{long} or C{None}
        @kwarg time_window_grouping: The time segments to break your query (only if timeSeries is true)
        @type aggregation_function: L{com.vmware.loginsight.api.types.Strata.StrataAggregationFunction} or C{None}
        @kwarg aggregation_function: The function to evaluate the fields on
        @type aggregation_field: C{str} or C{None}
        @kwarg aggregation_field: The field to aggregate on
        @type limit: C{long} or C{None}
        @kwarg limit: Max number of rows returned in the table
        @type query_id: L{com.vmware.loginsight.api.types.Strata.StrataQueryId} or C{None}
        @kwarg query_id: 
        @rtype: L{com.vmware.loginsight.api.types.Strata.StrataQueryResult}
        @return: 
        @raise L{vmware.vapi.bindings.error.InvalidRequest}: 
        @raise L{vmware.vapi.bindings.error.TimedOut}: 
        @raise L{vmware.vapi.bindings.error.InternalServerError}: 
        """
        self._validate_kwargs('aggregation_query', kwargs)
        return self._invoke('aggregation_query',
                            query=kwargs.get('query'),
                            wait_millis=kwargs.get('wait_millis'),
                            start_time_millis=kwargs.get('start_time_millis'),
                            end_time_millis=kwargs.get('end_time_millis'),
                            constraints=kwargs.get('constraints'),
                            group_by_fields=kwargs.get('group_by_fields'),
                            time_series=kwargs.get('time_series'),
                            time_window_grouping=kwargs.get('time_window_grouping'),
                            aggregation_function=kwargs.get('aggregation_function'),
                            aggregation_field=kwargs.get('aggregation_field'),
                            limit=kwargs.get('limit'),
                            query_id=kwargs.get('query_id'),
                           )

    def incremental_aggregation_query(self, **kwargs):
        """
        Continue an aggregation query

        @type query_id: L{com.vmware.loginsight.api.types.Strata.StrataQueryId}
        @kwarg query_id: ID of this query
        @type wait_millis: C{long} or C{None}
        @kwarg wait_millis: Amount of time to wait for results to return
        @rtype: L{com.vmware.loginsight.api.types.Strata.StrataQueryResult}
        @return: StrataQueryResult
        @raise L{vmware.vapi.bindings.error.InvalidRequest}: 
        @raise L{vmware.vapi.bindings.error.TimedOut}: 
        @raise L{vmware.vapi.bindings.error.InternalServerError}: 
        """
        self._validate_kwargs('incremental_aggregation_query', kwargs)
        return self._invoke('incremental_aggregation_query',
                            query_id=kwargs.get('query_id'),
                            wait_millis=kwargs.get('wait_millis'),
                           )

    def index_messages(self, **kwargs):
        """
        Submit a list of messages for indexing.

        @type messages: C{list} of L{com.vmware.loginsight.api.types.Strata.StrataMessage}
        @kwarg messages: List of messages to index.
        @type parser_name: C{str} or C{None}
        @kwarg parser_name: Parser to use.
        @raise L{vmware.vapi.bindings.error.InvalidRequest}: 
        @raise L{vmware.vapi.bindings.error.TimedOut}: 
        @raise L{vmware.vapi.bindings.error.InternalServerError}: 
        """
        self._validate_kwargs('index_messages', kwargs)
        return self._invoke('index_messages',
                            messages=kwargs.get('messages'),
                            parser_name=kwargs.get('parser_name'),
                           )

    def get_message(self, **kwargs):
        """
        Retrieve a log message by given message ID.

        @type message_id: L{com.vmware.loginsight.api.types.Strata.StrataMessageId}
        @kwarg message_id: globally unique message ID.
        @rtype: L{com.vmware.loginsight.api.types.Strata.StrataMessage}
        @return: log message
        @raise L{vmware.vapi.bindings.error.InvalidRequest}: if the message ID cannot be found
        @raise L{vmware.vapi.bindings.error.TimedOut}: 
        @raise L{vmware.vapi.bindings.error.InternalServerError}: 
        """
        self._validate_kwargs('get_message', kwargs)
        return self._invoke('get_message',
                            message_id=kwargs.get('message_id'),
                           )

    def flush_index(self, **kwargs):
        """
        Flush all pending messages in ingestion pipeline to permanent storage
        and make them available to search.

        @type timeout_millis: C{long} or C{None}
        @kwarg timeout_millis: timeout in milliseconds. If it is not present or
        it is 0, there is no timeout.
        @rtype: C{bool}
        @return: true if flush succeeded; false otherwise.
        @raise L{vmware.vapi.bindings.error.TimedOut}: 
        @raise L{vmware.vapi.bindings.error.InternalServerError}: 
        """
        self._validate_kwargs('flush_index', kwargs)
        return self._invoke('flush_index',
                            timeout_millis=kwargs.get('timeout_millis'),
                           )

    def get_config(self):
        """
        Retrieve current user configuration.

        @rtype: C{str}
        @return: XML string of all user-configurable options.
        @raise L{vmware.vapi.bindings.error.InternalServerError}: 
        """
        return self._invoke('get_config')

    def get_default_config(self):
        """
        Retrieve the system default configuration.

        @rtype: C{str}
        @return: XML string with default values of all user-configurable options.
        @raise L{vmware.vapi.bindings.error.InternalServerError}: 
        """
        return self._invoke('get_default_config')

    def set_config(self, **kwargs):
        """
        Set user configuration.

        @type xml: C{str}
        @kwarg xml: User configuration in XML format.
        @raise L{vmware.vapi.bindings.error.InvalidRequest}: If XML format is invalid or if one or
        more provided values of configuration are not valid
        @raise L{vmware.vapi.bindings.error.InternalServerError}: if saving the configuration failed
        or configuration could not be retrieved
        """
        self._validate_kwargs('set_config', kwargs)
        return self._invoke('set_config',
                            xml=kwargs.get('xml'),
                           )

    def get_version(self):
        """
        Retrieve current version information.

        @rtype: L{com.vmware.loginsight.api.types.Strata.StrataVersionInfo}
        @return: Version information.
        @raise L{vmware.vapi.bindings.error.InternalServerError}: 
        """
        return self._invoke('get_version')

class StrataStub(ApiInterfaceStub):
    StrataTypeType = EnumType('StrataType')
    StrataConstraintOperatorType = EnumType('StrataConstraintOperator')
    StrataGroupByTypeType = EnumType('StrataGroupByType')
    StrataAggregationFunctionType = EnumType('StrataAggregationFunction')

    StrataMatchingTermType = StructType('com.vmware.loginsight.api.strata.strata_matching_term', {
        'start_offset': IntegerType(),
        'value': StringType(),
        },
        Strata.StrataMatchingTerm,
    )
    StrataValueType = StructType('com.vmware.loginsight.api.strata.strata_value', {
        'type': ReferenceType(locals(), 'StrataTypeType'),
        'value': StringType(),
        'numeric_value': OptionalType(DoubleType()),
        },
        Strata.StrataValue,
    )
    StrataFieldType = StructType('com.vmware.loginsight.api.strata.strata_field', {
        'name': StringType(),
        'value': ReferenceType(locals(), 'StrataValueType'),
        'is_extracted': OptionalType(BooleanType()),
        'start_offset': OptionalType(IntegerType()),
        },
        Strata.StrataField,
    )
    StrataFacetingFieldType = StructType('com.vmware.loginsight.api.strata.strata_faceting_field', {
        'name': StringType(),
        'is_number': BooleanType(),
        'is_extracted': BooleanType(),
        },
        Strata.StrataFacetingField,
    )
    StrataQueryConstraintType = StructType('com.vmware.loginsight.api.strata.strata_query_constraint', {
        'field_name': StringType(),
        'field_val': StringType(),
        'operator': ReferenceType(locals(), 'StrataConstraintOperatorType'),
        },
        Strata.StrataQueryConstraint,
    )
    StrataQueryConstraintsType = StructType('com.vmware.loginsight.api.strata.strata_query_constraints', {
        'constraints': OptionalType(ListType(ListType(ReferenceType(locals(), 'StrataQueryConstraintType')))),
        },
        Strata.StrataQueryConstraints,
    )
    StrataQueryIdType = StructType('com.vmware.loginsight.api.strata.strata_query_id', {
        'id': StringType(),
        },
        Strata.StrataQueryId,
    )
    StrataQueryStatusType = StructType('com.vmware.loginsight.api.strata.strata_query_status', {
        'id': ReferenceType(locals(), 'StrataQueryIdType'),
        'elapse': IntegerType(),
        'pending': BooleanType(),
        },
        Strata.StrataQueryStatus,
    )
    StrataMessageIdType = StructType('com.vmware.loginsight.api.strata.strata_message_id', {
        'bucket_high': IntegerType(),
        'bucket_low': IntegerType(),
        'segment_offset': IntegerType(),
        'message_index': IntegerType(),
        },
        Strata.StrataMessageId,
    )
    StrataMessageType = StructType('com.vmware.loginsight.api.strata.strata_message', {
        'message_text': StringType(),
        'message_id': OptionalType(ReferenceType(locals(), 'StrataMessageIdType')),
        'message_timestamp': OptionalType(IntegerType()),
        'arrival_timestamp': OptionalType(IntegerType()),
        'matching_terms': OptionalType(ListType(ReferenceType(locals(), 'StrataMatchingTermType'))),
        'fields': OptionalType(ListType(ReferenceType(locals(), 'StrataFieldType'))),
        },
        Strata.StrataMessage,
    )
    StrataTableType = StructType('com.vmware.loginsight.api.strata.strata_table', {
        'headers': ListType(StringType()),
        'values': ListType(ListType(ReferenceType(locals(), 'StrataValueType'))),
        },
        Strata.StrataTable,
    )
    StrataQueryResultType = StructType('com.vmware.loginsight.api.strata.strata_query_result', {
        'query_id': ReferenceType(locals(), 'StrataQueryIdType'),
        'messages': ListType(ReferenceType(locals(), 'StrataMessageType')),
        'faceting_fields': ListType(ReferenceType(locals(), 'StrataFacetingFieldType')),
        'table': OptionalType(ReferenceType(locals(), 'StrataTableType')),
        'more_incremental_results': BooleanType(),
        'total': IntegerType(),
        },
        Strata.StrataQueryResult,
    )
    StrataVersionInfoType = StructType('com.vmware.loginsight.api.strata.strata_version_info', {
        'version': StringType(),
        'major': IntegerType(),
        'minor': IntegerType(),
        'revision': IntegerType(),
        'build': StringType(),
        'packager': StringType(),
        'timestamp': IntegerType(),
        },
        Strata.StrataVersionInfo,
    )
    StrataGroupByFieldType = StructType('com.vmware.loginsight.api.strata.strata_group_by_field', {
        'field_name': StringType(),
        'group_by_type': ReferenceType(locals(), 'StrataGroupByTypeType'),
        'group_by_value': StringType(),
        },
        Strata.StrataGroupByField,
    )

    def __init__(self, impl, api_provider):
        ApiInterfaceStub.__init__(self, iface_name='com.vmware.loginsight.api.strata',
                                  impl=impl, api_provider=api_provider)


    class _GenerateQueryIdMethod(ApiMethodStub):
        def __init__(self, **kwargs):
            input_type = {}
            ApiMethodStub.__init__(self, name='generate_query_id',
                                   input_type=StructType('com.vmware.loginsight.api.strata.generate_query_id_input', input_type),
                                   output_type=ReferenceType(StrataStub, 'StrataQueryIdType'),
                                   **kwargs)

    class _CancelQueryMethod(ApiMethodStub):
        def __init__(self, **kwargs):
            input_type = {
                'query_id': ReferenceType(StrataStub, 'StrataQueryIdType'),
                }
            ApiMethodStub.__init__(self, name='cancel_query',
                                   input_type=StructType('com.vmware.loginsight.api.strata.cancel_query_input', input_type),
                                   output_type=VoidType(),
                                   **kwargs)

    class _ListQueriesMethod(ApiMethodStub):
        def __init__(self, **kwargs):
            input_type = {}
            ApiMethodStub.__init__(self, name='list_queries',
                                   input_type=StructType('com.vmware.loginsight.api.strata.list_queries_input', input_type),
                                   output_type=ListType(ReferenceType(StrataStub, 'StrataQueryStatusType')),
                                   **kwargs)

    class _PiqlQueryMethod(ApiMethodStub):
        def __init__(self, **kwargs):
            input_type = {
                'query': StringType(),
                'wait_millis': OptionalType(IntegerType()),
                'from_result': OptionalType(IntegerType()),
                'count': OptionalType(IntegerType()),
                'query_id': OptionalType(ReferenceType(StrataStub, 'StrataQueryIdType')),
                }
            ApiMethodStub.__init__(self, name='piql_query',
                                   input_type=StructType('com.vmware.loginsight.api.strata.piql_query_input', input_type),
                                   output_type=ReferenceType(StrataStub, 'StrataQueryResultType'),
                                   **kwargs)

    class _MessageQueryMethod(ApiMethodStub):
        def __init__(self, **kwargs):
            input_type = {
                'query': OptionalType(StringType()),
                'wait_millis': OptionalType(IntegerType()),
                'from_result': OptionalType(IntegerType()),
                'count': OptionalType(IntegerType()),
                'start_time_millis': OptionalType(IntegerType()),
                'end_time_millis': OptionalType(IntegerType()),
                'constraints': OptionalType(ReferenceType(StrataStub, 'StrataQueryConstraintsType')),
                'query_id': OptionalType(ReferenceType(StrataStub, 'StrataQueryIdType')),
                }
            ApiMethodStub.__init__(self, name='message_query',
                                   input_type=StructType('com.vmware.loginsight.api.strata.message_query_input', input_type),
                                   output_type=ReferenceType(StrataStub, 'StrataQueryResultType'),
                                   **kwargs)

    class _IncrementalMessageQueryMethod(ApiMethodStub):
        def __init__(self, **kwargs):
            input_type = {
                'query_id': ReferenceType(StrataStub, 'StrataQueryIdType'),
                'wait_millis': OptionalType(IntegerType()),
                }
            ApiMethodStub.__init__(self, name='incremental_message_query',
                                   input_type=StructType('com.vmware.loginsight.api.strata.incremental_message_query_input', input_type),
                                   output_type=ReferenceType(StrataStub, 'StrataQueryResultType'),
                                   **kwargs)

    class _AggregationQueryMethod(ApiMethodStub):
        def __init__(self, **kwargs):
            input_type = {
                'query': OptionalType(StringType()),
                'wait_millis': OptionalType(IntegerType()),
                'start_time_millis': OptionalType(IntegerType()),
                'end_time_millis': OptionalType(IntegerType()),
                'constraints': OptionalType(ReferenceType(StrataStub, 'StrataQueryConstraintsType')),
                'group_by_fields': OptionalType(ListType(ReferenceType(StrataStub, 'StrataGroupByFieldType'))),
                'time_series': OptionalType(BooleanType()),
                'time_window_grouping': OptionalType(IntegerType()),
                'aggregation_function': OptionalType(ReferenceType(StrataStub, 'StrataAggregationFunctionType')),
                'aggregation_field': OptionalType(StringType()),
                'limit': OptionalType(IntegerType()),
                'query_id': OptionalType(ReferenceType(StrataStub, 'StrataQueryIdType')),
                }
            ApiMethodStub.__init__(self, name='aggregation_query',
                                   input_type=StructType('com.vmware.loginsight.api.strata.aggregation_query_input', input_type),
                                   output_type=ReferenceType(StrataStub, 'StrataQueryResultType'),
                                   **kwargs)

    class _IncrementalAggregationQueryMethod(ApiMethodStub):
        def __init__(self, **kwargs):
            input_type = {
                'query_id': ReferenceType(StrataStub, 'StrataQueryIdType'),
                'wait_millis': OptionalType(IntegerType()),
                }
            ApiMethodStub.__init__(self, name='incremental_aggregation_query',
                                   input_type=StructType('com.vmware.loginsight.api.strata.incremental_aggregation_query_input', input_type),
                                   output_type=ReferenceType(StrataStub, 'StrataQueryResultType'),
                                   **kwargs)

    class _IndexMessagesMethod(ApiMethodStub):
        def __init__(self, **kwargs):
            input_type = {
                'messages': ListType(ReferenceType(StrataStub, 'StrataMessageType')),
                'parser_name': OptionalType(StringType()),
                }
            ApiMethodStub.__init__(self, name='index_messages',
                                   input_type=StructType('com.vmware.loginsight.api.strata.index_messages_input', input_type),
                                   output_type=VoidType(),
                                   **kwargs)

    class _GetMessageMethod(ApiMethodStub):
        def __init__(self, **kwargs):
            input_type = {
                'message_id': ReferenceType(StrataStub, 'StrataMessageIdType'),
                }
            ApiMethodStub.__init__(self, name='get_message',
                                   input_type=StructType('com.vmware.loginsight.api.strata.get_message_input', input_type),
                                   output_type=ReferenceType(StrataStub, 'StrataMessageType'),
                                   **kwargs)

    class _FlushIndexMethod(ApiMethodStub):
        def __init__(self, **kwargs):
            input_type = {
                'timeout_millis': OptionalType(IntegerType()),
                }
            ApiMethodStub.__init__(self, name='flush_index',
                                   input_type=StructType('com.vmware.loginsight.api.strata.flush_index_input', input_type),
                                   output_type=BooleanType(),
                                   **kwargs)

    class _GetConfigMethod(ApiMethodStub):
        def __init__(self, **kwargs):
            input_type = {}
            ApiMethodStub.__init__(self, name='get_config',
                                   input_type=StructType('com.vmware.loginsight.api.strata.get_config_input', input_type),
                                   output_type=StringType(),
                                   **kwargs)

    class _GetDefaultConfigMethod(ApiMethodStub):
        def __init__(self, **kwargs):
            input_type = {}
            ApiMethodStub.__init__(self, name='get_default_config',
                                   input_type=StructType('com.vmware.loginsight.api.strata.get_default_config_input', input_type),
                                   output_type=StringType(),
                                   **kwargs)

    class _SetConfigMethod(ApiMethodStub):
        def __init__(self, **kwargs):
            input_type = {
                'xml': StringType(),
                }
            ApiMethodStub.__init__(self, name='set_config',
                                   input_type=StructType('com.vmware.loginsight.api.strata.set_config_input', input_type),
                                   output_type=VoidType(),
                                   **kwargs)

    class _GetVersionMethod(ApiMethodStub):
        def __init__(self, **kwargs):
            input_type = {}
            ApiMethodStub.__init__(self, name='get_version',
                                   input_type=StructType('com.vmware.loginsight.api.strata.get_version_input', input_type),
                                   output_type=ReferenceType(StrataStub, 'StrataVersionInfoType'),
                                   **kwargs)

