import eventlet
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


class EventletGreenPool(eventlet.GreenPool):
    """
    Class that can be used to run tasks in a thread pool such that if one
    of the running tasks returns an exception then waitall() will throw an
    exception.

    Note: This class is not thread safe if it is used within other threads
    since multiple threads can manipulate the pool and this implementation
    doesn't implement locks yet.
    """
    def __init__(self, *args, **kwargs):
        super(EventletGreenPool, self).__init__(*args, **kwargs)
        self._pool = []
        self._results = []

    def spawn(self, *args, **kwargs):
        t = super(EventletGreenPool, self).spawn(*args, **kwargs)
        t.waited_on = None
        if t not in self._pool:
            self._pool.append(t)
        return t

    def waitall(self, *args, **kwargs):
        super(EventletGreenPool, self).waitall(*args, **kwargs)
        for t in self._pool[:]:
            if t.waited_on is None:
                self._results.append(t.wait())
                t.waited_on = True

    def get_results(self):
        if self.running():
            pylogger.debug("Thread pool is still running, will wait for "
                           "it to finish ...")
            self.waitall()
        return self._results
