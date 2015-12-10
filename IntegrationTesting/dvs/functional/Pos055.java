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

import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.MessageConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * DESCRIPTION:<br>
 * (Add vmnics in a certain order.) <br>
 * TARGET: VC <br>
 * NOTE : PR#470349 <br>
 * <br>
 * SETUP:<br>
 * 1. Create a vDS with host by adding two vmnics to uplink PG <br>
 * TEST:<br>
 * 2. Remove both vmnics from vDs <br>
 * 3. Add vmnic2 to uplink1 and vmnic1 to the portgroup <br>
 * CLEANUP:<br>
 * 4. Destroy vDs<br>
 */
public class Pos055 extends TestBase
{
   /*
    * private data variables
    */
   private HostSystem ihs = null;
   private ManagedObjectReference hostMor = null;
   private Folder iFolder = null;
   private NetworkSystem ins = null;
   private DistributedVirtualSwitch iDVS = null;
   private DistributedVirtualPortgroup iDVPG = null;
   private ManagedObjectReference nsMor = null;
   private ManagedObjectReference vDsMor = null;
   private String[] freePnics = null;
   private List<String> uplinkDVportKeys = null;
   private ManagedObjectReference dvPortgroupMor = null;
   private Vector<String> pnicVec = new Vector<String>(2);
   private Vector<String> portKeyVec = new Vector<String>(2);
   private Map<String, List<String>> hmUplinks = new HashMap<String, List<String>>();

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      super.setTestDescription("PR# 470349  : test case \n"
               + " 1.Create a vDs with one host (vmnic1 connects to uplink1, vmnic2 connects to uplink2)   \n"
               + " 2. Remove both vmnics from vDs  \n"
               + " 3. Add vmnic2 to uplink1 and vmnic1 to the portgroup and verify that the operation succeeds \n");
   }

   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception

   {
      HostNetworkConfig[] hostNetworkConfig = null;

      this.iFolder = new Folder(connectAnchor);
      this.iDVS = new DistributedVirtualSwitch(connectAnchor);
      this.ihs = new HostSystem(connectAnchor);
      this.ins = new NetworkSystem(connectAnchor);
      this.iDVPG = new DistributedVirtualPortgroup(connectAnchor);
      hostMor = this.ihs.getStandaloneHost();
      assertNotNull(hostMor, MessageConstants.HOST_GET_STALONE_PASS,
               MessageConstants.HOST_GET_STALONE_FAIL);
      this.nsMor = this.ins.getNetworkSystem(this.hostMor);
      assertNotNull(hostMor, "Failed to get NetworkSystem Mor");
      freePnics = ins.getPNicIds(this.hostMor);
      assertTrue((freePnics != null && freePnics.length >= 2),
               "Failed to get required(2) no of freePnics");
      this.vDsMor = this.iFolder.createDistributedVirtualSwitch(
               this.getTestId(), hostMor);
      assertNotNull(vDsMor, "Successfully created the DVSwitch",
               "Null returned for Distributed Virtual Switch MOR");
      assertTrue(this.ins.refresh(this.nsMor),
               "Refreshed the network system of the host",
               "Failed to refresh the network information and settings");
      hostNetworkConfig = this.iDVS.getHostNetworkConfigMigrateToDVS(
               this.vDsMor, this.hostMor);
      assertTrue(
               (hostNetworkConfig != null && hostNetworkConfig.length == 2
                        && hostNetworkConfig[0] != null && hostNetworkConfig[1] != null),
               "Successfully retrieved the original and the "
                        + "updated network config of the host",
               "Can not retrieve the original and the updated "
                        + "network config");
      assertTrue(this.ins.updateNetworkConfig(this.nsMor, hostNetworkConfig[0],
               TestConstants.CHANGEMODE_MODIFY),
               "Successfully updated the host network config",
               "Can not update the host network config");

      return true;

   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "PR# 470349  : test case \n"
               + " 1.Create a vDs with one host (vmnic1 connects to uplink1, vmnic2 connects to uplink2)   \n"
               + " 2. Remove both vmnics from vDs  \n"
               + " 3. Add vmnic2 to uplink1 and vmnic1 to the portgroup and verify that the operation succeeds \n")
   public void test()
      throws Exception
   {

      dvPortgroupMor = this.iDVS.getUplinkPortgroups(vDsMor).get(0);
      uplinkDVportKeys = this.iDVPG.getPortKeys(dvPortgroupMor);
      Map<String, DistributedVirtualPort> connectedEntitiespMap = DVSUtil.getConnecteeInfo(
               connectAnchor, vDsMor, uplinkDVportKeys);
      for (Map.Entry<String, DistributedVirtualPort> entry : connectedEntitiespMap.entrySet()) {
         portKeyVec.add(entry.getKey());
         pnicVec.add(entry.getValue().getConnectee().getNicKey());
      }
      List<String> alUplink = new ArrayList<String>();
      alUplink.add(null);
      alUplink.add(portKeyVec.firstElement());
      hmUplinks.put(pnicVec.lastElement(), alUplink);
      alUplink = new ArrayList<String>();
      alUplink.add(this.iDVPG.getKey(dvPortgroupMor));
      alUplink.add(null);
      hmUplinks.put(pnicVec.firstElement(), alUplink);
      assertTrue(DVSUtil.removeAllUplinks(connectAnchor, this.hostMor,
               this.vDsMor), "Successfully removed all vmnics from vDs ",
               "Failed to remove all vmnics from vDs ");
      assertTrue(DVSUtil.addUplinks(connectAnchor, hostMor, vDsMor, hmUplinks),
               "Successfully added vmnics to vDs ",
               "Failed to add vmnics to vDs ");

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
      if (this.vDsMor != null) {
         assertTrue(this.iDVS.destroy(this.vDsMor), " Failed to destroy vDs");
      }

      return true;
   }

}
