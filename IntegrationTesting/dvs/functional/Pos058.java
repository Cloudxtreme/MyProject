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

import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupPolicy;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.MessageConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * DESCRIPTION:<br>
 * (Moving live uplinkport to new uplink DVPG ) <br>
 * TARGET: VC <br>
 * NOTE : PR#534823 <br>
 * <br>
 * SETUP:<br>
 * 1.Create a vDS with host by one pnic to uplink PG<br>
 * TEST:<br>
 * 2.Add new uplink DVPG. <br>
 * 3.Move default uplink ports to new uplink DVPG <br>
 * CLEANUP:<br>
 * 4. Destroy vDs<br>
 */
public class Pos058 extends TestBase
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
   private ManagedObjectReference vDsMor = null;
   private String[] freePnics = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      super.setTestDescription("PR# 534823  : test case \n"
               + " 1.Create a vDS with host by one pnic to uplink PG\n"
               + " 2.Add new  uplink DVPG.\n"
               + " 3.Move default uplinkports  to new Uplionk DVPG\n");
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
      freePnics = ins.getPNicIds(this.hostMor);
      assertTrue((freePnics != null && freePnics.length >= 2),
               "Failed to get required(2) no of freePnics");
      this.vDsMor =
               this.iFolder.createDistributedVirtualSwitch(this.getTestId());
      assertNotNull(this.vDsMor, "Cannot create the distributed virtual "
               + "switch with the config spec passed");
      Vector<ManagedObjectReference> DvsMorList =
               new Vector<ManagedObjectReference>();
      DvsMorList.add(this.vDsMor);
      assertTrue(DVSUtil.addFreePnicAndHostToDVS(connectAnchor, this.hostMor,
               DvsMorList), "Successfully added host to DVS",
               "Unable to add hosts to DVS");
      return true;

   }

   @Override
   @Test(description = "PR# 534823  : test case \n"
               + " 1.Create a vDS with host by one pnic to uplink PG\n"
               + " 2.Add new  uplink DVPG.\n"
               + " 3.Move default uplinkports  to new Uplionk DVPG\n")
   public void test()
      throws Exception
   {
      ManagedObjectReference uplinkPortGroupMor = null;
      DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
      DVPortgroupPolicy policy = null;
      List<String> uplinkDVportKeys = null;
      uplinkPortGroupMor = this.iDVS.getUplinkPortgroups(vDsMor).get(0);
      dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
      dvPortgroupConfigSpec.setConfigVersion(this.iDVPG.getConfigInfo(
               uplinkPortGroupMor).getConfigVersion());
      policy = new DVPortgroupPolicy();
      policy.setLivePortMovingAllowed(true);
      dvPortgroupConfigSpec.setPolicy(policy);
      assertTrue((this.iDVPG.reconfigure(uplinkPortGroupMor,
               dvPortgroupConfigSpec)),
               "Successfully reconfigured the portgroup",
               "Failed to reconfigure the portgroup");
      uplinkDVportKeys = this.iDVPG.getPortKeys(uplinkPortGroupMor);
      uplinkPortGroupMor =
               DVSUtil.createUplinkPortGroup(connectAnchor, this.vDsMor, null,
                        0);
      dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
      dvPortgroupConfigSpec.setConfigVersion(this.iDVPG.getConfigInfo(
               uplinkPortGroupMor).getConfigVersion());
      policy = new DVPortgroupPolicy();
      policy.setLivePortMovingAllowed(true);
      dvPortgroupConfigSpec.setPolicy(policy);
      assertTrue((this.iDVPG.reconfigure(uplinkPortGroupMor,
               dvPortgroupConfigSpec)),
               "Successfully reconfigured the portgroup",
               "Failed to reconfigure the portgroup");
      assertTrue(this.iDVS.movePort(vDsMor, uplinkDVportKeys
               .toArray(new String[uplinkDVportKeys.size()]), this.iDVPG
               .getConfigInfo(uplinkPortGroupMor).getKey()),
               "Successfully moved given ports.", "Failed to move the ports.");
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
