import time as time

import vmware.common.global_config as global_config
import vmware.interfaces.log_server_interface as logging_server_interface
import strata_client as strata_client


pylogger = global_config.pylogger


class LOGINSIGHT23LogServerImpl(
        logging_server_interface.LogServerInterface):

    filter_keys_map = {
        'user_name': 'UserName:',
        'module_name': 'ModuleName:',
        'operation': 'Operation:',
        'operation_status': 'Operation status:',
        'log_type': '',
        'manager_ip': ''
    }

    @classmethod
    def verify_audit_logs(cls, client_object, **kwargs):
        query = ''
        count = 0
        start_time = 0
        verification_result = 'SUCCESS'
        filter_keys = kwargs["filter_keys"]
        pylogger.info("kwargs : %s" % kwargs)
        for key in filter_keys:
            if key == 'count':
                count = int(filter_keys['count'])
            elif key == 'interval':
                start_time = int(round(time.time())
                                 - (5.5 * 60 * 60
                                    + int(filter_keys['interval'])))
            else:
                filter_key = cls.filter_keys_map[key]
                query = query + filter_key + filter_keys[key] + ", "
        pylogger.info("Query : %s" % query)
        strata = strata_client.Strata(client_object.get_connection())
        strata.StrataQueryResult = strata.message_query(
            query="'" + query[:-2] + "'",
            count=count, start_time_millis=start_time)
        strata.StrataMessage = strata.StrataQueryResult.messages
        if len(strata.StrataMessage) != count:
            verification_result = 'FAILURE'
            pylogger.info("The strata message count doesn't match")
            return verification_result
        for message in strata.StrataMessage:
            pylogger.info("Strata Message : %s" % (message.message_text))
            filters = message.message_text.split(',')
            for filter in filters:
                filter = filter.lstrip()
                if 'UserName:' in filter:
                    if ((filter_keys['manager_ip'] not in filter)
                            and (filter_keys['log_type'] not in filter)
                            and (filter_keys['user_name'] not in filter)):
                        verification_result = 'FAILURE'
                elif filter.startswith('ModuleName:'):
                    if filter.split(':')[1].replace("'", '') != \
                            filter_keys['module_name']:
                        verification_result = 'FAILURE'
                elif filter.startswith('Operation:'):
                    if filter.split(':')[1].replace("'", '') != \
                            filter_keys['operation']:
                        verification_result = 'FAILURE'
                elif filter.startswith('Operation status:'):
                    if filter.split(':')[1].replace("'", '') != \
                            filter_keys['operation_status']:
                        verification_result = 'FAILURE'
                if verification_result == 'FAILURE':
                    pylogger.info("The strata message verification failed")
                    return verification_result
        return verification_result
