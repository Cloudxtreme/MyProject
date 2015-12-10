from vmware.common.global_config import pylogger


class TestInventory():

    def __init__(self):
        """ Constructor to create TestInventory object
        """
        self.id = None

    def fubar(self, tmp):
        """ Constructor to create TestInventory object
        """
        result_obj = {}
        result_obj['status_code'] = '0'
        result_obj['response_data'] = 'Successfully set fubar'
        pylogger.info("Successfully called fubar")
        return result_obj

if __name__ == '__main__':
    ti = TestInventory()
