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
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareDVSPortgroupPolicy;
import com.vmware.vc.VMwareUplinkPortOrderPolicy;
import com.vmware.vc.VmwareUplinkPortTeamingPolicy;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.i18n.I18NFactoryImpl;
import com.vmware.vcqa.i18n.I18NResourceKeyConstants;
import com.vmware.vcqa.i18n.ITestDataProvider;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Add a portgroup to an existing distributed virtual switch all the parameters
 * set
 */
public class Pos048 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private ManagedObjectReference dcMor = null;
   private ITestDataProvider iDataProvider = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a portgroup to an existing"
               + "distributed virtual switch");
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
      boolean status = false;
      VMwareDVSPortSetting portSetting = null;
      DVSTrafficShapingPolicy inShapingPolicy = null;
      DVSTrafficShapingPolicy outShapingPolicy = null;
      VmwareUplinkPortTeamingPolicy uplinkTeamingPolicy = null;
      VMwareUplinkPortOrderPolicy portOrderPolicy = null;
      DVSFailureCriteria failureCriteria = null;
      VMwareDVSPortgroupPolicy portgroupPolicy = null;
      Map<String, Object> settingsMap = null;
      log.info("Test setup Begin:");
      iDataProvider = I18NFactoryImpl.getITestDataProviderImpl();
      iFolder = new Folder(connectAnchor);
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      iManagedEntity = new ManagedEntity(connectAnchor);
      dcMor = iFolder.getDataCenter();
      if (dcMor != null) {
         dvsConfigSpec = new DVSConfigSpec();
         dvsConfigSpec.setConfigVersion("");
         dvsConfigSpec.setName(iDataProvider.getData(
                  I18NResourceKeyConstants.DVS_DVS_NAME_SUFFIX,
                  String.valueOf(TestUtil.getTime()), true));
         dvsMor = iFolder.createDistributedVirtualSwitch(
                  iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
         if (dvsMor != null) {
            log.info("Successfully created the distributed " + "virtual switch");
            dvPortgroupConfigSpecArray = new DVPortgroupConfigSpec[3];
            dvPortgroupConfigSpecArray[0] = new DVPortgroupConfigSpec();
            dvPortgroupConfigSpecArray[0].setConfigVersion("");
            dvPortgroupConfigSpecArray[0].setName(iDataProvider.getData(
                     I18NResourceKeyConstants.DVS_DVPORTGROUP_NAME_SUFFIX,
                     String.valueOf(TestUtil.getTime())));
            dvPortgroupConfigSpecArray[0].setDescription(iDataProvider.getData(I18NResourceKeyConstants.DVS_DVPORTGROUP_DESCRIPTION));
            dvPortgroupConfigSpecArray[0].setNumPorts(25);
            dvPortgroupConfigSpecArray[0].setType(DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING);
            dvPortgroupConfigSpecArray[0].getScope().clear();
            dvPortgroupConfigSpecArray[0].getScope().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new ManagedObjectReference[] { dcMor }));
            dvPortgroupConfigSpecArray[0].setPortNameFormat(DVSTestConstants.DVPORTGROUP_PORTNAMEFORMAT_PORTINDEX);
            settingsMap = new HashMap<String, Object>();
            settingsMap.put(DVSTestConstants.BLOCKED_KEY, false);
            inShapingPolicy = DVSUtil.getTrafficShapingPolicy(false, true,
                     new Long(10), new Long(100), new Long(50));
            settingsMap.put(DVSTestConstants.INSHAPING_POLICY_KEY,
                     inShapingPolicy);
            outShapingPolicy = DVSUtil.getTrafficShapingPolicy(false, true,
                     new Long(10), new Long(100), new Long(50));
            settingsMap.put(DVSTestConstants.OUT_SHAPING_POLICY_KEY,
                     outShapingPolicy);
            failureCriteria = DVSUtil.getFailureCriteria(false, "exact", 50,
                     true, true, true, 10, true);
            portOrderPolicy = DVSUtil.getPortOrderPolicy(false, new String[] {
                     "uplink1", "uplink2" }, new String[] { "uplink3",
                     "uplink4" });
            uplinkTeamingPolicy = DVSUtil.getUplinkPortTeamingPolicy(false,
                     "loadbalance_ip", true, true, true, failureCriteria,
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
            dvPortgroupConfigSpecArray[1].setName(iDataProvider.getData(
                     I18NResourceKeyConstants.DVS_DVPORTGROUP_NAME_SUFFIX,
                     String.valueOf(TestUtil.getTime() + 1)));
            dvPortgroupConfigSpecArray[1].setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
            /*
             * dvPortgroupConfigSpec for DVPORTGROUP_TYPE_EPHEMERAL
             */
            dvPortgroupConfigSpecArray[2] = (DVPortgroupConfigSpec) TestUtil.deepCopyObject(dvPortgroupConfigSpecArray[0]);
            dvPortgroupConfigSpecArray[2].setType(DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL);
            dvPortgroupConfigSpecArray[2].setName(iDataProvider.getData(
                     I18NResourceKeyConstants.DVS_DVPORTGROUP_NAME_SUFFIX,
                     String.valueOf(TestUtil.getTime() + 2)));
            status = true;
         } else {
            log.error("Failed to create the distributed " + "virtual switch");
         }
      } else {
         log.error("Failed to find a datacenter");
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that adds a portgroup to the distributed virtual switch with
    * configVersion set to an empty string
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "Add a portgroup to an existing"
            + "distributed virtual switch")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      dvPortgroupMorList = iDVSwitch.addPortGroups(dvsMor,
               dvPortgroupConfigSpecArray);
      if (dvPortgroupMorList != null) {
         if (dvPortgroupMorList.size() == dvPortgroupConfigSpecArray.length) {
            log.info("Successfully added all the portgroups");
            status = true;
         } else {
            log.error("Could not add all the portgroups");
         }
      } else {
         log.error("No portgroups were added");
      }
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started. Destroy
    * the portgroup, followed by the distributed virtual switch
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      if (dvPortgroupMorList != null) {
         for (final ManagedObjectReference mor : dvPortgroupMorList) {
            status &= iManagedEntity.destroy(mor);
         }
      }
      if (dvsMor != null) {
         status &= iManagedEntity.destroy(dvsMor);
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}