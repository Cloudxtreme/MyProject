package dvs.healthcheck;

import org.testng.annotations.Factory;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.InvalidArgument;
import com.vmware.vc.VMwareDVSVlanMtuHealthCheckConfig;

import com.vmware.vcqa.execution.TestExecutionUtils;

public class Neg004 extends HealthCheckTestBase {

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

   @Test(description = "Configure Health Check for vDS with " + "duplicated VMwareDVSVlanMtuHealthCheckConfig parameter")
   public
         void test() throws Exception {
      try {
         VMwareDVSVlanMtuHealthCheckConfig[] vlanmtuHealthCheckConfig = new VMwareDVSVlanMtuHealthCheckConfig[2];
         vlanmtuHealthCheckConfig[0] = new VMwareDVSVlanMtuHealthCheckConfig();
         vlanmtuHealthCheckConfig[0].setEnable(vlanMtuEnabled);
         vlanmtuHealthCheckConfig[0].setInterval(vlanMtuInterval);
         vlanmtuHealthCheckConfig[1] = new VMwareDVSVlanMtuHealthCheckConfig();
         vlanmtuHealthCheckConfig[1].setEnable(vlanMtuEnabled);
         vlanmtuHealthCheckConfig[1].setInterval(vlanMtuInterval);
         configHealthCheck(vlanmtuHealthCheckConfig);
         log.error("Returned from invoking updateDVSHealthCheckConfig " +
                "with duplicated VMwareDVSVlanMtuHealthCheckConfig " +
                "parameter,  the API did not throw any exception");
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
