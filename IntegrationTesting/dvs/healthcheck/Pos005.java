package dvs.healthcheck;

import org.testng.annotations.Factory;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.HostMemberHealthCheckResult;
import com.vmware.vc.HostMemberRuntimeInfo;
import com.vmware.vc.VMwareDVSHealthCheckConfig;
import com.vmware.vc.VMwareDVSTeamingHealthCheckConfig;
import com.vmware.vc.VMwareDVSVlanMtuHealthCheckConfig;
import com.vmware.vc.DVSRuntimeInfo;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.util.Assert.assertNotNull;

import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

public class Pos005 extends HealthCheckTestBase {

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

      SetVlanforDvpg();

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

      Thread.sleep(120000);
      DVSRuntimeInfo dvsRuntimeInfo = vmwareDvsHelper.getRuntimeInfo(dvsMor);
      assertNotNull(dvsRuntimeInfo, "DvsRuntimeinfo is NULL");
      HostMemberRuntimeInfo[] hostMemberRuntimeInfo = null;
      hostMemberRuntimeInfo = com.vmware.vcqa.util.TestUtil.vectorToArray(dvsRuntimeInfo.getHostMemberRuntime(), com.vmware.vc.HostMemberRuntimeInfo.class);
      assertNotNull(hostMemberRuntimeInfo,
            "Retrieved HostMemberRuntimeInfo is NULL");
      assertTrue(hostMemberRuntimeInfo.length > 0,
            "The length of retrieved " + "HostMemberRuntimeInfo is zero");

      boolean foundVMwareDVSMtuHealthCheckResult = false;
      boolean foundVMwareDVSTeamingHealthCheckResult = false;
      boolean foundVMwareDVSVlanHealthCheckResult = false;

      HostMemberHealthCheckResult[] hostMemberHealthCheckResult = null;
      for (int i = 0; i < hostMemberRuntimeInfo.length; i++) {
         hostMemberHealthCheckResult = com.vmware.vcqa.util.TestUtil
               .vectorToArray(hostMemberRuntimeInfo[0].getHealthCheckResult(), com.vmware.vc.HostMemberHealthCheckResult.class);
         assertNotNull(hostMemberHealthCheckResult,
               "Retrieved HostMemberHealthCheckResult is NULL");
         assertTrue(
               hostMemberHealthCheckResult.length > 0,
               "The length of retrieved " + "HostMemberHealthCheckResult is zero");
         String resultClassName = null;
         for (int j = 0; j < hostMemberHealthCheckResult.length; j++) {
            resultClassName = hostMemberHealthCheckResult[j].getClass()
                  .getName();
            log.debug("Class Name is: " + resultClassName);
            if (resultClassName
                  .equals(DVSTestConstants.VMWAREDVSMTUHEALTHCHECKRESULT_CLASS_NAME)) {
               foundVMwareDVSMtuHealthCheckResult = true;
            } else if (resultClassName
                  .equals(DVSTestConstants.VMWAREDVSTEAMINGHEALTHCHECKRESULT_CLASS_NAME)) {
               foundVMwareDVSTeamingHealthCheckResult = true;
            } else if (resultClassName
                  .equals(DVSTestConstants.VMWAREDVSVLANHEALTHCHECKRESULT_CLASS_NAME)) {
               foundVMwareDVSVlanHealthCheckResult = true;
            }
         }
      }

      assertTrue(foundVMwareDVSMtuHealthCheckResult,
            "Succeeded to get VMwareDVSMtuHealthCheckResult runtime info",
            "Failed to get VMwareDVSMtuHealthCheckResult runtime info");
      assertTrue(foundVMwareDVSTeamingHealthCheckResult,
            "Succeeded to get VMwareDVSTeamingHealthCheckResult runtime info",
            "Failed to get VMwareDVSTeamingHealthCheckResult runtime info");
      assertTrue(foundVMwareDVSVlanHealthCheckResult,
            "Succeeded to get VMwareDVSVlanHealthCheckResult runtime info",
            "Failed to get VMwareDVSVlanHealthCheckResult runtime info");
   }

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp() throws Exception {

      boolean done = false;
      log.info("Destroying the DVS: {} ", dvsName);
      done = destroy(dvsMor);
      return done;

   }

}
