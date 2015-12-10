/*
 * ************************************************************************
 *
 * Copyright 2004-2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package com.vmware.vcqa;

import java.io.File;
import java.lang.reflect.Method;
import java.text.SimpleDateFormat;
import java.util.Collections;
import java.util.Date;
import java.util.List;

import org.apache.commons.collections.MultiMap;
import org.apache.commons.collections.map.MultiValueMap;
import org.apache.commons.configuration.ConfigurationUtils;
import org.apache.commons.configuration.HierarchicalConfiguration;
import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;

import com.vmware.vc.MethodFault;
import com.vmware.vcqa.execution.InventoryManager;
import com.vmware.vcqa.execution.TestDataHandler;
import com.vmware.vcqa.execution.setup.exception.RecoveryTaskException;
import com.vmware.vcqa.execution.setup.task.impl.RecoveryAdapter;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.MessageConstants;
import com.vmware.vcqa.vim.SessionManager;

/**
 * TestBase is the base class for all test cases and it provides public wrapper
 * API for all host agent/VC Web Service operations. <br>
 * Every Test case should extend from this base class and implement abstract
 * methods. They are:<br>
 * <br>
 * 1. setTestDescription() - Set one line precise Test Description.<br>
 * 2. testSetUp() - Logic to set the environment required for test<br>
 * 3. test() - Logic for actual test and verification<br>
 * 4. testCleanUp() - Logic to put environment to original state<br>
 * <p/>
 * TestBase also has methods which perform the default tasks 1. preSetUp() -
 * This method will auto-login to the service unless overridden 2. postCleanUp()
 * - This method will auto-logout from the service unless explicitly overridden
 */

public abstract class TestBase
{
   protected static final Logger log = LoggerFactory.getLogger(TestBase.class);

   /*
    * Instance variables
    */
   private String testId = null;
   private String testDescription = null;

   /**
    * used to state if HTTP Tunneling related system property was
    * set based on XML suite parameters or not.
    */
   private boolean tunnelingSetupViaXmlParameter = false;

   /**
    * the data used by the the test case.
    */
   protected HierarchicalConfiguration data;

   /**
    * the Outcome/Result of the test
    */
   private ResultsEnum testOutcome;

   /**
    * ConnectAnchor/ServiceInfo needed by each test
    */
   private final MultiMap serviceInfoMap = new MultiValueMap();
   protected ConnectAnchor connectAnchor;
   /*
    * Unique identifier for this instance of TestBase
    */
   private final long nInstanceId = (new Date()).getTime();

   /*
    * public TestBase abstract methods should go here These abstract methods
    * should be implemented by every extending test case
    */

   /**
    * Implement this method to provide setup for your test.<br>
    *
    * @return true is setup is successful false otherwise.
    * @throws Exception On problems while setup.
    */
   public abstract boolean testSetUp()
      throws Exception;

   /**
    * A test is considered PASS is it doesn't throws any exception.<br>
    * In case of Negative tests if the MethodFault is same as Expected then it
    * is considered as PASS else FAIL.<br>
    *
    * @throws Exception On problems while testing.
    */
   public abstract void test()
      throws Exception;

   /**
    * Implement this method to provide cleanup for you test.<br>
    *
    * @return true if cleanup is successful false otherwise.
    * @throws Exception On problems while cleanup.
    */
   public abstract boolean testCleanUp()
      throws Exception;

   /**
    * Sets the test description. It should be implemented by the test case
    * FIXME: Converting abstract method into dummy implementation to support legacy framework
    * TODO: Should be removed once CAT moves to TestNG
    */
   public void setTestDescription() {}

   /*
    * TestBase utility methods getters and setters should go here
    */
   /**
    * Gets the testOutcome <br>
    *
    * @return testOutCome - outcome of the test
    */
   public ResultsEnum getOutcome()
   {
      return testOutcome;
   }

   /**
    * Sets the testOutcome <br>
    *
    * @param outcome ResultsEnum
    */
   public void setOutcome(ResultsEnum outcome)
   {
      if (testOutcome == null ||testOutcome == ResultsEnum.NONE || testOutcome == ResultsEnum.PASS ) {
                               // 	  outcome == ResultsEnum.PASSED_WITH_SYSALERT
          testOutcome = outcome;
          log.info("Set outcome to " + outcome);
      }else {
         log.warn("Trying to set outcome to: " + outcome.toString());
         log.warn("Cannot set testoutcome as outcome already set to: "
                  + getOutcome().toString());
      }
   }

   /**
    * Resets the testOutcome <br>
    */

   public void resetOutcome()
   {
      testOutcome = ResultsEnum.NONE;
   }

   /**
    * This will be used by Negative and some Security tests to set the expected
    * exception.<br>
    * One needs to override this method to return the expected MethodFault.
    *
    * @return the expected MethodFault.
    */
   public MethodFault getExpectedMethodFault()
   {
      return null;
   }

   /**
    * Sets USE_HTTP_TUNNELING, tunnelingSetupViaXmlParameter <br>
    */
   public void setHTTPTunnelingProp(boolean val)
   {
      if(val){
         System.setProperty(TestConstants.USE_HTTP_TUNNELING, "true");
      }else{
        System.clearProperty(TestConstants.USE_HTTP_TUNNELING);
      }
      tunnelingSetupViaXmlParameter = val;
      log.info("tunnelingSetupViaXmlParameter was set to " + tunnelingSetupViaXmlParameter);
   }

   /**
    * Loads basic necessary information like hostname, port, userName, password.<br>
    * This method should be called before calling the life cycle methods like
    * testSetUp(), test(), testCleanUp()<br>
    *
    * @param testData the test data.
    * @throws Exception if any problem occurs while initializing the test.
    */
   public final void init(final HierarchicalConfiguration testData)
      throws Exception
   {
      if (TestConstants.BOOL_TRUE.equalsIgnoreCase(System.getProperty(TestConstants.TRACESOAP))) {
         System.setProperty(TestConstants.TESTID, this.getClass().getName());
      }
      /*
       * ensures that each test instance has its own copy of configuration data
       * so that any further modifications to this doesn't affect other tests.
       */
      this.data = new HierarchicalConfiguration(testData);
      TestInputHandler.initialize(this, data);
   }

   /**
    * Initializes the test when executed using TestNG
    *
    * @param testArgs -
    * @throws Exception -
    */
   //@BeforeClass(alwaysRun = true) is required to include this method by TestNG when
   //test cases are run with TestNG groups.
   @BeforeClass(alwaysRun = true)
   @Parameters("testArgs")
   public void initTest(@Optional("") String testArgs)
      throws Exception
   {
      String testId = getTestId();
     //start logging to test specific log file
      TestLogHelper.startTestLogging(testId);
      HierarchicalConfiguration testData = null;

      /*
       * Create and copy the test data only if it has not been initialized
       * already, such as the testng test factory.
       */
      if(this.data == null) {
         HierarchicalConfiguration commonData =
            (HierarchicalConfiguration)TestDataHandler.getSingleton().getData();
         /**
          * Clone the configuration only if the suites are being run in parallel.
          */
         if (commonData.getBoolean(TestConstants.TESTINPUT_RUN_SUITES_IN_PARALLEL,
                                   false)) {
            testData = (HierarchicalConfiguration)
                  ConfigurationUtils.cloneConfiguration(commonData);
         } else {
            testData = commonData;
         }
      } else {
         //Copy the data already populated.
         testData = this.data;
      }

      if (!"".equals(testArgs)) {
         /*
          * FIXME: Hack: Here to keep current code working with both legacy framework and
          * TestNG. Used to solve the issue of testArgs. Should be removed and replaced
          * with a better solution in future
          */
         String[] args = testArgs.split("\\s+");

         if (args.length % 2 != 0) {
            log.error("Odd number of values on arg line. Not adding specific parameters : "
                     + testArgs);
         } else {
            for (int i = 0; i < args.length; i += 2) {
               String name = args[i].substring(1);
               String value = args[i + 1];
               /*
                * Replace the properties set from the config.properties with the
                * ones set in the testng xml file.
                */
               testData.setProperty(name, value);
            }
            log.info("data containing testArgs=" +
                     ConfigurationUtils.toString(testData).replace("\r\n", " | ").replace("\n", "|"));
         }
      }
      //start logging to test specific log file
      TestLogHelper.startTestLogging(testId);

      // Handle HTTP tunneling request
      // moved to TestInputHandler.initialize() to accommodate the old testing framework
      //
      //if (Boolean.valueOf(data.getString(TestConstants.USE_HTTP_TUNNELING_PARAM, Boolean.FALSE.toString()))) {
      //   System.setProperty(TestConstants.USE_HTTP_TUNNELING, "true");
      //   tunnelingSetupViaXmlParameter = true;
      //}
      try {
         log.info("Recovery Adaptor Enabled : " +
                  testData.getString(TestDataHandler.TESTINPUT_RECOVERY_ADAPTOR));
         if (testData.getString(TestDataHandler.TESTINPUT_RECOVERY_ADAPTOR) != null &&
             testData.getString(TestDataHandler.TESTINPUT_RECOVERY_ADAPTOR).equals("true")) {
            TestLogHelper.startTestLogging(getTestId() + "-recovery-adapter");
            RecoveryAdapter.run();
         }
      } catch (Exception e) {
         log.error("Generic Exception thrown by RecoveryAdapter ", e);
      } catch (RecoveryTaskException e) {
         // todo : if the exception is fatal exception then stop execution
         log.error("RecoveryTask Exception ", e);
      }

      //start logging to test file again
      TestLogHelper.startTestLogging(testId);

      //initialize the test configuration data
      init(testData);

      try {
         InventoryManager inventoryMgr = new InventoryManager();
         if (!TestConstants.PARALLEL_ENABLED_FIELD.equals(System.getProperty("ParallelExecution"))
                  && inventoryMgr.isEnabled()) {
            //start logging to inventory log file
            TestLogHelper.startTestLogging("inventoryMgr");
            inventoryMgr.verifyAndResetInventory(this.getClass().getName(), testData);
         }
      } catch (Exception e) {
         log.error("**** caught exception in InventoryManager ***");
         TestUtil.handleException(e);
      }

      //start logging to test file again
      TestLogHelper.startTestLogging(testId);
      //Log the test information.
      printTestInfo();
   }

   /**
    * Sets the test ID, if one requires to set it explicitly
    *
    * @param id test ID.
    */
   public void setTestId(String id)
   {
      this.testId = id;
   }

   /**
    * Sets the data for this test instance.
    *
    * @param data HierarchicalConfiguration object.
    */
   public void setData(HierarchicalConfiguration data)
   {
      this.data = data;
   }

   /**
    * Gets the test ID.
    *
    * @return the test ID of the test.
    */
   public String getTestId()
   {
      return ((testId == null) ? (this.getClass().getName()) : testId);
   }

   /**
    * Sets the description of the test in {@link #setTestDescription()}
    * implementation.
    *
    * @param description Test description.
    */
   public void setTestDescription(String description)
   {
      this.testDescription = description;
   }

   /**
    * Method to get the test description.
    *
    * @return the test description.
    */
   public String getTestDescription()
   {
      if (StringUtils.isBlank(testDescription)) {
         setTestDescription();
         if(StringUtils.isBlank(testDescription)) {
            log.warn("Test description is not set.");
         }
      }
      return this.testDescription;
   }

   /**
    * Gets List of ServiceInfo items by extension key
    * @param extensionKey -
    *
    * @return List of ServiceInfo
    */
   public List<ServiceInfo> getServiceInfoList(String extensionKey)
   {
      List<ServiceInfo> serviceInfoList = (List<ServiceInfo>) serviceInfoMap.get(extensionKey);
      return serviceInfoList == null ? Collections.EMPTY_LIST
               : Collections.unmodifiableList(serviceInfoList);
   }

   /**
    * Add ServiceInfos to the MultiMap
    * @param serviceInfoList -
    * @return void
    */
   public void addServiceInfoList(List<ServiceInfo> serviceInfoList)
   {
      for (ServiceInfo serviceInfo : serviceInfoList) {
         this.serviceInfoMap.put(serviceInfo.getExtensionKey(), serviceInfo);
      }
   }

   /**
    * Get serviceInfoMap
    *
    * @return serviceInfoMap
    */
   public MultiMap getServiceInfoMap() {
      return serviceInfoMap;
   }

   /**
    * Get ConnectAnchor
    *
    * @return connectAnchor ConnectAnchor
    */
   public ConnectAnchor getConnectAnchor()
   {
      return this.connectAnchor;
   }

   /**
    * Set ConnectAnchor
    *
    * @return connectAnchor ConnectAnchor
    */
   public void setConnectAnchor(ConnectAnchor connectAnchor) {
      this.connectAnchor = connectAnchor;
   }

   /**
    * Re-login Session
    */
   public void reloginSession() {
      try {
         log.info("Re-login to the connect anchor");
         String username = getServiceInfoList(TestConstants.VC_EXTENSION_KEY).get(0).getUserName();
         String password = getServiceInfoList(TestConstants.VC_EXTENSION_KEY).get(0).getPassword();
         log.info("Username: " + username + " Password: " + password);
         SessionManager.login(this.connectAnchor, username, password);
         log.info("Sleeping for 30 seconds for session getting established");
         Thread.sleep(30 * 1000);
      } catch (Exception e) {
         log.info("Got the exception during reset connect anchor", e);
      }
   }

   /**
    * Method to print the string representation of the test.
    */
   public void printTestInfo()
   {
      StringBuffer desc = new StringBuffer();
      desc.append("<TESTID>").append(getTestId()).append("</TESTID>\n");
      desc.append("<TESTDESCRIPTION>").append(getTestDescription()).append(
         "</TESTDESCRIPTION>");
      //TODO: print hierarchical configuration data here

      // FIXME If this is needed only in stress tests then we should
      // override this in StressBase and add it.
      desc.append("<opTestId>").append(this.getClass().getCanonicalName())
         .append("</opTestId>");
      log.info(desc.toString());
   }

   /**
    * This method will be called before testSetUp by testExecutor Presetup
    * method will auto-login unless it is overridden
    *
    * @return true if preSetUp passes false if it fails
    */
   //@BeforeClass(alwaysRun = true) is required to include this method by TestNG when
   //test cases are run with TestNG groups.
   @BeforeClass(dependsOnMethods = {"initTest"}, alwaysRun = true)
   public boolean preSetUp()
      throws Exception
   {
      log.info("*** Entering PreSetUp ***");
       
      Assert.assertNotNull(SessionManager.login(connectAnchor,
    		  getServiceInfoList(TestConstants.VC_EXTENSION_KEY).get(0).getUserName(),
    		  getServiceInfoList(TestConstants.VC_EXTENSION_KEY).get(0).getPassword()),
               MessageConstants.LOGIN_PASS, MessageConstants.LOGIN_FAIL);
      return true;
   }


   /**
    * This method will be called before postCleanUp for SysAlert verification
    */
   @AfterClass(alwaysRun = true)
   public boolean verifySysAlert()
   {
      boolean sysAlertEnabled = TestConstants.SYS_ALERT_ENABLED;
      log.debug("SYS_ALERT_ENABLED : " + sysAlertEnabled);

      if (!sysAlertEnabled) {
         //no need to proceed
         return true;
      }
      boolean sysAlert = true;
      List<ServiceInfo> serviceInfoList =
                     getServiceInfoList(TestConstants.VC_EXTENSION_KEY);

      try {
         if (serviceInfoList.size() > 0
                  && serviceInfoList.get(0).getConnectAnchor().getAPIType()
                        .equalsIgnoreCase(TestConstants.SIC_SERVER_TYPE_VC)) {
            final String className = "com.vmware.vcqa.vpxd.SysAlertHelper";
            Class<?> cl = Class.forName(className);
            Object obj = cl.newInstance();
            Class<?>[] param = new Class<?>[5];
            param[0] = Class.forName("java.lang.String");
            param[1] = Integer.TYPE;
            param[2] = Class.forName("java.lang.String");
            param[3] = Class.forName("java.lang.String");
            param[4] = Class.forName("java.lang.String");
            Method mthd = cl.getMethod("verifySysAlert", param);

            for (ServiceInfo serviceInfo :
                     getServiceInfoList(TestConstants.VC_EXTENSION_KEY)) {

               sysAlert &= (Boolean) mthd.invoke(obj,
                                        serviceInfo.getHostName(),
                                        serviceInfo.getPort(),
                                        serviceInfo.getUserName(),
                                        serviceInfo.getPassword(),
                                        this.getClass().getName());
            }
         }
      } catch (Exception exception) {
         // Need to print the stack trace before log.error because log.error is
         // throwing an Error
         exception.printStackTrace(System.out);
         log.error("SYSALERT_EXCEPTION:", exception);
         setOutcome(ResultsEnum.EXCEPTION);
         //TestUtil.handleException(exception);
      }
      return sysAlert;
   }

   /**
    * This method will be called after testCleanUp it will auto-logout unless
    * overridden
    *
    * @return boolean
    */
   @AfterClass(dependsOnMethods = {"verifySysAlert"}, alwaysRun = true)
   public boolean postCleanUp()
      throws Exception
   {
      /*
       * HTTP Tunneling cleanup.
       * In case http tunneling system property was set, remove it
       */
      if (tunnelingSetupViaXmlParameter) {
         /*
          * Only unset the system property if we set it in first place. User could set it via
          * JVM args as well
          */
        setHTTPTunnelingProp(false);
      }

      //TODO: needs to be fixed for solution tests where
      // serviceInfoList is used instead of connect anchor
      try {
         if (null != connectAnchor) {
            Assert.assertTrue(SessionManager.logout(connectAnchor), "Post-Cleanup failed");
            // kiri fix this.
//            ServiceClient serviceClient = connectAnchor.getService()._getServiceClient();
//            ConfigurationContext context = serviceClient.getServiceContext().getConfigurationContext();
//            if (context.getProperty(HTTPConstants.CACHED_HTTP_CLIENT) != null) {
//                  HttpClient client = (HttpClient)context.getProperty(HTTPConstants.CACHED_HTTP_CLIENT);
//                  ((MultiThreadedHttpConnectionManager)client.getHttpConnectionManager()).shutdown();
//            }

         }
      } finally {
         if( null != connectAnchor ){
            connectAnchor.clean();
         }
         TestLogHelper.stopTestLogging();
      }
      return true;
   }

   /**
    * Attempts to collect logs for as many hosts in the inventory as possible.
    * The configuration file must have {@link TestConstants#TESTINPUT_COLLECTLOGS}
    * set to true for logs to be collected.  The configuration file may specify
    * the root logging directory by setting {@link
    * TestConstants#TESTINPUT_SYSTEMLOGSPATH}.  '/var/log' is the default.
    *
    * @param nDateTime  This should be the start time for the set of tests that
    *                   are being run and provides a unique label under which
    *                   Log Bundles are stored.  If 0 is passed in, the time at
    *                   which this TestBase was instantiated is used as the
    *                   unique identifier.
    * @param strStepId  Label to indicate where in the test the logs were gathered.
    *                   If not specified, this label will become "unspecified".
    */
   public void preserveLogs(long nDateTime, String strStepId)
   {
      /*
       * Are we configured to generate the logs?
       */
      boolean bCollectLogs = this.data.getBoolean(
         TestConstants.TESTINPUT_COLLECTLOGS, false);
      if (!bCollectLogs){
         log.debug("Test configuration value, " +
            TestConstants.TESTINPUT_COLLECTLOGS + " is not set to true;");
         return;
      }

      /*
       * Set the unique logging directory based on date/time.
       */
      if (nDateTime == 0){
         nDateTime = this.nInstanceId;
      }
      if (strStepId == null || strStepId.isEmpty()){
         strStepId = "unspecified";
      }
      SimpleDateFormat objDateFormat = new SimpleDateFormat("yyyyMMdd'-'HHmmss");
      String strDateTime = objDateFormat.format(nDateTime);

      try{
         /*
          * Build and create a unigue log path.
          */
         String strLogsPath = this.data.getString(
            TestConstants.TESTINPUT_SYSTEMLOGSPATH, "/var/log/");
         String strSep = System.getProperty("file.separator");
         if (!strLogsPath.endsWith(strSep)) {
            strLogsPath += strSep;
         }
         strLogsPath += strDateTime + strSep + strStepId;
         File objLogsPath = new File(strLogsPath);
         Assert.assertTrue(objLogsPath.mkdirs(), "Could not create directory, " +
            strLogsPath);
         log.info("Posting log bundle to " + strLogsPath);

         /*
          * Generate and post the log bundles.
          */
         String strAdminPassword =
            this.data.getString(TestDataHandler.TESTINPUT_PASSWORD);
         Assert.assertTrue(strAdminPassword != null && !strAdminPassword.equals(""),
            "Failed to retrieve Admin password.");
         String strResult = TestUtil.postLogBundles(this.connectAnchor,
            strAdminPassword, TestConstants.ESX_USERNAME,
            TestConstants.ESX_PASSWORD, strLogsPath);
         log.info("Post Log Bundles result: " + strResult);
      } catch (Exception e){
         log.warn("preserveLogs encountered errors: " + e.getClass().getName() +
            ": " + e.getMessage());
      }
   }

}
