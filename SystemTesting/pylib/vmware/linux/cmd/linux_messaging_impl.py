import json
import pprint

import vmware.common as common
import vmware.common.global_config as global_config
import vmware.interfaces.messaging_interface as messaging_interface
import vmware.linux.linux_helper as linux_helper

pylogger = global_config.pylogger
Linux = linux_helper.Linux


class LinuxMessagingImpl(messaging_interface.MessagingInterface):
    """Command based NSX related operations"""

    # TODO - mihaid - Seperate out json file parsing
    # TODO - mihaid - Investigate opportunity for code reuse

    @classmethod
    def _get_mpaconfig(cls, client_object):
        '''
        CAT the mpa config file

        @rtype: string
        @return: Contents of mpaconfig.json file
        '''
        cmd = 'cat %s' % global_config.DEFAULT_MPA_CONFIG
        result = None
        try:
            result = client_object.connection.request(cmd, strict=False)
            pylogger.debug("Content of mpaconfig.json %s",
                           result.response_data)
        except Exception as error:
            pylogger.error("Failed to cat mpaconfig.json: %s" % error)
            raise
        content = result.response_data
        return content

    # TODO - mihaid - Deprecated, check tests that still use and remove
    @classmethod
    def read_master_broker_ip(cls, client_object,
                              read_master_broker_ip=None):
        '''
        Read the master broker IP

        @rtype: dictionary
        @return: {'master_broker_ip': <Result>}
        '''
        _ = read_master_broker_ip
        master_broker_ip = None
        content = cls._get_mpaconfig(client_object)
        data = json.loads(content)
        brokerlist = data["RmqBrokerCluster"]
        for item in brokerlist:
            if "true" in item["BrokerIsMaster"].lower():
                master_broker_ip = item["BrokerIpAddress"]
                break
        pylogger.debug("Found master_broker_ip %s" % master_broker_ip)
        result_dict = {'master_broker_ip': master_broker_ip}
        return result_dict

    @classmethod
    def get_broker_ip(cls, client_object, num=0):
        '''
        Helper for getting the connected broker IP in an mpaconfig

        @type num: integer
        @param num: Entry of broker on mpaconfig list (starts at 0 for master)
        @rtype: string
        @return: Broker ip address from mpaconfig
        '''
        content = cls._get_mpaconfig(client_object)
        data = json.loads(content)
        try:
            mp_ip = \
                data["RmqBrokerCluster"][num]["BrokerIpAddress"]
            pylogger.debug('Broker IP: %s' % mp_ip)
            return mp_ip

        except IndexError:
            pylogger.error("Broker ip not found in: %s" %
                           pprint.pformat(data))
            raise ValueError('Missing broker ip in mpa config')

    @classmethod
    def get_broker_port(cls, client_object, num=0):
        '''
        Helper for getting the port in an mpaconfig

        @type num: integer
        @param num: Entry of broker on mpaconfig list (starts at 0 for master)
        @rtype: string
        @return: Broker port from mpaconfig
        '''
        content = cls._get_mpaconfig(client_object)
        data = json.loads(content)
        try:
            port = \
                data["RmqBrokerCluster"][num]["BrokerPort"]
            pylogger.debug('Port: %s' % port)
            return port

        except IndexError:
            pylogger.error("Broker port not found in: %s" %
                           pprint.pformat(data))
            raise ValueError('Missing port in mpa config')

    @classmethod
    def get_broker_thumbprint(cls, client_object, num=0):
        '''
        Helper for getting the thumbprint in an mpaconfig

        @type num: integer
        @param num: Entry of broker on mpaconfig list (starts at 0 for master)
        @rtype: string
        @return: Broker thumbprint from mpaconfig
        '''
        content = cls._get_mpaconfig(client_object)
        data = json.loads(content)
        try:
            thumbprint = \
                data["RmqBrokerCluster"][num]["BrokerSslCertThumbprint"]
            pylogger.debug('BrokerSslCertThumbprint: %s' % thumbprint)
            return thumbprint

        except IndexError:
            pylogger.error("Broker thumbprint not found in: %s" %
                           pprint.pformat(data))
            raise ValueError('Missing thumbprint in mpa config')

    @classmethod
    def get_client_token(cls, client_object):
        '''
        Helper for getting the account name/client-token in an mpaconfig

        @rtype: string
        @return: Account name/client-token from mpaconfig
        '''
        content = cls._get_mpaconfig(client_object)
        data = json.loads(content)
        try:
            token = \
                data["AccountName"]
            pylogger.debug('Client-token: %s' % token[7:])
            return token[7:]

        except IndexError:
            pylogger.error("Client token not found in: %s" %
                           pprint.pformat(data))
            raise ValueError('Missing client-token in mpa config')

    @classmethod
    def read_client_token(cls, client_object, read_client_token=None):
        '''
        Helper method to return the account name/client-token as a k,v pair
        to persist across workloads

        @type read_client_token: dict
        @param read_client_token: Dict for persisting data across workloads,
            not a argument used in the function. Passed in because of VDNet
            artifacts.
        @rtype: dict
        @return : Client Token from the mpa config file
        '''
        _ = read_client_token
        client_token = cls.get_client_token(client_object)
        pylogger.debug("Found client_token %s" % client_token)
        result_dict = {'client_token': client_token}
        return result_dict

    @classmethod
    def read_broker_ip(cls, client_object, num=0, read_broker_ip=None):
        '''
        Helper method to return the broker ip as a k,v pair
        to persist across workloads

        @type num: integer
        @param num: Entry of broker on mpaconfig list (starts at 0 for master)
        @type read_broker_ip: dict
        @param read_broker_ip: Dict for persisting data, not a argument used
            in the function. Passed in because of VDNet artifacts.
        @rtype: dictionary
        @return: {'broker_ip': <Result>}
        '''
        _ = read_broker_ip
        count = int(num)
        content = cls._get_mpaconfig(client_object)
        data = json.loads(content)
        brokerlist = data["RmqBrokerCluster"]
        if count is 0:
            for item in brokerlist:
                if "true" in item["BrokerIsMaster"].lower():
                    broker_ip = item["BrokerIpAddress"]
                    break
        else:
            broker_ip = cls.get_broker_ip(client_object, count)
        pylogger.debug("Found broker_ip %s" % broker_ip)
        result_dict = {'ip': broker_ip}
        return result_dict

    @classmethod
    def read_broker_port(cls, client_object, num=0, read_broker_port=None):
        '''
        Helper method to return the broker port as a k,v pair
        to persist across workloads

        @type num: integer
        @param num: Entry of broker on mpaconfig list (starts at 0 for master)
        @type read_broker_port: dict
        @param read_broker_port: Dict for persisting data, not a argument used
            in the function. Passed in because of VDNet artifacts.
        @rtype: dict
        @return : Broker port from config file
        '''
        _ = read_broker_port
        count = int(num)
        broker_port = cls.get_broker_port(client_object, count)
        pylogger.debug("Found broker_port %s" % broker_port)
        result_dict = {'broker_port': broker_port}
        return result_dict

    @classmethod
    def read_broker_thumbprint(cls, client_object, num=0,
                               read_broker_thumbprint=None):
        '''
        Helper method to return the broker thumbprint as a k,v pair
        to persist across workloads

        @type num: integer
        @param num: Entry of broker on mpaconfig list (starts at 0 for master)
        @type read_broker_thumbprint: dict
        @param read_broker_thumbprint: Dict for persisting data, not a argument
            used in the function. Passed in because of VDNet artifacts.
        Passed in because of VDNet artifacts
        @rtype: dict
        @return : Broker thumbprint from config file
        '''
        _ = read_broker_thumbprint
        count = int(num)
        broker_thumbprint = cls.get_broker_thumbprint(client_object,
                                                      count)
        pylogger.debug("Found broker_thumbprint %s" % broker_thumbprint)
        result_dict = {'broker_thumbprint': broker_thumbprint}
        return result_dict

    @classmethod
    def remove_broker(cls, client_object, num=None, ip=None):
        '''
        Remove a broker from the mpa config file by entry number or ip address

        @type num: integer
        @param num: Entry of broker to remove
        @type ip: string
        @param ip: IP Address of broker to remove
        @rtype: status code
        @return : Success
        '''
        # TODO: mihaid: Implement file locking
        # TODO: mihaid: More constants for JSON keys?

        if ip is not None and num is not None:
            pylogger.error("Broker removal requires num or ip, not both." +
                           "Found num=%s, ip=%s" % (num, ip))
            return common.status_codes.FAILURE
        elif ip is None and num is None:
            pylogger.error("Num or IP not specified as parameters")
            return common.status_codes.FAILURE
        elif ip is not None:
            key = ip
        elif num is not None:
            key = int(num)

        content = cls._get_mpaconfig(client_object)
        try:
            data = json.loads(content)
            brokerlist = data["RmqBrokerCluster"]
            if ip is not None:
                for item in brokerlist:
                    if ip in item["BrokerIpAddress"]:
                        del item
                        break
            elif num is not None:
                del brokerlist[num]

            pylogger.debug("New JSON config data:\n%s" % pprint.pformat(data))
            Linux.create_file(client_object,
                              path=global_config.DEFAULT_MPA_CONFIG,
                              content=json.dumps(data, indent=3),
                              overwrite=True)
        except KeyError:
            pylogger.error("Failed to find broker %s; bad config file:\n%s" %
                           key, pprint.pformat(data))
            raise
        except Exception as error:
            pylogger.error("Failed to remove broker: %s" %
                           error)
            raise
        return common.status_codes.SUCCESS

    @classmethod
    def add_broker(cls, client_object, num=0, ip=None, port='5671',
                   virtual_host='nsx', thumbprint=None, master=False):
        '''
        Add a broker to the mpa config file

        @type num: integer
        @param num: Entry of broker on mpaconfig list (starts at 0 for master)
        @rtype: status code
        @return : Success
        '''
        # TODO: mihaid: Implement file locking
        # TODO: mihaid: Ensure no broker with same ip already exists (?)
        # TODO: mihaid: Set port as constant

        content = cls._get_mpaconfig(client_object)
        data = json.loads(content)

        entry = {}
        entry["BrokerIpAddress"] = ip
        entry["BrokerPort"] = port
        entry["BrokerVirtualHost"] = virtual_host
        entry["BrokerSslCertThumbprint"] = thumbprint
        entry["BrokerIsMaster"] = master

        try:
            data["RmqBrokerCluster"][num] = entry
        except KeyError:
            pylogger.error("No RmqBrokerCluster in config file:\n%s" %
                           pprint.pformat(data))
            raise

        pylogger.debug("New JSON config data:\n%s" % pprint.pformat(data))
        Linux.create_file(client_object, path=global_config.DEFAULT_MPA_CONFIG,
                          content=json.dumps(data, indent=3), overwrite=True)
        return common.status_codes.SUCCESS