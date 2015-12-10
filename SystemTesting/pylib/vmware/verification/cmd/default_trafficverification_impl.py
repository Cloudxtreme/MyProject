import vmware.interfaces.traffic_verification_interface as \
    traffic_verification_interface
import vmware.verification.cmd.tshark_trafficverification_impl as \
    tshark_trafficverification_impl

class_map = {
    'tshark': tshark_trafficverification_impl.TSharkTrafficVerificationImpl()}


class DefaultTrafficVerificationImpl(
        traffic_verification_interface.TrafficVerificationInterface):

    @classmethod
    def generate_capture_file_name(cls, client_object, tool=None, **kwargs):
        return class_map[tool].generate_capture_file_name(client_object,
                                                          **kwargs)

    @classmethod
    def start_capture(cls, client_object, tool=None, **kwargs):
        return class_map[tool].start_capture(client_object, **kwargs)

    @classmethod
    def stop_capture(cls, client_object, tool=None, **kwargs):
        return class_map[tool].stop_capture(client_object, **kwargs)

    @classmethod
    def delete_capture_file(cls, client_object, tool=None, **kwargs):
        return class_map[tool].delete_capture_file(client_object, **kwargs)

    @classmethod
    def extract_capture_results(cls, client_object, tool=None, **kwargs):
        return class_map[tool].extract_capture_results(client_object, **kwargs)

    @classmethod
    def get_ipfix_capture_data(cls, client_object, tool=None, **kwargs):
        return class_map[tool].get_ipfix_capture_data(client_object, **kwargs)

    @classmethod
    def get_capture_data(cls, client_object, tool=None, **kwargs):
        return class_map[tool].get_capture_data(client_object, **kwargs)

    @classmethod
    def get_captured_packet_count(cls, client_object, tool=None, **kwargs):
        return class_map[tool].get_captured_packet_count(client_object,
                                                         **kwargs)
