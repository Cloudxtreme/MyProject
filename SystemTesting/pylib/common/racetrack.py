#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
## Racetrack reporting module

__author__ = 'fusion-automation@vmware.com'

# urllib2_file replaces functions in urllib2 to enable file uploads. It is not
# called directly.

import urllib2_file
import logging
import urllib2
import os

''' racetrack.py - Racetrack reporting module
    General usage:

    The module uses module scoped global variables to track server, test case,
    and test set IDs. This means that in the simple case, your harness and
    test cases can import racetrack, start and stop test cases and test sets
    without having to pass the IDs around. Starting multiple test cases or
    test sets simultaneously breaks this model. You will have to pass test
    case and test set IDs around if multiple tests are desired. See also
    the 'advanced' global variable.

    NOTE: Functions that accept an ID parameter will not honor it unless the
    advanced variable is set. Setting this variable implies that the caller
    will take responsibility for tracking all test set and test case IDs.

    There is also a global variable for disabling reporting altogether, useful
    for debugging.

    Another global variable, testCaseResult, stores the result
    of the test case. If verifications fail, the result is updated
    automatically. More sophisticated test strategies may opt to set the result
    manually rather than relying on the racetrack module to determine test
    results.

    Example usage:

    import racetrack

    # Override the default server
    racetrack.server = 'racetrack-dev.eng.vmware.com'

    racetrack.testSetBegin(BuildID, User, Product, Description, HostOS)
    racetrack.testCaseBegin(Name, Feature)

    ... test ...

    if !racetrack.verify(actual, expected, 'Checking result of x'):
        racetrack.comment("I knew that wouldn't work")
    racetrack.testCaseEnd()
    racetrack.testSetEnd()

    More information on the web services API is at:
    https://wiki.eng.vmware.com/RacetrackWebServices
'''
LOG_FORMAT = '%(asctime)s %(levelname)-8s %(message)s'

logging.basicConfig(level=logging.DEBUG,
                    format=LOG_FORMAT,
                    datefmt='%a, %d %b %Y %H:%M:%S')

### Module scoped global variables ###
### These variables can be updated by callers to change module behavior ###

enabled = True
'''enabled - Flag to specify whether writing results to Racetrack is
   enabled or not.
'''
advanced = False
'''advanced - allows a new test case and test set to be started even when
   prior cases have not finished. If advanced is set to True, the caller must
   specify the test case or test set ID to any function that accepts it.
'''
server = 'racetrack.eng.vmware.com'
'''server - specify the Racetrack server to post to.

   Valid values:
        racetrack.eng.vmware.com
        racetrack-dev.eng.vmware.com
'''

### Module scoped data variables ###
### Callers should not directly change the contents of these variables ###

testSetID = None
'''testSetID - store the current test set ID.'''
testCaseID = None
'''testCaseID - store the ID of the current test case.'''
testCaseResult = None
'''testCaseResult - stores the result of the current test case.'''

### Module scoped constants ###

'''These constants specify valid choices for the various enums in the web
   services API.
'''
TESTTYPES = ['BATS', 'Smoke', 'Regression', 'DBT', 'Unit', 'Performance']
LANGUAGES = ['English', 'Japanese', 'French', 'Italian', 'German', 'Spanish',
                'Portuguese', 'Chinese', 'Korean']
RESULTTYPES = ['PASS', 'FAIL', 'RUNNING', 'CONFIG','SCRIPT', 'PRODUCT',
                  'RERUNPASS', 'UNSUPPORTED']
VERIFYRESULTS = ['TRUE', 'FALSE']

### Public module functions ###

def testSetBegin(BuildID, User, Product, Description, HostOS,
                      ServerBuildID=None, Branch=None, BuildType=None,
                      TestType=None, Language=None):
    '''testSetBegin - begin a new test set in Racetrack.

        Returns a new test set ID on success or False on failure.
        Param             Required?    Description
        BuildID           Yes          The build number that is being tested
        User              Yes          The user running the test
        Product           Yes          The name of the product under test
        Description       Yes          A description of this test run
        HostOS            Yes          The Host OS
        ServerBuildID     No           The build number of the "server" product
        Branch            No           The branch which generated the build
        BuildType         No           The type of build under test
        TestType          No           default Regression
        Language          No           default English
    '''
    global testSetID
    global advanced
    if testSetID is not None and not advanced:
        logging.error('A test set (ID %s) has already begun in Racetrack!' %
            testSetID)
        return False
    if Language is not None and Language not in LANGUAGES:
        logging.error('Specified language is invalid.')
        return False
    if TestType is not None and TestType not in TESTTYPES:
        logging.error('Specified test type is invalid.')
        return False
    data = {
              'BuildID' : BuildID,
              'User' : User,
              'Product' : Product,
              'Description' : Description,
              'HostOS' : HostOS,
              'ServerBuildID' : ServerBuildID,
              'Branch' : Branch,
              'BuildType' : BuildType,
              'TestType' : TestType,
              'Language' : Language
             }
    result = _postHTTP('TestSetBegin.php', data)
    if result:
        testSetID = result
        logging.info('New test set started at %s' % getURL())
    return result

def testCaseTriage(ID=None, Result='Product', BugNumber=None):
     if ID is not None and advanced:
          testSetID = ID
     if testSetID is None:
          logging.error('testSetUpdate called but there is no active test set!')
          return False
     if BugNumber is None:
          logging.error('Bug number must be specified!')
          return False

     data = {'ID' : testSetID,
             'Result' : Result,
             'bugnumber' : BugNumber
            }

     result = _postHTTP('TestCaseTriage.php', data)
     return result

def testSetUpdate(ID=None, BuildID=None, User=None, Product=None,
                        Description=None, HostOS=None, ServerBuildID=None,
                        Branch=None, BuildType=None, TestType=None, Language=None):
    '''testSetUpdate - Update test set data after creation.

        Param             Required?    Description
        ID                No           The test set/run that is being completed.
        BuildID           No           The build number that is being tested
        User              No           The user running the test
        Product           No           The name of the product under test
        Description       No           A description of this test run
        HostOS            No           The Host OS
        ServerBuildID     No           The build number of the "server" product
        Branch            No           The branch which generated the build
        BuildType         No           The type of build under test
        TestType          No           default Regression
        Language          No           default English
    '''
    global testSetID
    global advanced
    if ID is not None and advanced:
        testSetID = ID
    if testSetID is None:
        logging.error('testSetUpdate called but there is no active test set!')
        return False
    if Language is not None and Language not in LANGUAGES:
        logging.error('Specified language is invalid.')
        return False
    if TestType is not None and TestType not in TESTTYPES:
        logging.error('Specified test type is invalid.')
        return False
    data = {
              'ID' : testSetID,
              'BuildID' : BuildID,
              'User' : User,
              'Product' : Product,
              'Description' : Description,
              'HostOS' : HostOS,
              'ServerBuildID' : ServerBuildID,
              'Branch' : Branch,
              'BuildType' : BuildType,
              'TestType' : TestType,
              'Language' : Language
             }
    result = _postHTTP('TestSetUpdate.php', data)
    return result

def testSetData(Name, Value, ResultSetID=None):
    '''Update result set with additional data. Called by framework anytime.

        Param             Required?    Description
        Name              Yes            The key in the key/value pair of data
        Value             Yes            The value in the key/value pair of data.
        ResultSetID     No             The test set/run that is being completed.
    '''
    global testSetID
    global advanced
    if ResultSetID is not None and advanced:
        testSetID = ResultSetID
    if testSetID is None:
        logging.error('testSetData called but there is no active test set.')
        return False
    data = {
              'ID' : testSetID,
              'Name' : Name,
              'Value' : Value
             }
    result = _postHTTP('TestSetData.php', data)
    return result

def testSetEnd(ID=None):
    '''testSetEnd - End the test set

        Param             Required?    Description
        ID                No           The test set/run that is being completed.
    '''
    global testSetID
    global advanced
    if ID is not None and advanced:
        testSetID = ID
    if testSetID is None:
        logging.error('testSetEnd called but there is no active test set.')
        return False
    data = {
              'ID' : testSetID
             }
    result = _postHTTP('TestSetEnd.php', data)
    testSetID = None
    return result

def testCaseBegin(Name, Feature, Description=None, MachineName=None,
                        TCMSID=None, InputLanguage=None, ResultSetID=None):
    '''testCaseBegin - Start a new test case

        Param             Required?    Description
        Name              Yes            The name of the test case
        Feature          Yes            The feature that is being tested
        Description     No             A description of this test case
        MachineName     No             The host that the test is running against
        TCMSID            No             A comma-separated Testlink (TCMSID) ID's.
        InputLanguage  No             abbreviation for the language used eg 'EN'
        ResultSetID     No             The test set/run that is being completed.
    '''
    global testSetID
    global advanced
    global testCaseID
    global testCaseResult
    if ResultSetID is not None and advanced:
        testSetID = ResultSetID
    if testSetID is None:
        logging.error('testCaseBegin called but there is no active test set.')
        return False
    if testCaseID is not None and not advanced:
        logging.error('A test case (ID %s) has already begun in Racetrack!' %
            testCaseID)
        return False
    data = {
              'Name' : Name,
              'Feature' : Feature,
              'Description' : Description,
              'MachineName' : MachineName,
              'TCMSID' : TCMSID,
              'InputLanguage' : InputLanguage,
              'ResultSetID' : testSetID
             }
    result = _postHTTP('TestCaseBegin.php', data)
    if result is not False:
        testCaseID = result
        testCaseResult = 'PASS'
    return result

def screenshot(Description, Screenshot, ResultID=None):
    '''screenshot - upload a screenshot

        Param             Required?    Description
        Description       Yes          The comment
        Screenshot        Yes          The screenshot location
        ResultID          No           The test case# that is being completed.
    '''
    global advanced
    global testCaseID
    if ResultID is not None and advanced:
        testCaseID = ResultID
    if testCaseID is None:
        logging.error('screenshot called but there is no active test case.')
        return False
    if not os.path.exists(Screenshot):
        logging.error('Screenshot to upload not found: %s' % Screenshot)
        return False
    data = {
              'Description' : Description,
              'ResultID' : testCaseID,
              'Screenshot' : { 'fd' : open(Screenshot),
                                     'filename' : os.path.basename(Screenshot) }
             }
    result = _postHTTP('TestCaseScreenshot.php', data)
    return result

def log(Description, Log, ResultID=None):
    '''log - upload a log

        Param             Required?    Description
        Description       Yes          The comment
        Log               Yes          The log location
        ResultID          No           The test case# that is being completed.
    '''
    global advanced
    global testCaseID
    if ResultID is not None and advanced:
        testCaseID = ResultID
    if testCaseID is None:
        logging.error('log called but there is no active test case.')
        return False
    if not os.path.exists(os.path.expanduser(Log)):
        logging.error('Log to upload not found: %s' % Log)
        return False
    data = {
              'Description' : Description,
              'ResultID' : testCaseID,
              'Log' : { 'fd' : open(os.path.expanduser(Log)),
                            'filename' : os.path.basename(Log) }
             }
    result = _postHTTP('TestCaseLog.php', data)
    return result

def performanceCsvLog(csvLog, ResultSetID=None):
    '''log - upload a log

        Param             Required?    Description
        csvLog            Yes            The CSV log location
        ResultSetID     No             The test set/run that is being completed.
    '''
    global testSetID
    global advanced
    if ResultSetID is not None and advanced:
        testSetID = ResultSetID
    if testSetID is None:
        logging.error('performanceCsvLog called but there is no active test set.')
        return False
    if not os.path.exists(os.path.expanduser(csvLog)):
        logging.error('CSV log to upload not found: %s' % csvLog)
        return False
    data = {
              'ResultSetID' : testSetID,
              'CsvLog' : { 'fd' : open(os.path.expanduser(csvLog)),
                                'filename' : os.path.basename(csvLog) }
             }
    result = _postHTTP('TestCaseCsvLog.php', data)
    return result

def performanceLog(Feature, Measure, Type, Value, ResultSetID = None):
    '''performanceLog - Performance logging

        Param             Required?    Description
        Feature           Yes          Test feature
        Measure           Yes          Test name (ex: OpenVM, PowerOnVM)
        Type              Yes          Seconds, Memory, CPU, NetworkIO, DiskIO
        Value             Yes          Respective measured type value (ex: 6(seconds), 90(CPU %), 250(MB))
        ResultSetID       No           The test set/run that is being completed.
    '''
    global testSetID
    global advanced
    if ResultSetID is not None and advanced:
        testSetID = ResultSetID
    if testSetID is None:
        logging.error('performanceLog called but there is no active test set.')
        return False
    data = {
              'Feature' : Feature,
              'Measure' : Measure,
              'Type' : Type,
              'Value' : Value,
              'ResultSetID' : testSetID
             }
    result = _postHTTP('PerfData.php', data)
    return result

def comment(Description, ResultID=None):
    '''comment - submit a comment for a test case.

        Param             Required?    Description
        Description       Yes          The comment
        ResultID          No           The test case# that is being completed.
    '''
    global advanced
    global testCaseID
    if ResultID is not None and advanced:
        testCaseID = ResultID
    if testCaseID is None:
        logging.error('comment called but there is no active test case.')
        return False
    data = {
              'Description' : Description,
              'ResultID' : testCaseID
             }
    result = _postHTTP('TestCaseComment.php', data)
    return result

def verify(Description, Actual, Expected, Result=None, Screenshot=None,
              ResultID=None):
    '''verify - Validate the actual matches the expected.

        This function returns Expected==Actual, allowing shorthand like:

        if racetrack.verify('Test', expected, actual):
            # Do something if verify passes

        See testCaseVerification() for additional parameters definition.
    '''
    result = testCaseVerification(Description, Actual, Expected, Result=Result,
                                  Screenshot=Screenshot, ResultID=ResultID)
    logging.debug('test case verification POST result: %r' % result)
    return Expected == Actual

def testCaseVerification(Description, Actual, Expected, Result=None, Screenshot=None,
              ResultID=None):
    '''
    Report a test case verification status to Racetrack.

        Param             Required?    Description
        Description     Yes            The comment
        Actual            Yes            The actual value. (any string)
        Expected         Yes            The expected value. (any string)
        Result            No             The outcome of the verification.
                                            (TRUE or FALSE representing PASS or FAIL)
        Screenshot      No             A screenshot associated with the (failed)
                                            verification
        ResultID         No             The test case that is being completed.
    '''
    global advanced
    global testCaseID
    global testCaseResult
    if ResultID is not None and advanced:
        testCaseID = ResultID
    if testCaseID is None:
        logging.error('verify called but there is no active test case.')
        return False
    if Result is None:
        if Expected == Actual:
            Result = 'TRUE'
        else:
            Result = 'FALSE'
            testCaseResult = 'FAIL'
    else:
         if Result not in VERIFYRESULTS:
              logging.error('Specified result is not valid.')
              return False
         if Result == 'FAIL':
              testCaseResult = 'FAIL'
    data = {
              'Description' : Description,
              'Actual' : Actual,
              'Expected' : Expected,
              'Result' : Result,
              'ResultID' : testCaseID
             }
    if Screenshot is not None:
        if not os.path.exists(Screenshot):
            logging.error('Screenshot to upload not found: %s' % Screenshot)
            return False
        data['Screenshot'] = {
                              'fd' : open(Screenshot, 'rb'),
                              'filename' : os.path.basename(Screenshot)
                             }
    result = _postHTTP('TestCaseVerification.php', data)
    return result

def testCaseEnd(Result=None, ID=None):
    '''testCaseEnd - End a test case

        Param             Required?    Description
        Result            No           The result of the test. Enum of 'PASS',
                                          'FAIL', 'RUNNING','CONFIG','SCRIPT',
                                         'PRODUCT','RERUNPASS', or 'UNSUPPORTED'
        ID                 No          The test case that is being completed.
    '''
    global advanced
    global testCaseID
    global testCaseResult
    if ID is not None and advanced:
        testCaseID = ID
    if testCaseID is None:
        logging.error('testCaseEnd called but there is no active test case.')
        return False
    if Result is not None:
        if Result not in RESULTTYPES:
            logging.error('Specified test result is invalid.')
            return False
        else:
            testCaseResult = Result
    data = {
              'Result' : testCaseResult,
              'ID' : testCaseID
             }
    result = _postHTTP('TestCaseEnd.php', data)
    testCaseID = None
    return result

def getTokenValue(product, token, language):
    '''getTokenValue - Retrieve a token from the Racetrack g11n database

        Returns False if the API fails, blank if the token was not found, or
        the contents of the token.

        Param             Required?    Description
        product           Yes          Name of the product to retrieve
        token             Yes          Token to retrieve from the database
        language          Yes          Desired token language
    '''
    data = {
              'product' : product,
              'token' : token,
              'language' : language
           }
    result = _postHTTP('gettestdatavalue.php', data)
    return result

def getURL(ID=None):
    '''getURL - return the URL of the current test set or False if error'''
    global advanced
    global testSetID
    global server
    if ID is not None and advanced:
        testSetID = ID
    if testSetID is None:
        logging.error('getURL called with no active test set')
        return False
    if testSetID == True:
        return 'No URL available. Test set created with racetrack.enable = False'
    return 'http://%s/result.php?id=%s' % (server, testSetID)

def postBatsEng(ResultSetID, Group, Recommendation):
    '''log - upload a log

        Param             Required?    Description
        ResultSetID       Yes          Result set id (one or more comma separated)
        Group             Yes          Test product group (ex: Workstation)
        Recommendation    Yes          Recommend the product or not ?
    '''
    data = {
              'ResultSetID' : ResultSetID,
              'Group' : Group,
              'Recommendation' : Recommendation
             }
    result = _postHTTP('PostBatsEngResult.php', data)
    return result

def uploadLogs2Bugzilla(logFilePath, bugId):
    '''log - upload log file to VMware bugzilla

        Param             Required?    Description
        logFilePath       Yes          Log file path in racetrack server
        bugId             Yes          Bug number
    '''
    data = {
              'LogFilePath' : logFilePath,
              'BugId' : bugId
           }
    result = _postHTTP('UploadLog2Bugzilla.php', data)
    return result

### Private module functions ###

def _postHTTP(method, data):
    '''_postHTTP - post the supplied data to the specified method'''
    global server
    global enabled

    url = 'http://%s/%s' % (server, method)
    for key in data.keys():
        if data[key] is None:
            del data[key]
        else:
            if isinstance(data[key], unicode):
                data[key] = data[key].encode('utf-8')
            if not isinstance(data[key], basestring) and \
                not isinstance(data[key], dict):
                data[key] = str(data[key])
    if enabled:
        #logging.debug('Racetrack post to %s: %s' % (url, data))
        try:
            result = urllib2.urlopen(url, data)
            result = result.read().decode('utf-8')
            #logging.debug('Racetrack server returned: %s' % result)
        except Exception, e:
            logging.error('Error connecting to web service: %s', e)
            logging.error('URL: %s\nData: %s' % (url, data))
            return False
        return result
    else:
        logging.debug('Racetrack disabled - skipped post to %s: %s' %
            (url, data))
        return True

