package dvs.healthcheck;

import javax.xml.ws.soap.SOAPFaultException;

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
import static com.vmware.vcqa.vim.PrivilegeConstants.DVSWITCH_MODIFY;

import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.vim.AuthorizationHelper;

public class Sec002 extends HealthCheckTestBase {

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
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), true,
            data.getString(TESTINPUT_USERNAME), data
                  .getString(TESTINPUT_PASSWORD));
      authHelper.setPermissions(dvsMor, DVSWITCH_MODIFY, testUser, false);
      return authHelper.performSecurityTestsSetup(testUser);

   }

   @Test(description = "Enable/disable or Edit HealthCheck Or Edit HealthCheck " + "option to the DVS by a user without DVSwitch.Modify privilege.")
   public
         void test() throws Exception {

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
         boolean success = false;
         if (excep.getClass().equals(SOAPFaultException.class)) {
            log.info("API threw SOAPFaultException exception as expected");
            success = true;
         }
         com.vmware.vcqa.util.Assert.assertTrue(success,
            "MethodFault mismatch!");
      }
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
