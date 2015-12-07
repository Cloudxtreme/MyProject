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

import static com.vmware.vcqa.util.Assert.assertTrue;
import com.vmware.vcqa.execution.TestExecutionUtils;

public class Pos004 extends HealthCheckTestBase {

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
         + "VMwareDVSVlanMtuHealthCheckConfig and "
         + "VMwareDVSTeamingHealthCheckConfig parameters")
   public void test() throws Exception {
      VMwareDVSHealthCheckConfig[] vdsHealthCheckConfig = new VMwareDVSHealthCheckConfig[2];
      vdsHealthCheckConfig[0] = new VMwareDVSVlanMtuHealthCheckConfig();
      vdsHealthCheckConfig[0].setEnable(vlanMtuEnabled);
      vdsHealthCheckConfig[0].setInterval(vlanMtuInterval);
      vdsHealthCheckConfig[1] = new VMwareDVSTeamingHealthCheckConfig();
      vdsHealthCheckConfig[1].setEnable(teamingEnabled);
      vdsHealthCheckConfig[1].setInterval(teamingInterval);

      assertTrue(configHealthCheck(vdsHealthCheckConfig),
            "Successfully to configure HealthCheck",
            "Failed to configure HealthCheck");

   }

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp() throws Exception {

      boolean done = false;
      log.info("Destroying the DVS: {} ", dvsName);
      done = destroy(dvsMor);
      return done;

   }

}
