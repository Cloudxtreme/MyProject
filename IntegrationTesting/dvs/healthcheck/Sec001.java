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

import static com.vmware.vcqa.TestConstants.*;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVSWITCH_MODIFY;

import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.vim.AuthorizationHelper;

public class Sec001 extends HealthCheckTestBase {

   private AuthorizationHelper authHelper;
   private final String testUser = GENERIC_USER;

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

      // Login with Test user with "DVSWITCH_MODIFY" privilege.
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), data
            .getString(TESTINPUT_USERNAME), data.getString(TESTINPUT_PASSWORD));
      authHelper.setPermissions(dvsMor, DVSWITCH_MODIFY, testUser, false);
      return authHelper.performSecurityTestsSetup(testUser);

   }

   @Test(description = "Enable/disable HealthCheck Or Edit HealthCheck " + "option to the DVS by a user having DVSwitch.Modify privilege.")
   public
         void test() throws Exception {
      // Enable HealthCheck config
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

      boolean done = true;
      if (authHelper != null) {
         done &= authHelper.performSecurityTestsCleanup();
      }
      log.info("Destroying the DVS: {} ", dvsName);
      done &= this.destroy(dvsMor);
      return done;
   }

}
