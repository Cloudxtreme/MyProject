package dvs.healthcheck;

import org.testng.annotations.Factory;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.InvalidRequest;

import com.vmware.vcqa.execution.TestExecutionUtils;

public class Neg001 extends HealthCheckTestBase {

   /**
    * Factory method to create the data driven tests.
    *
    * @return Object[] TestBase objects.
    *
    * @throws Exception
    */
   @Factory
   @Parameters({ "dataFile" })
   public Object[] getTests(@Optional("") String dataFile) throws Exception {
      return TestExecutionUtils.getTests(this.getClass().getName(), dataFile);
   }

   @BeforeMethod(alwaysRun = true)
   @Override
   public boolean testSetUp() throws Exception {
      getProperties();
      initialize();
      dvsMor = createDVSWithNics(dvsName);
      setupPortgroups(dvsMor);
      return true;
   }

   @Test(description = "Update vDS HealthCheck config with null as input argument")
   public
         void test() throws Exception {
      try {
         vmwareDvsHelper.updateDVSHealthCheckConfig(dvsMor, null);
         log.error("Returned from invoking updateDVSHealthCheckConfig " +
                "with null parameter,  the API did not throw any exception");
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new InvalidRequest();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
   }

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp() throws Exception {

      boolean done = false;
      log.info("Destroying the DVS: {} ", dvsName);
      done = destroy(dvsMor);
      return done;

   }

}
