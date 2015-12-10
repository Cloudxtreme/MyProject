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
 * (ReconfigureDVPG by setting numports to 2 ) <br>
 * TARGET: VC <br>
 * NOTE : PR#534823 <br>
 * <br>
 * SETUP:<br>
 * 1. Create a vDS and add free pnic from host to it<br>
 * TEST:<br>
 * 2.Add new uplink DVPG with 4 uplink ports<br>
 * 3.Move default uplinkports to new Uplink DVPG<BR>
 * 4.Change number of uplink ports to 4 in new uplink DVPG by invoking
 * ReconfigureDVPG api <br>
 * CLEANUP:<br>
 * 4. Destroy vDs<br>
 */
public class Pos061 extends TestBase
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
      super
               .setTestDescription("PR# 534823  : test case \n"
                        + " 1.Create a vDS and add free  pnic from host  to it\n"
                        + " 2.Add another uplink DVPG  with 4 uplink ports\n"
                        + "3.Move default uplinkports  to new Uplink DVPG\n"
                        + " 4. Change number of uplink ports to 4 in  new  uplink DVPG by invoking ReconfigureDVPG api");
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
      assertTrue((freePnics != null && freePnics.length >= 1),
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
                        + " 2.Add another uplink DVPG  with 4 uplink ports\n"
                        + "3.Move default uplinkports  to new Uplink DVPG\n"
                        + " 4. Change number of uplink ports to 4 in  new  uplink DVPG by invoking ReconfigureDVPG api")
   public void test()
      throws Exception
   {
      ManagedObjectReference uplinkPortGroupMor = null;
      ManagedObjectReference defaultUplinkPortGroupMor = null;
      DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
      DVPortgroupPolicy policy = null;
      List<String> uplinkDVportKeys = null;
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
      uplinkDVportKeys = this.iDVPG.getPortKeys(defaultUplinkPortGroupMor);
      uplinkPortGroupMor =
               DVSUtil.createUplinkPortGroup(connectAnchor, this.vDsMor, null,
                        4);
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
      dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
      dvPortgroupConfigSpec.setConfigVersion(this.iDVPG.getConfigInfo(
               uplinkPortGroupMor).getConfigVersion());
      dvPortgroupConfigSpec.setNumPorts(4);
      assertTrue((this.iDVPG.reconfigure(uplinkPortGroupMor,
               dvPortgroupConfigSpec)),
               "Successfully reconfigured the portgroup",
               "Failed to reconfigure the portgroup");
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
