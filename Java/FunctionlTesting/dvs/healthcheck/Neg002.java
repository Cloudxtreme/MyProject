package dvs.healthcheck;

import org.testng.annotations.Factory;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.InvalidArgument;
import com.vmware.vc.VMwareDVSTeamingHealthCheckConfig;

import com.vmware.vcqa.execution.TestExecutionUtils;

public class Neg002 extends HealthCheckTestBase {

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

   @Test(description = "Configure Health Check for vDS with " + ""
         + "-1 as interval value")
   public void test() throws Exception {
      try {
         VMwareDVSTeamingHealthCheckConfig[] teamingHealthCheckConfig = new VMwareDVSTeamingHealthCheckConfig[1];
         teamingHealthCheckConfig[0] = new VMwareDVSTeamingHealthCheckConfig();
         teamingHealthCheckConfig[0].setEnable(teamingEnabled);
         teamingHealthCheckConfig[0].setInterval(teamingInterval);
         configHealthCheck(teamingHealthCheckConfig);
         log.error("Returned from invoking configHealthCheck " +
            "with invalid parameter,  the API did not throw any exception");
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new InvalidArgument();
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
