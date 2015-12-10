import eventlet
import os
from datetime import datetime
from pprint import pprint
import vmware.common.global_config as global_config

pylogger = global_config.pylogger

#
# Not all modules on local OS supports greenlets
# applying monkey patch to ensure that these modules
# are greenlet friendly
# Ref: http://eventlet.net/doc/basic_usage.html
#
eventlet.monkey_patch()
#eventlet.debug.hub_prevent_multiple_readers(False)

if ('VDNET_PYLIB_THREADS' in os.environ.keys()):
    num_threads = int(os.environ['VDNET_PYLIB_THREADS'])
else:
    num_threads = 30

def thread_decorate(func):
    pool = eventlet.GreenPool(num_threads)
    options = {}
    time_start = datetime.now()
    def thread_wrapper(template_obj, pydict_array=None, *args):
        threads_array = []
        result_array = []
        if not isinstance(pydict_array, list):
            pylogger.debug("No array of pydicts...")
            result = func(template_obj, pydict_array)
            import inspect
            if inspect.getdoc(func):
                if 'delete' in inspect.getdoc(func).lower():
                    return result
            result_array.append(result)
            return result_array
        if ('VDNET_PYLIB_THREADS' not in os.environ.keys()):
            pylogger.debug("No threads...")
            for py_dict in pydict_array:
                pylogger.debug("py_dict: %s " % py_dict)
                schema_object = template_obj.get_schema_object(py_dict)
                result = func(template_obj, schema_object)
                result_array.append(result)
        else:
            pylogger.debug("Running threads...")
            if len(threads_array) > 0:
                threads_array = []
            for py_dict in pydict_array:
                pylogger.debug("py_dict: %s " % py_dict)
                if isinstance(py_dict, dict):
                    schema_object = template_obj.get_schema_object(py_dict)
                else:
                    schema_object = None
                    template_obj = py_dict
                thread = pool.spawn(func, template_obj, schema_object)
                threads_array.append(thread)
            # Wait til the threads finish
            if pool.running():
                pool.waitall()
            if len(result_array) > 0:
                result_array = []
            # Now get the return values for each thread
            for thread in threads_array:
                result = thread.wait()
                result_array.append(result)
        time_end = datetime.now()
        total_time = time_end - time_start
        pylogger.debug("Total number of components %s " % len(pydict_array))
        pylogger.debug("Time taken in secs %s " % total_time.seconds)
        pylogger.debug("Total result objects %s " % len(result_array))
        return result_array
    return thread_wrapper

class Tasks:
    def __init__(self):
        self.timeout= None
        self.num_threads = None

    # For unit testing thread decorator
    @thread_decorate
    def get_text1(elem, array):
        print "In get_text1: %s " % elem
        return 1

if __name__=='__main__':
    task_obj = Tasks()
    array = [1,2,3,4]
    return_array = task_obj.get_text1("A", array)
    print str(return_array)[1:-1]
