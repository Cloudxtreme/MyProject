package dvs.healthcheck;

import org.testng.annotations.Factory;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.VMwareDVSVlanMtuHealthCheckConfig;

import static com.vmware.vcqa.util.Assert.assertTrue;
import com.vmware.vcqa.execution.TestExecutionUtils;

public class Pos002 extends HealthCheckTestBase {

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

   @Test(description = "Configure Health Check for vDS with VMwareDVSVlanMtuHealthCheckConfig parameter")
   public
         void test() throws Exception {
      VMwareDVSVlanMtuHealthCheckConfig[] vlanmtuHealthCheckConfig = new VMwareDVSVlanMtuHealthCheckConfig[1];
      vlanmtuHealthCheckConfig[0] = new VMwareDVSVlanMtuHealthCheckConfig();
      vlanmtuHealthCheckConfig[0].setEnable(vlanMtuEnabled);
      vlanmtuHealthCheckConfig[0].setInterval(vlanMtuInterval);

      assertTrue(configHealthCheck(vlanmtuHealthCheckConfig),
            "Successfully to configure VlanMtuHealthCheck",
            "Failed to configure VlanMtuHealthCheck");

   }

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp() throws Exception {

      boolean done = false;
      log.info("Destroying the DVS: {} ", dvsName);
      done = destroy(dvsMor);
      return done;

   }

}
