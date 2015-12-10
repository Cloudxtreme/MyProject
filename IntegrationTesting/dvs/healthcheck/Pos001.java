package dvs.healthcheck;

import org.testng.annotations.Factory;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.DVSCreateSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSFeatureCapability;
import com.vmware.vc.VMwareDVSHealthCheckCapability;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager;

public class Pos001 extends HealthCheckTestBase {

   /*
    * private data variables
    */
   private String vDsVersion = null;
   private DistributedVirtualSwitchManager dvsManager = null;
   private ManagedObjectReference dvsManagerMor = null;
   private DVSCreateSpec createSpec = null;
   private static String VLANMTUSUPPORTED = "vlanMtuSupported";
   private static String TEAMINGSUPPORTED = "teamingSupported";
   private boolean vlanMtuSupported = false;
   private boolean teamingSupported = false;

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
   public boolean testSetUp() throws Exception {
      vlanMtuSupported = this.data.getBoolean(VLANMTUSUPPORTED);
      teamingSupported = this.data.getBoolean(TEAMINGSUPPORTED);

      DVS = new DistributedVirtualSwitch(connectAnchor);
      vDsVersion = this.data.getString(DVSTestConstants.NEW_VDS_VERSION);
      spec = DVSUtil.getProductSpec(connectAnchor, vDsVersion);
      assertNotNull(spec,
            "Successfully obtained the productSpec for : " + vDsVersion,
            "Null returned for productSpec for :" + vDsVersion);
      createSpec = DVSUtil.createDVSCreateSpec(DVSUtil
            .createDefaultDVSConfigSpec(null), spec, null);
      assertNotNull(createSpec, "DVSCreateSpec is null");
      dvsMor = DVSUtil.createDVSFromCreateSpec(connectAnchor, createSpec);
      assertNotNull(dvsMor, "Successfully created the DVSwitch",
            "Null returned for Distributed Virtual Switch MOR");
      return true;
   }

   @Test(description = "Create VDS with desired version and check " + "VmwareHealthCheckFeatureCapability")
   public
         void test() throws Exception {
      boolean bTeamingSupported = false;
      boolean bVlanMtuSupported = false;

      dvsManager = new DistributedVirtualSwitchManager(connectAnchor);
      dvsManagerMor = dvsManager.getDvSwitchManager();
      log.debug("Invoking queryDvsFeatureCapability..");
      VMwareDVSFeatureCapability featureCapability = (VMwareDVSFeatureCapability) this.dvsManager
            .queryDvsFeatureCapability(dvsManagerMor, spec);
      VMwareDVSHealthCheckCapability healthCheckCapability = (VMwareDVSHealthCheckCapability) featureCapability
            .getHealthCheckCapability();
      bTeamingSupported = healthCheckCapability.isTeamingSupported();
      bVlanMtuSupported = healthCheckCapability.isVlanMtuSupported();
      assertTrue(
            (bTeamingSupported == vlanMtuSupported && bVlanMtuSupported == teamingSupported),
            "Test Failed");
   }

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp() throws Exception {
      if (this.dvsMor != null) {
         assertTrue((this.DVS.destroy(dvsMor)), "Successfully deleted DVS",
               "Unable to delete DVS");
      }
      return true;
   }

}
