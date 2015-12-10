class ProfileInterface(object):

    @classmethod
    def check_compliance(cls, client_object, profile=None,
                         entity=None, **kwargs):
        """Interface to check compliance of an entity against a profile"""
        raise NotImplementedError

    @classmethod
    def associate_profile(cls, client_object, **kwargs):
        """Associates a profile"""
        raise NotImplementedError

    @classmethod
    def get_profile_info(cls, client_object, subprofile=None, **kwargs):
        """Returns subprofile information"""
        raise NotImplementedError

    @classmethod
    def get_network_policy_info(cls, client_object, category=None,
                                network_device=None, **kwargs):
        """Returns the specified policy for the network category"""
        raise NotImplementedError

    @classmethod
    def apply_profile(cls, client_object, **kwargs):
        """Applies a profile to the host"""
        raise NotImplementedError

    @classmethod
    def export_answer_file(cls, client_object, **kwargs):
        """Exports an answer file"""
        raise NotImplementedError

    @classmethod
    def import_answer_file(cls, client_object, **kwargs):
        """Imports an answer file"""
        raise NotImplementedError

    @classmethod
    def update_ip_address_option(cls, client_object, **kwargs):
        """Updates host's IP and subnet-mask in answer file."""
        raise NotImplementedError

    @classmethod
    def update_answer_file(cls, client_object, **kwargs):
        """Updates host's answer file."""
        raise NotImplementedError

    @classmethod
    def get_answer_file(cls, client_object, **kwargs):
        """Retrieves the host's answer file"""
        raise NotImplementedError
