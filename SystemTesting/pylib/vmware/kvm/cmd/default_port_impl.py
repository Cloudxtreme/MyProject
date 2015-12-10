import pprint

import vmware.common.global_config as global_config
import vmware.interfaces.port_interface as port_interface

pylogger = global_config.pylogger


class Error(Exception):
    """General Error"""
    pass


class DefaultPortImpl(port_interface.PortInterface):

    @classmethod
    def get_port_qos_info(cls, client_object, get_port_qos_info=None):
        port_attributes_map = {'table': []}
        _dedupe_map = {}
        pylogger.info("Getting Qos Queue configuration from OVSDB")
        # OVSDB does not have a query opportunity to filter data at the host
        # due to the filter value is a partial string match. Inspect the
        # entire Queue table in local memory.
        qos_queues = client_object.ovsdb.Queue.get_all()
        for q in qos_queues:
            # Queue external_ids name field includes LPort identifier in a
            # period-delimited string.
            # Ex. name="817d6270-6760-4ef6-98b0-4de86d70385b.16cf763a-570b-4736-9df5-715c23b38c84"  # noqa
            lport_id = q.external_ids['name'].split('.')
            try:
                lport_id = lport_id[1]
            except IndexError:
                pylogger.trace("VIF ID not found, using full 'name' value as "
                               "ID: %s" % lport_id)
            # TODO(jschmidt): The key names in 'record' are common with net-dvs
            # port parser used in related ESX implementation. Instead use
            # shared constants for the key names.
            record = {'port': lport_id}
            # Unsupported QoS attributes for KVM
            record['burst_size'] = None
            record['peak_bandwidth'] = None
            record['class_of_service'] = None
            # Supported QoS attributes for KVM
            min_rate = q.other_config.get('min-rate')
            max_rate = q.other_config.get('max-rate')
            if min_rate != max_rate:
                raise Error("Expect Queue min and max rate the same for "
                            "average_bandwidth configuration, got min=%s, "
                            "max=%s" % (min_rate, max_rate))
            else:
                record['average_bandwidth'] = min_rate
            if q.dscp == set():
                record['dscp'] = None
                record['mode'] = 'trusted'
            else:
                record['dscp'] = q.dscp
                record['mode'] = 'untrusted'
            # Queue records are duplicated toward each pairing of logical port
            # ID and transport port ID. Make a simplifying design using the
            # expectation that Queue configuration is the same toward all
            # records. De-duplicate the table.
            if lport_id in _dedupe_map:
                if record != _dedupe_map[lport_id]:
                    pylogger.error("Expected queue:\n%s\nActual queue:\n%s" %
                                   pprint.pformat(_dedupe_map[lport_id]),
                                   pprint.pformat(record))
                    raise Error("Expect all Queue records for same LPort to "
                                "be equal, got difference for LPort '%s'" %
                                lport_id)
                else:
                    pylogger.debug("Ignoring duplicate Queue record for "
                                   "LPort '%s'" % lport_id)
            else:
                _dedupe_map[lport_id] = record
        port_attributes_map['table'].extend(_dedupe_map.values())
        return port_attributes_map
