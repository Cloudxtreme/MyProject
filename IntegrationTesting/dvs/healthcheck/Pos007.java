package dvs.healthcheck;

import java.util.List;

import org.testng.annotations.Factory;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.DVSKeyedOpaqueData;
import com.vmware.vc.DVSOpaqueDataConfigInfo;
import com.vmware.vc.DVSOpaqueData;
import com.vmware.vc.DVSOpaqueDataList;
import com.vmware.vc.DVSSelection;
import com.vmware.vc.DistributedVirtualSwitchHostMember;
import com.vmware.vc.HostDVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.SelectionSet;
import com.vmware.vc.UserSession;
import com.vmware.vc.VMwareDVSHealthCheckConfig;
import com.vmware.vc.VMwareDVSTeamingHealthCheckConfig;
import com.vmware.vc.VMwareDVSVlanMtuHealthCheckConfig;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertNotEmpty;
import static com.vmware.vcqa.util.Assert.assertTrue;

import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.internal.vim.InternalServiceInstance;
import com.vmware.vcqa.internal.vim.dvs.InternalDistributedVirtualSwitchManager;
import com.vmware.vcqa.internal.vim.dvs.InternalHostDistributedVirtualSwitchManager;

import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ServiceInstance;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

public class Pos007 extends HealthCheckTestBase {

   private ManagedObjectReference vdsMgrMor = null;
   private InternalDistributedVirtualSwitchManager vdsMgr = null;
   private ServiceInstance serviceInstance = null;
   private String vDsUUID = null;
   final String OPAQUE_VLANCHK_KEY = DVSTestConstants.OPAQUE_HEALTHCHECK_VLANCHK_KEY;
   final String OPAQUE_TEAMCHK_KEY = DVSTestConstants.OPAQUE_HEALTHCHECK_TEAMCHK_KEY;
   private int vlanid = 0;
   boolean is_iphash = false;

   void setupVariables() throws Exception {
      serviceInstance = new ServiceInstance(connectAnchor);
      vdsMgrMor = serviceInstance.getSC().getDvSwitchManager();
      vdsMgr = new InternalDistributedVirtualSwitchManager(connectAnchor);
      vDsUUID = dvsCfgInfo.getUuid();
   }

   void verifyVlanOpaqueData(byte[] vlanByteArray) throws Exception {
      int bitNum = vlanid % 8;
      int vectorNum = vlanid / 8;
      int bitPosition = 1 << bitNum;
      boolean status = true;

      int vlanActualMap = vlanByteArray[vectorNum];
      log.debug("Actual vlan map is : " + Integer.toBinaryString(vlanActualMap));
      log.debug("Expected vlan map is : " + Integer.toBinaryString(bitPosition));
      if ((vlanActualMap & bitPosition) == 0) {
         status = false;
      }

      assertTrue(status, "Vlan map is not matched.");
   }

   void verifyTeamingOpaqueData(byte[] teamingByteArray) throws Exception {

      boolean status = true;
      int teamingActualMap = teamingByteArray[0];

      if ((is_iphash == false && teamingActualMap != 0) || (is_iphash == true && teamingActualMap != 1)) {
         status = false;
      }

      assertTrue(status, "Teaming map is not matched.");
   }

   void VerifyVlanTeamingStreamFromVDS() throws Exception {

      SelectionSet[] dvsSelectionList = new SelectionSet[1];
      DVSSelection dvsSelection = new DVSSelection();
      dvsSelection.setDvsUuid(vDsUUID);
      dvsSelectionList[0] = dvsSelection;

      List<DVSOpaqueDataConfigInfo> dvsOpaqueDataList = null;
      dvsOpaqueDataList = vdsMgr.fetchOpaqueData(vdsMgrMor, dvsSelectionList,
            false);

      assertNotNull(dvsOpaqueDataList, "dvsOpaqueDataList is NULL.");

      for (DVSOpaqueDataConfigInfo opaqueDataConfig : dvsOpaqueDataList) {
         DVSKeyedOpaqueData[] opaqueData = com.vmware.vcqa.util.TestUtil
               .vectorToArray(opaqueDataConfig.getKeyedOpaqueData(), com.vmware.vc.DVSKeyedOpaqueData.class);
         for (int i = 0; i < opaqueData.length; i++) {
            log.debug("key is : " + opaqueData[i].getKey());
            if (opaqueData[i].getKey().equals(OPAQUE_VLANCHK_KEY)) {
               if (opaqueData[i].getOpaqueData().length != 512) {
                  throw new Exception("Returned bytes is not equal to 512");
               }
               verifyVlanOpaqueData(opaqueData[i].getOpaqueData());
            } else if (opaqueData[i].getKey().equals(OPAQUE_TEAMCHK_KEY)) {
               verifyTeamingOpaqueData(opaqueData[i].getOpaqueData());
            }
         }
      }
   }

   void VerifyVlanTeamingStreamFromHost(ManagedObjectReference hostMor)
         throws Exception {

      HostSystem hostSystem = new HostSystem(connectAnchor);
      UserSession hostLoginSession = null;
      ConnectAnchor hostConnectAnchor = new ConnectAnchor(hostSystem
            .getHostName(hostMor), connectAnchor.getPort());
      SessionManager sessionManager = new SessionManager(hostConnectAnchor);
      ManagedObjectReference sessionMgrMor = sessionManager.getSessionManager();
      hostLoginSession = new SessionManager(hostConnectAnchor).login(
            sessionMgrMor, TestConstants.ESX_USERNAME,
            TestConstants.ESX_PASSWORD, null);
      assertNotNull(hostLoginSession, "Cannot login into the host");
      InternalHostDistributedVirtualSwitchManager hdvs = new InternalHostDistributedVirtualSwitchManager(
            hostConnectAnchor);
      InternalServiceInstance msi = new InternalServiceInstance(
            hostConnectAnchor);
      ManagedObjectReference hostDVSMgrMor = msi
            .getInternalServiceInstanceContent()
            .getHostDistributedVirtualSwitchManager();

      HostDVSConfigSpec hostDVSConfigSpec = null;
      hostDVSConfigSpec = hdvs.retrieveDVSConfigSpec(hostDVSMgrMor, vDsUUID);
      DVSOpaqueDataList dvsOpaqueDataList = hostDVSConfigSpec.getDvsOpaqueDataList();
      assertNotNull(dvsOpaqueDataList,
            "hostDVSConfigSpec.getDvsOpaqueDataList() retruned NULL from host.");
      DVSOpaqueData[] opaqueData= com.vmware.vcqa.util.TestUtil.vectorToArray(dvsOpaqueDataList.getOpaqueData(), com.vmware.vc.DVSOpaqueData.class);
      assertNotNull(opaqueData, "No opaque data found in the host.");
      assertNotEmpty(opaqueData, "No actual opaque data found in the host.");

      for (int i = 0; i < opaqueData.length; i++) {
         log.debug("key is : " + opaqueData[i].getKey());
         if (opaqueData[i].getKey().equals(OPAQUE_VLANCHK_KEY)) {
            if (opaqueData[i].getOpaqueData().length != 512) {
               throw new Exception("Returned bytes is not equal to 512");
            }
            verifyVlanOpaqueData(opaqueData[i].getOpaqueData());
         } else if (opaqueData[i].getKey().equals(OPAQUE_TEAMCHK_KEY)) {
            verifyTeamingOpaqueData(opaqueData[i].getOpaqueData());
         }
      }
   }

   void VerifyOpaqueDataOnHosts() throws Exception {
      ManagedObjectReference hostMor = null;

      DistributedVirtualSwitchHostMember[] hostMembers = dvsCfgInfo.getHost().toArray(new DistributedVirtualSwitchHostMember[0]);
      if (hostMembers != null && hostMembers.length > 0) {
         for (DistributedVirtualSwitchHostMember hostMember : hostMembers) {
            hostMor = hostMember.getConfig().getHost();
            if (hostMor != null) {
               VerifyVlanTeamingStreamFromHost(hostMor);
            } else {
               log.warn("hostMor is null on " + "DistributedVirtualSwitchHostMember config");
            }
         }
      }
   }

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

   @Test(description = "Query and vlan and teaming opaque data from vDS and hosts.")
   public
         void test() throws Exception {

      setupVariables();

      // set vlan for DVPG only, keep default teaming policy for DVPG.
      vlanid = SetVlanforDvpg();

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

      VerifyVlanTeamingStreamFromVDS();
      VerifyOpaqueDataOnHosts();

      // Set vlan and teaming policy to iphash and verify opaque data again.
      vlanid = SetVlanforDvpg();
      SetTeamingPolicyforDvpg("loadbalance_ip");
      is_iphash = true;
      Thread.sleep(60000);
      VerifyVlanTeamingStreamFromVDS();
      VerifyOpaqueDataOnHosts();
   }

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp() throws Exception {

      boolean done = false;
      log.info("Destroying the DVS: {} ", dvsName);
      done = destroy(dvsMor);
      return done;
   }
}
