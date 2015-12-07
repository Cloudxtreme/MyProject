package dvs.healthcheck;

import org.testng.annotations.Factory;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.VMwareDVSHealthCheckConfig;

import com.vmware.vcqa.execution.TestExecutionUtils;

public class Pos008 extends HealthCheckTestBase
{

   /**
    * Factory method to create the data driven tests.
    *
    * @return Object[] TestBase objects.
    * @throws Exception
    */
   @Factory
   @Parameters({ "dataFile" })
   public Object[] getTests(@Optional("") String dataFile)
      throws Exception
   {
      return TestExecutionUtils.getTests(this.getClass().getName(), dataFile);
   }

   @BeforeMethod(alwaysRun = true)
   @Override
   public boolean testSetUp()
      throws Exception
   {
      getProperties();
      initialize();
      dvsMor = createDVSWithNics(dvsName);
      setupPortgroups(dvsMor);
      return true;
   }

   @Test(description = "This test case is designed for PR 874054, "
            + "to Configure Health Check for vDS with super class type "
            + "VMwareDVSHealthCheckConfig, it should just be ignored by "
            + "VC server, doesn't cause any exception ")
   public void test()
      throws Exception
   {

      try {
         VMwareDVSHealthCheckConfig[] HealthCheckConfig = new
                  VMwareDVSHealthCheckConfig[1];
         HealthCheckConfig[0] = new VMwareDVSHealthCheckConfig();
         configHealthCheck(HealthCheckConfig);
      } catch (Exception excep) {
         log.error("Error, with the fix of PR 874054, "
                  + "no exception should been caught!");
         throw excep;
      }
   }

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {

      boolean done = false;
      log.info("Destroying the DVS: {} ", dvsName);
      done = destroy(dvsMor);
      return done;

   }
}
