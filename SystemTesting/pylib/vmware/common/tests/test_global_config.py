import vmware.common.global_config as global_config


global_config.configure_global_pylogger(
    log_dir='/tmp', log_prefix='test1', log_level='ERROR',
    logfile_level='DEBUG')
pylogger = global_config.pylogger
pylogger.info('Test1 debug should appear in file only')
pylogger.info('Test1 info should appear in file only')
pylogger.warn('Test1 warn should appear in file only')
pylogger.error('Test1 error message should appear in file and stdout')

global_config.configure_global_pylogger(
    log_dir='/tmp', log_prefix='test2', log_level='DEBUG',
    logfile_level='DEBUG')
pylogger = global_config.pylogger
pylogger.info('Test2 debug message should appear in file and stdout')
pylogger.info('Test2 info message should appear in file and stdout')
pylogger.warn('Test2 warn message should appear in file and stdout')
pylogger.error('Test2 error message should appear in file and stdout')
