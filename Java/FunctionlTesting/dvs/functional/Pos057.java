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
 * (Connecting Host PNICs to multiple uplink portgroups ) <br>
 * TARGET: VC <br>
 * NOTE : PR#534823 <br>
 * <br>
 * SETUP:<br>
 * 1.Create a vDS and add free pnic from host to it <br>
 * TEST:<br>>
 * 2.Add new uplink DVPG. <br>
 * 3.Add free pnic from same host to new uplink DVPG<br>
 * CLEANUP:<br>
 * 4. Destroy vDs<br>
 */
public class Pos057 extends TestBase
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
               + " 1.Create a vDS and add free  pnic from host  to it\n"
               + " 2.Add new  uplink DVPG.\n"
               + " 3.Add free pnic from same host  to new uplink DVPG \n");
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
               + " 1.Create a vDS and add free  pnic from host  to it\n"
               + " 2.Add new  uplink DVPG.\n"
               + " 3.Add free pnic from same host  to new uplink DVPG \n")
   public void test()
      throws Exception
   {
      ManagedObjectReference uplinkPortGroupMor = null;
      ManagedObjectReference defaultUplinkPortGroupMor = null;
      DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
      DVPortgroupPolicy policy = null;
      String uplinkPortKey = null;
      List<String> alUplink = new ArrayList<String>();
      defaultUplinkPortGroupMor = this.iDVS.getUplinkPortgroups(vDsMor).get(0);
      dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
      dvPortgroupConfigSpec.setConfigVersion(this.iDVPG.getConfigInfo(
               defaultUplinkPortGroupMor).getConfigVersion());
      policy = new DVPortgroupPolicy();
      policy.setLivePortMovingAllowed(true);
      dvPortgroupConfigSpec.setPolicy(policy);
      assertTrue((this.iDVPG.reconfigure(defaultUplinkPortGroupMor,
               dvPortgroupConfigSpec)),
               "Successfully reconfigured the portgroup",
               "Failed to reconfigure the portgroup");
      uplinkPortKey =
               this.iDVS.getFreePortInPortgroup(vDsMor, this.iDVPG
                        .getConfigInfo(defaultUplinkPortGroupMor).getKey(),
                        null);

      Map<String, List<String>> hmUplinks = new HashMap<String, List<String>>();
      uplinkPortGroupMor =
               DVSUtil.createUplinkPortGroup(connectAnchor, this.vDsMor, null,
                        1);
      /*
       * Move free port from default uplink DVPG
       */
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
      assertTrue(this.iDVS.movePort(vDsMor, new String[] { uplinkPortKey },
               this.iDVPG.getConfigInfo(uplinkPortGroupMor).getKey()),
               "Successfully moved given ports.", "Failed to move the ports.");
      alUplink.add(this.iDVPG.getConfigInfo(uplinkPortGroupMor).getKey());
      alUplink.add(uplinkPortKey);
      hmUplinks.put(freePnics[0], alUplink);
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
