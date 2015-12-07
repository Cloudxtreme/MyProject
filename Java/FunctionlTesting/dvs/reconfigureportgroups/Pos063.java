/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigureportgroups;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareDVSPortgroupPolicy;
import com.vmware.vc.VmwareUplinkPortTeamingPolicy;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Reconfigure an early binding portgroup to an existing distributed virtual
 * switch with valid uplinkTeamingPolicy (Set the teaming policy as LBT-Dynamic
 * Load Balancer in NIC Teaming
 */
public class Pos063 extends TestBase
{
   /*
    * private data variables
    */
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private VMwareDVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private ManagedObjectReference dcMor = null;
   private VMwareDVSPortSetting dvsPortSetting = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Reconfigure an early binding portgroup to an "
               + "existing distributed virtual"
               + " switch with valid uplinkTeamingPolicy (Set the teaming"
               + " policy as LBT-Dynamic Load Balancer in NIC Teaming ");
   }

   /**
    * Method to setup the environment for the test
    * 
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    * @throws Exception
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      String pgName = getTestId() + "-pg1";
      final String dvsName = super.getTestId();
      log.info("Test setup Begin:");
      this.iFolder = new Folder(connectAnchor);
      this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      this.dcMor = this.iFolder.getDataCenter();
      assertNotNull(this.dcMor, "Unable to find datacenter ");
      this.dvsConfigSpec = new VMwareDVSConfigSpec();
      this.dvsConfigSpec.setConfigVersion("");
      this.dvsConfigSpec.setName(dvsName);
      this.dvsConfigSpec.setNumStandalonePorts(9);
      dvsMor = this.iFolder.createDistributedVirtualSwitch(
               this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);

      assertNotNull(dvsMor, "Successfully created the DVS " + dvsName,
               "Can not create the DVS " + dvsName);
      this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
      this.dvPortgroupConfigSpec.setConfigVersion("");
      this.dvPortgroupConfigSpec.setName(pgName);
      this.dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
      this.dvPortgroupConfigSpec.setNumPorts(1);
      this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
      this.dvPortgroupMorList = this.iDVSwitch.addPortGroups(dvsMor,
               new DVPortgroupConfigSpec[] { this.dvPortgroupConfigSpec });
      assertTrue(
               (this.dvPortgroupMorList != null && this.dvPortgroupMorList.size() == 1),
               "Successfully added the early binding "
                        + "portgroup to the DVS " + pgName,
               "Unable to add the early binding " + "portgroup to the DVS :  "
                        + pgName);
      return true;
   }

   /**
    * Method that reconfigures a portgroup
    * 
    * @param connectAnchor ConnectAnchor object
    * @throws Exception
    */
   @Override
   @Test(description = "Reconfigure an early binding portgroup to an "
               + "existing distributed virtual"
               + " switch with valid uplinkTeamingPolicy (Set the teaming"
               + " policy as LBT-Dynamic Load Balancer in NIC Teaming ")
   public void test()
      throws Exception
   {
      VmwareUplinkPortTeamingPolicy portgroupUplinkTeamingPolicy = null;
      VMwareDVSPortgroupPolicy portgroupPolicy = null;
      Map<String, Object> settingsMap = null;
      portgroupPolicy = new VMwareDVSPortgroupPolicy();
      portgroupUplinkTeamingPolicy = DVSUtil.getUplinkPortTeamingPolicy(false,
               "loadbalance_loadbased", null, true, null, null, null);
      portgroupPolicy.setUplinkTeamingOverrideAllowed(true);
      settingsMap = new HashMap<String, Object>();
      settingsMap.put(DVSTestConstants.UPLINK_TEAMING_POLICY_KEY,
               portgroupUplinkTeamingPolicy);
      this.dvPortgroupConfigSpec.setDefaultPortConfig(DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap));
      this.dvPortgroupConfigSpec.setPolicy(portgroupPolicy);
      this.dvPortgroupConfigSpec.setConfigVersion(this.iDVPortgroup.getConfigInfo(
               dvPortgroupMorList.get(0)).getConfigVersion());
      assertTrue((this.iDVPortgroup.reconfigure(dvPortgroupMorList.get(0),
               this.dvPortgroupConfigSpec)),
               "Successfully reconfigured the portgroup",
               "Failed to reconfigure the portgroup");

   }

   /**
    * Method to restore the state as it was before the test was started.
    * 
    * @param connectAnchor ConnectAnchor object
    * @throws Exception
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      /*
       * Cleanup dvs
       */
      assertTrue(this.iDVSwitch.destroy(dvsMor), "Successfully deleted DVS",
               "Unable to delete DVS");
      return true;
   }
}
