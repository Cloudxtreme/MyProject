package dvs.updateopaquedata;

import static com.vmware.vcqa.util.Assert.*;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.MethodFault;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.testframework.Step;
import com.vmware.vcqa.vim.dvs.testframework.StepReader;

public class UpdateOpaqueDataNegTest extends TestBase implements IDataDrivenTest
{

   private Object opaqueChannelTestFramework = null;
   private Class<?> testFrameworkClass = null;
   private StepReader xmlTester = null;

   /**
    * This method executes the steps specified as part of the test group
    *
    * @throws Exception
    */
   @Test(description="Set of all  negative updateopaquedata api tests")
   public void test()
      throws Exception
   {
      List<Step> stepList = xmlTester.getSteps(DVSTestConstants.TEST);
      MethodFault expectedMethodFault = xmlTester.getExpectedMethodFault();
      assertNotNull(expectedMethodFault,"The expected method fault was not " +
         "provided by the user");
      try{
         Method method = testFrameworkClass.getDeclaredMethod("setStepsList",
            List.class);
         method.invoke(this.opaqueChannelTestFramework, stepList);
         execute(stepList);
         log.error("The api did not throw any exception");
         throw new Exception();
      } catch(InvocationTargetException ex){
         Throwable throwable = ex.getTargetException();
         try {
            if(throwable instanceof Exception){
               Exception e = (Exception)throwable;
               throw e;
            }
         } catch(Exception actualMethodFaultExcep){
            MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
            assertTrue(TestUtil.checkMethodFault(actualMethodFault,
               expectedMethodFault),"The expected and actual method faults " +
                  "match","The expected and actual method faults do not match");
         }
      }
   }

   /**
    * This method invokes the list of cleanup steps as provided by the user
    *
    * @throws Exception
    *
    */
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      List<Step> stepList = xmlTester.getSteps(DVSTestConstants.TEST_CLEANUP);
      Method method = testFrameworkClass.getDeclaredMethod("setStepsList",
         List.class);
      method.invoke(this.opaqueChannelTestFramework, stepList);
      execute(stepList);
      return true;
   }

   /**
    * This method initializes the current test parameters
    *
    * @throws Exception
    */
   public void initializeTest()
      throws Exception
   {
      xmlTester = new StepReader(this.data);
      String testFrameworkClassName = xmlTester.getData(DVSTestConstants.
         TEST_FRAMEWORK);
      String beanPath = xmlTester.getData(DVSTestConstants.BEAN_DATA);
      testFrameworkClass = Class.forName(testFrameworkClassName);
      Constructor<?> constructor = testFrameworkClass.getConstructor(
         ConnectAnchor.class,String.class);
      opaqueChannelTestFramework = constructor.newInstance(this.connectAnchor,
         beanPath);
   }

   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      initializeTest();
      List<Step> stepList = xmlTester.getSteps(DVSTestConstants.TEST_SETUP);
      /*
       * Set the list of steps on the framework
       */
      Method method = testFrameworkClass.getDeclaredMethod("setStepsList",
         List.class);
      method.invoke(this.opaqueChannelTestFramework, stepList);
      execute(stepList);
      return true;
   }

   /**
    * Private method to execute a list of steps provided
    *
    * @param stepList
    *
    * @throws Exception
    */
   private void execute(List<Step> stepList)
      throws Exception
   {
      for(Step step : stepList){
         Method method = testFrameworkClass.getDeclaredMethod(step.getName());
         method.invoke(this.opaqueChannelTestFramework);
      }
   }

   /**
    * This method retrieves either all the data-driven tests or one
    * test based on the presence of test id in the execution properties
    * file.
    */
   @Factory
   @Parameters({"dataFile"})
   public Object[] getTests(@Optional("") String dataFile)
      throws Exception {
      Object[] tests = TestExecutionUtils.getTests(this.getClass().getName(),
         dataFile);
      /*
       * Load the dvs execution properties file
       */
      String testId = TestUtil.getPropertyValue(this.getClass().getName(),
         DVSTestConstants.DVS_EXECUTION_PROP_FILE);
      if(testId == null){
         return tests;
      } else {
         for(Object test : tests){
            if(test instanceof TestBase){
               TestBase testBase = (TestBase)test;
               if(testBase.getTestId().equals(testId)){
                  return new Object[]{testBase};
               }
            } else {
               log.error("The current test is not an instance of TestBase");
            }
         }
         log.error("The test id " + testId + "could not be found");
      }
      /*
       * TODO : Examine the possibility of a custom exception here since
       * the test id provided is wrong and the user needs to be notified of
       * that.
       */
      return null;
   }

   /**
    * (non-Javadoc)
    * @see org.testng.ITest#getTestName()
    */
   public String getTestName()
   {
      return getTestId();
   }
}
