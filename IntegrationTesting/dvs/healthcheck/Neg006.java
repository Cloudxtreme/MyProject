package dvs.healthcheck;

import org.testng.annotations.Factory;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.VMwareDVSHealthCheckConfig;
import com.vmware.vc.VMwareDVSTeamingHealthCheckConfig;
import com.vmware.vc.VMwareDVSVlanMtuHealthCheckConfig;
import com.vmware.vc.NotSupported;

import com.vmware.vcqa.execution.TestExecutionUtils;

public class Neg006 extends HealthCheckTestBase {

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
      dvsMor = createDVSWithNicsEx(dvsName, "5.0.0");
      setupPortgroups(dvsMor);
      return true;
   }

   @Test()
   public void test() throws Exception {
      try {
         VMwareDVSHealthCheckConfig[] vdsHealthCheckConfig = new VMwareDVSHealthCheckConfig[2];
         vdsHealthCheckConfig[0] = new VMwareDVSVlanMtuHealthCheckConfig();
         vdsHealthCheckConfig[0].setEnable(vlanMtuEnabled);
         vdsHealthCheckConfig[0].setInterval(vlanMtuInterval);
         vdsHealthCheckConfig[1] = new VMwareDVSTeamingHealthCheckConfig();
         vdsHealthCheckConfig[1].setEnable(teamingEnabled);
         vdsHealthCheckConfig[1].setInterval(teamingInterval);
         configHealthCheck(vdsHealthCheckConfig);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new NotSupported();
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
