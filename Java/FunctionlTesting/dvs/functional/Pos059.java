/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupPolicy;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.HostConfigChangeOperation;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostProxySwitchConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.UserSession;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.MessageConstants;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * DESCRIPTION:<br>
 * (Add vmnics in a certain order to multiple uplink DVPGs.) <br>
 * TARGET: VC <br>
 * NOTE : PR#534823 <br>
 * <br>
 * SETUP:<br>
 * 1. Create a vDS and add free pnic from host to it <br>
 * * TEST:<br>
 * 2.Add new uplink DVPG 3. Remove pnic from default uplink DVPG via VC <br>
 * 4. Connect to hostd and add the removed pnic to create uplink DVPG 5. Connect
 * another free pnic of the host to default DVPG through VC. <br>
 * CLEANUP:<br>
 * 6. Destroy vDs<br>
 */
public class Pos059 extends TestBase
{
   /*
    * private data variables
    */
   private SessionManager sessionManager = null;
   private HostSystem ihs = null;
   private ManagedObjectReference hostMor = null;
   private Folder iFolder = null;
   private NetworkSystem ins = null;
   private DistributedVirtualSwitch iDVS = null;
   private DistributedVirtualPortgroup iDVPG = null;
   private ManagedObjectReference vDsMor = null;
   private String[] freePnics = null;
   private List<String> uplinkDVportKeys = null;
   private String hostName = null;
   private Map<String, List<String>> hmUplinks =
            new HashMap<String, List<String>>();

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      super
               .setTestDescription("PR# 534823  : test case \n"
                        + " 1. Create a vDS and add free  pnic from host  to it.."
                        + " 2.Add new  uplink DVPG"
                        + " 3.Remove pnic from default uplink DVPG  via VC from default DVPG"
                        + " 4.Connect to hostd and add the removed pnic to create uplink DVPG"
                        + " 5.Connect another free pnic of the host to default DVPG through VC.");
   }

   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception

   {
      this.iFolder = new Folder(connectAnchor);
      this.iDVS = new DistributedVirtualSwitchHelper(connectAnchor);
      this.ihs = new HostSystem(connectAnchor);
      this.ins = new NetworkSystem(connectAnchor);
      this.iDVPG = new DistributedVirtualPortgroup(connectAnchor);
      hostMor = ihs.getConnectedHost(null);
      assertNotNull(hostMor, MessageConstants.HOST_GET_PASS,
               MessageConstants.HOST_GET_PASS);
      hostName = ihs.getHostName(hostMor);
      freePnics = ins.getPNicIds(hostMor);
      assertTrue((freePnics != null && freePnics.length >= 2),
               "Failed to get required(2) no of freePnics");
      vDsMor = iFolder.createDistributedVirtualSwitch(getTestId());
      assertNotNull(vDsMor, "Cannot create the distributed virtual "
               + "switch with the config spec passed");
      Vector<ManagedObjectReference> DvsMorList =
               new Vector<ManagedObjectReference>();
      DvsMorList.add(vDsMor);
      assertTrue(DVSUtil.addFreePnicAndHostToDVS(connectAnchor, hostMor,
               DvsMorList), "Successfully added host to DVS",
               "Unable to add hosts to DVS");
      return true;

   }

   @Override
   @Test(description = "PR# 534823  : test case \n"
                        + " 1. Create a vDS and add free  pnic from host  to it.."
                        + " 2.Add new  uplink DVPG"
                        + " 3.Remove pnic from default uplink DVPG  via VC from default DVPG"
                        + " 4.Connect to hostd and add the removed pnic to create uplink DVPG"
                        + " 5.Connect another free pnic of the host to default DVPG through VC.")
   public void test()
      throws Exception
   {
      String pnic = null;
      ManagedObjectReference uplinkPortGroupMor = null;
      ManagedObjectReference defaultUplinkPortGroupMor = null;
      DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
      DVPortgroupPolicy policy = null;
      String uplinkPortKey = null;

      defaultUplinkPortGroupMor = iDVS.getUplinkPortgroups(vDsMor).get(0);
      dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
      dvPortgroupConfigSpec.setConfigVersion(iDVPG.getConfigInfo(
               defaultUplinkPortGroupMor).getConfigVersion());
      policy = new DVPortgroupPolicy();
      policy.setLivePortMovingAllowed(true);
      dvPortgroupConfigSpec.setPolicy(policy);
      assertTrue((iDVPG.reconfigure(defaultUplinkPortGroupMor,
               dvPortgroupConfigSpec)),
               "Successfully reconfigured the portgroup",
               "Failed to reconfigure the portgroup");
      uplinkPortKey =
               iDVS.getFreePortInPortgroup(vDsMor, iDVPG.getConfigInfo(
                        defaultUplinkPortGroupMor).getKey(), null);
      uplinkDVportKeys = iDVPG.getPortKeys(defaultUplinkPortGroupMor);
      Map<String, DistributedVirtualPort> connectedEntitiespMap =
               DVSUtil
                        .getConnecteeInfo(connectAnchor, vDsMor,
                                 uplinkDVportKeys);
      for (Map.Entry<String, DistributedVirtualPort> entry : connectedEntitiespMap
               .entrySet()) {
         pnic = entry.getValue().getConnectee().getNicKey();
      }
      uplinkPortGroupMor =
               DVSUtil.createUplinkPortGroup(connectAnchor, vDsMor, null, 1);

      /*
       * Move free port from default uplink DVPG
       */
      dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
      dvPortgroupConfigSpec.setConfigVersion(iDVPG.getConfigInfo(
               uplinkPortGroupMor).getConfigVersion());
      policy = new DVPortgroupPolicy();
      policy.setLivePortMovingAllowed(true);
      dvPortgroupConfigSpec.setPolicy(policy);
      assertTrue(
               (iDVPG.reconfigure(uplinkPortGroupMor, dvPortgroupConfigSpec)),
               "Successfully reconfigured the portgroup",
               "Failed to reconfigure the portgroup");

      assertTrue(iDVS.movePort(vDsMor, new String[] { uplinkPortKey }, iDVPG
               .getConfigInfo(uplinkPortGroupMor).getKey()),
               "Successfully moved given ports.", "Failed to move the ports.");

      List<String> alUplink = new ArrayList<String>();
      alUplink.add(iDVPG.getConfigInfo(uplinkPortGroupMor).getKey());
      alUplink.add(null);
      hmUplinks.put(pnic, alUplink);
      assertTrue(DVSUtil.removeAllUplinks(connectAnchor, hostMor, vDsMor),
               "Successfully removed all vmnics from vDs ",
               "Failed to remove all vmnics from vDs ");
      assertTrue(performOperationsOnhostd(hmUplinks),
               "Successfully added vmnics to vDs ",
               "Failed to add vmnics to vDs ");
      alUplink = new ArrayList<String>();
      alUplink.add(iDVPG.getConfigInfo(defaultUplinkPortGroupMor).getKey());
      alUplink.add(iDVPG.getPortKeys(uplinkPortGroupMor).get(0));
      hmUplinks.put(ins.getPNicIds(hostMor)[0], alUplink);
      assertTrue(DVSUtil.addUplinks(connectAnchor, hostMor, vDsMor, hmUplinks),
               "Successfully added vmnics to vDs ",
               "Failed to add vmnics to vDs ");

   }

   private boolean performOperationsOnhostd(Map<String, List<String>> hmUplink)
      throws Exception
   {
      ConnectAnchor hostConnectAnchor = null;
      boolean status = true;
      NetworkSystem hostIns = null;
      HostSystem hostIhs = null;
      HostProxySwitchConfig originalHostProxySwitchConfig = null;
      HostProxySwitchConfig updatedHostProxySwitchConfig = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
      List<DistributedVirtualSwitchHostMemberPnicSpec> pnicSpecList =
               new ArrayList<DistributedVirtualSwitchHostMemberPnicSpec>();
      HostNetworkConfig updatedNetworkConfig = null;
      ManagedObjectReference hostNWMor = null;
      ManagedObjectReference host = null;
      UserSession newLoginSession = null;
      hostConnectAnchor =
               new ConnectAnchor(hostName, data
                        .getInt(TestConstants.TESTINPUT_PORT));
      assertNotNull(hostConnectAnchor, "Null hostConnectAnchor");
      log.info("Successfully obtained the connect"
               + " anchor to the host");

      ManagedObjectReference newAuthenticationMor = null;
      sessionManager = new SessionManager(hostConnectAnchor);
      newAuthenticationMor = sessionManager.getSessionManager();
      assertNotNull(newAuthenticationMor, "Null session manager");
      newLoginSession =
               sessionManager.login(newAuthenticationMor,
                        TestConstants.ESX_USERNAME, TestConstants.ESX_PASSWORD,
                        null);
      assertNotNull(newLoginSession, "Null login session");
      hostIns = new NetworkSystem(hostConnectAnchor);
      hostIhs = new HostSystem(hostConnectAnchor);
      host = hostIhs.getHost(hostName);
      hostNWMor = hostIns.getNetworkSystem(host);
      originalHostProxySwitchConfig =
               iDVS.getDVSVswitchProxyOnHost(vDsMor, hostMor);
      updatedHostProxySwitchConfig =
               (HostProxySwitchConfig) TestUtil
                        .deepCopyObject(originalHostProxySwitchConfig);
      updatedHostProxySwitchConfig
               .setChangeOperation(HostConfigChangeOperation.EDIT.value());
      if (updatedHostProxySwitchConfig.getSpec() != null
               && updatedHostProxySwitchConfig.getSpec().getBacking() != null
               && updatedHostProxySwitchConfig.getSpec().getBacking() instanceof DistributedVirtualSwitchHostMemberPnicBacking) {
         pnicBacking =
                  (DistributedVirtualSwitchHostMemberPnicBacking) updatedHostProxySwitchConfig
                           .getSpec().getBacking();

         for (Map.Entry<String, List<String>> entry : hmUplinks.entrySet()) {
            pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
            pnicSpec.setPnicDevice(entry.getKey());
            pnicSpec.setUplinkPortgroupKey(entry.getValue().get(0));
            pnicSpec.setUplinkPortKey(entry.getValue().get(1));
            pnicSpecList.add(pnicSpec);
         }

         pnicBacking.getPnicSpec().clear();
         pnicBacking.getPnicSpec()
                  .addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(pnicSpecList
                           .toArray(new DistributedVirtualSwitchHostMemberPnicSpec[pnicSpecList
                                    .size()])));
         updatedHostProxySwitchConfig.getSpec().setBacking(pnicBacking);
         updatedNetworkConfig = new HostNetworkConfig();
         if (updatedHostProxySwitchConfig != null) {
            updatedNetworkConfig.getProxySwitch().clear();
            updatedNetworkConfig.getProxySwitch()
                     .addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new HostProxySwitchConfig[] { updatedHostProxySwitchConfig }));
            status =
                     hostIns.updateNetworkConfig(hostNWMor,
                              updatedNetworkConfig,
                              TestConstants.CHANGEMODE_MODIFY);
         }
      }

      return status;
   }

   /**
    * Method to restore the state as it was before the test is started.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      if (vDsMor != null) {
         assertTrue(iDVS.destroy(vDsMor), " Failed to destroy vDs");
      }

      return true;
   }

}
