import time
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


def wait_for_task_completion(task, wait_time=180, poll_interval=0):
    startTime = time.time()
    while (time.time() - startTime < wait_time):
        time.sleep(poll_interval)
        if task.info.state == "success":
            pylogger.debug("Task %s is successful" % task.info.descriptionId)
            return task
        elif task.info.state == "error":
            pylogger.error("Task %s threw an error" % task.info.descriptionId)
            raise Exception(task.info.error)
            break
    raise Exception("Task %s timed out after %d seconds, current state: %s"
                    % (task.info.descriptionId, wait_time, task.info.state))


def get_task_state(task):
    if hasattr(task, 'info'):
        result = wait_for_task_completion(task)
        pylogger.info("Result of %r = %r" %
                      (task.info.descriptionId, result.info.state))
        return result.info.state
