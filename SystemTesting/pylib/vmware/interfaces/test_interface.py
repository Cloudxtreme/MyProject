class TestInterface(object):

    @classmethod
    def verify_ui_component(cls, client_obj, test_name=None, **kwargs):
        """
        Verify the UI operation through UAS
        """
        raise NotImplementedError
