/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
// I18N support added
package dvs.addportgroups;

import static com.vmware.vcqa.util.Assert.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSFailureCriteria;
import com.vmware.vc.DVSTrafficShapingPolicy;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.UserSession;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareDVSPortgroupPolicy;
import com.vmware.vc.VMwareUplinkPortOrderPolicy;
import com.vmware.vc.VmwareUplinkPortTeamingPolicy;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Add a portgroup to an existing distributed virtual switch with valid
 * uplinkTeamingPolicy (LBT-Dynamic Load Balancer in NIC Teaming)
 */
public class Pos077 extends TestBase
{
   /*
    * private data variables
    */
   private final UserSession loginSession = null;
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private ManagedObjectReference dcMor = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a portgroup to an existing distributed"
               + " virtual switch " + " with valid uplinkTeamingPolicy "
               + "(LBT-Dynamic Load Balancer in NIC Teaming)");
   }

   /**
    * Method to setup the environment for the test. This method creates a
    * distributed virtual switch.
    *
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      final boolean status = false;
      VMwareDVSPortSetting portSetting = null;
      DVSTrafficShapingPolicy inShapingPolicy = null;
      DVSTrafficShapingPolicy outShapingPolicy = null;
      VmwareUplinkPortTeamingPolicy uplinkTeamingPolicy = null;
      VMwareUplinkPortOrderPolicy portOrderPolicy = null;
      DVSFailureCriteria failureCriteria = null;
      VMwareDVSPortgroupPolicy portgroupPolicy = null;
      Map<String, Object> settingsMap = null;
      log.info("Test setup Begin:");
      iFolder = new Folder(connectAnchor);
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      iManagedEntity = new ManagedEntity(connectAnchor);
      dcMor = iFolder.getDataCenter();
      assertNotNull(dcMor, "Failed to find a datacenter");
      dvsConfigSpec = new DVSConfigSpec();
      dvsConfigSpec.setConfigVersion("");
      dvsConfigSpec.setName(this.getClass().getName() + "-dvs");
      dvsMor = iFolder.createDistributedVirtualSwitch(
               iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
      assertNotNull(dvsMor, "Failed to create a vds");
      dvPortgroupConfigSpecArray = new DVPortgroupConfigSpec[3];
      dvPortgroupConfigSpecArray[0] = new DVPortgroupConfigSpec();
      dvPortgroupConfigSpecArray[0].setConfigVersion("");
      dvPortgroupConfigSpecArray[0].setName(this.getClass().getName()
               + "-pg");
      dvPortgroupConfigSpecArray[0].setNumPorts(25);
      dvPortgroupConfigSpecArray[0].setType(DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING);
      dvPortgroupConfigSpecArray[0].getScope().clear();
      dvPortgroupConfigSpecArray[0].getScope().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new ManagedObjectReference[] { dcMor }));
      dvPortgroupConfigSpecArray[0].setPortNameFormat(DVSTestConstants.DVPORTGROUP_PORTNAMEFORMAT_PORTINDEX);
      settingsMap = new HashMap<String, Object>();
      settingsMap.put(DVSTestConstants.BLOCKED_KEY, false);
      inShapingPolicy = DVSUtil.getTrafficShapingPolicy(false, true, new Long(
               10), new Long(100), new Long(50));
      settingsMap.put(DVSTestConstants.INSHAPING_POLICY_KEY, inShapingPolicy);
      outShapingPolicy = DVSUtil.getTrafficShapingPolicy(false, true, new Long(
               10), new Long(100), new Long(50));
      settingsMap.put(DVSTestConstants.OUT_SHAPING_POLICY_KEY, outShapingPolicy);
      failureCriteria = DVSUtil.getFailureCriteria(false, "exact", 50, true,
               true, true, 10, true);
      portOrderPolicy = DVSUtil.getPortOrderPolicy(false, new String[] {
               "uplink1", "uplink2" }, new String[] { "uplink3", "uplink4" });
      uplinkTeamingPolicy = DVSUtil.getUplinkPortTeamingPolicy(false,
               "loadbalance_loadbased", true, true, true, failureCriteria,
               portOrderPolicy);
      settingsMap.put(DVSTestConstants.UPLINK_TEAMING_POLICY_KEY,
               uplinkTeamingPolicy);
      portSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
      portgroupPolicy = new VMwareDVSPortgroupPolicy();
      portgroupPolicy.setBlockOverrideAllowed(false);
      portgroupPolicy.setShapingOverrideAllowed(false);
      portgroupPolicy.setVendorConfigOverrideAllowed(true);
      portgroupPolicy.setLivePortMovingAllowed(true);
      portgroupPolicy.setPortConfigResetAtDisconnect(true);
      portgroupPolicy.setVlanOverrideAllowed(true);
      portgroupPolicy.setUplinkTeamingOverrideAllowed(true);
      portgroupPolicy.setSecurityPolicyOverrideAllowed(false);
      dvPortgroupConfigSpecArray[0].setPolicy(portgroupPolicy);
      dvPortgroupConfigSpecArray[0].setDefaultPortConfig(portSetting);
      /*
       * dvPortgroupConfigSpec for DVPORTGROUP_TYPE_EARLY_BINDING
       */
      dvPortgroupConfigSpecArray[1] = (DVPortgroupConfigSpec) TestUtil.deepCopyObject(dvPortgroupConfigSpecArray[0]);
      dvPortgroupConfigSpecArray[1].setName(this.getClass().getName()
               + "-pg2");
      dvPortgroupConfigSpecArray[1].setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
      /*
       * dvPortgroupConfigSpec for DVPORTGROUP_TYPE_EPHEMERAL
       */
      dvPortgroupConfigSpecArray[2] = (DVPortgroupConfigSpec) TestUtil.deepCopyObject(dvPortgroupConfigSpecArray[0]);
      dvPortgroupConfigSpecArray[2].setType(DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL);
      dvPortgroupConfigSpecArray[2].setName(this.getClass().getName()
               + "-pg3");
      return true;
   }

   /**
    * Method that adds a portgroup to the distributed virtual switch with
    * configVersion set to an empty string
    *
    * @param connectAnchor ConnectAnchor object
    * @throws Exception
    */
   @Override
   @Test(description = "Add a portgroup to an existing distributed"
            + " virtual switch " + " with valid uplinkTeamingPolicy "
            + "(LBT-Dynamic Load Balancer in NIC Teaming)")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      dvPortgroupMorList = iDVSwitch.addPortGroups(dvsMor,
               dvPortgroupConfigSpecArray);
      assertTrue(
               dvPortgroupMorList != null
                        && dvPortgroupMorList.size() == dvPortgroupConfigSpecArray.length,
               "Successfully added all the " + "portgroups",
               "Failed to add the portgroups");
   }

   /**
    * Method to restore the state as it was before the test is started. Destroy
    * the portgroup, followed by the distributed virtual switch
    *
    * @param connectAnchor ConnectAnchor object
    * @throws Exception
    */
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      assertTrue(iManagedEntity.destroy(dvsMor), "Successfully "
               + "destroyed the distributed virtual switch",
               "Failed to destroy " + "the distributed virtual switch");
      return true;
   }
}