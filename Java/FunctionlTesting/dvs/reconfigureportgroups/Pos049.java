/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigureportgroups;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSFailureCriteria;
import com.vmware.vc.DVSTrafficShapingPolicy;
import com.vmware.vc.HostNetworkTrafficShapingPolicy;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareDVSPortgroupPolicy;
import com.vmware.vc.VMwareUplinkPortOrderPolicy;
import com.vmware.vc.VmwareUplinkPortTeamingPolicy;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Reconfigure a portgroup to an existing distributed virtual switch all the
 * parameters set
 */
public class Pos049 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private VMwareDVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private ManagedObjectReference dvPortgroupMor = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private ManagedObjectReference dcMor = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Reconfigure a portgroup to an existing"
               + "distributed virtual switch");
   }

   /**
    * Method to setup the environment for the test. This method creates a
    * distributed virtual switch.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      VMwareDVSPortSetting portSetting = null;
      HostNetworkTrafficShapingPolicy inShapingPolicy = null;
      HostNetworkTrafficShapingPolicy outShapingPolicy = null;
      VmwareUplinkPortTeamingPolicy uplinkTeamingPolicy = null;
      VMwareUplinkPortOrderPolicy portOrderPolicy = null;
      DVSFailureCriteria failureCriteria = null;
      VMwareDVSPortgroupPolicy portgroupPolicy = null;
      log.info("Test setup Begin:");
      try {
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         this.rootFolderMor = this.iFolder.getRootFolder();
         this.dcMor = this.iFolder.getDataCenter();
         if (this.dcMor != null) {
            this.dvsConfigSpec = new VMwareDVSConfigSpec();
            this.dvsConfigSpec.setConfigVersion("");
            this.dvsConfigSpec.setName(this.getClass().getName());
            dvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
            if (dvsMor != null) {
               log.info("Successfully created the distributed "
                        + "virtual switch");
               this.dvPortgroupConfigSpecArray = new DVPortgroupConfigSpec[1];
               this.dvPortgroupConfigSpecArray[0] = new DVPortgroupConfigSpec();
               this.dvPortgroupConfigSpecArray[0].setConfigVersion("");
               this.dvPortgroupConfigSpecArray[0].setName(this.getTestId()
                        + "-1");
               this.dvPortgroupConfigSpecArray[0].setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
               this.dvPortgroupConfigSpecArray[0].setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
               this.dvPortgroupMorList = this.iDVSwitch.addPortGroups(dvsMor,
                        dvPortgroupConfigSpecArray);
               if (this.dvPortgroupMorList != null
                        && this.dvPortgroupMorList.size() == 1) {
                  log.info("Successfully added the portgroup");
                  status = true;
               } else {
                  log.error("Failed to add the portgroup");
               }
            } else {
               log.error("Failed to create the distributed "
                        + "virtual switch");
            }
         } else {
            log.error("Failed to find a datacenter");
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that reconfigures a portgroup in the distributed virtual switch
    * with all parameters set
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure a portgroup to an existing"
               + "distributed virtual switch")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      VMwareDVSPortSetting portSetting = null;
      DVSTrafficShapingPolicy inShapingPolicy = null;
      DVSTrafficShapingPolicy outShapingPolicy = null;
      VmwareUplinkPortTeamingPolicy uplinkTeamingPolicy = null;
      VMwareUplinkPortOrderPolicy portOrderPolicy = null;
      DVSFailureCriteria failureCriteria = null;
      VMwareDVSPortgroupPolicy portgroupPolicy = null;
      try {
         this.dvPortgroupConfigSpecArray[0].getScope().clear();
         this.dvPortgroupConfigSpecArray[0].getScope().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new ManagedObjectReference[] { this.dcMor }));
         this.dvPortgroupConfigSpecArray[0].setPortNameFormat(DVSTestConstants.DVPORTGROUP_PORTNAMEFORMAT_PORTINDEX);
         portSetting = (VMwareDVSPortSetting) this.iDVSwitch.getConfig(dvsMor).getDefaultPortConfig();
         portSetting.setBlocked(DVSUtil.getBoolPolicy(false, true));
         inShapingPolicy = portSetting.getInShapingPolicy();

         inShapingPolicy.setEnabled(DVSUtil.getBoolPolicy(false, true));
         inShapingPolicy.setAverageBandwidth(DVSUtil.getLongPolicy(false,
                  new Long(10)));
         inShapingPolicy.setBurstSize(DVSUtil.getLongPolicy(false, new Long(50)));
         inShapingPolicy.setPeakBandwidth(DVSUtil.getLongPolicy(false,
                  new Long(50)));
         portSetting.setInShapingPolicy(inShapingPolicy);
         outShapingPolicy = portSetting.getOutShapingPolicy();
         outShapingPolicy.setEnabled(DVSUtil.getBoolPolicy(false, true));
         outShapingPolicy.setAverageBandwidth(DVSUtil.getLongPolicy(false,
                  new Long(10)));
         outShapingPolicy.setBurstSize(DVSUtil.getLongPolicy(false,
                  new Long(50)));
         outShapingPolicy.setPeakBandwidth(DVSUtil.getLongPolicy(false,
                  new Long(50)));
         portSetting.setOutShapingPolicy(outShapingPolicy);
         uplinkTeamingPolicy = portSetting.getUplinkTeamingPolicy();
         uplinkTeamingPolicy.setNotifySwitches(DVSUtil.getBoolPolicy(false,
                  true));
         /*
          * TODO Need to push this into TestConstants
          */
         uplinkTeamingPolicy.setPolicy(DVSUtil.getStringPolicy(false,
                  "loadbalance_ip"));
         uplinkTeamingPolicy.setReversePolicy(DVSUtil.getBoolPolicy(false, true));
         uplinkTeamingPolicy.setRollingOrder(DVSUtil.getBoolPolicy(false, true));

         portOrderPolicy = new VMwareUplinkPortOrderPolicy();
         portOrderPolicy.getActiveUplinkPort().clear();
         portOrderPolicy.getActiveUplinkPort().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] { "uplink1",
                  "uplink2" }));
         portOrderPolicy.getStandbyUplinkPort().clear();
         portOrderPolicy.getStandbyUplinkPort().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] { "uplink3",
                  "uplink4" }));
         uplinkTeamingPolicy.setUplinkPortOrder(portOrderPolicy);

         failureCriteria = uplinkTeamingPolicy.getFailureCriteria();
         failureCriteria.setCheckBeacon(DVSUtil.getBoolPolicy(false, true));
         failureCriteria.setCheckDuplex(DVSUtil.getBoolPolicy(false, true));
         failureCriteria.setCheckErrorPercent(DVSUtil.getBoolPolicy(false, true));
         /*
          * TODO Need to push this into TestConstants
          */
         failureCriteria.setCheckSpeed(DVSUtil.getStringPolicy(false, "exact"));
         failureCriteria.setFullDuplex(DVSUtil.getBoolPolicy(false, true));
         failureCriteria.setPercentage(DVSUtil.getIntPolicy(false, new Integer(
                  10)));
         failureCriteria.setSpeed(DVSUtil.getIntPolicy(false, new Integer(50)));
         uplinkTeamingPolicy.setFailureCriteria(failureCriteria);
         portSetting.setUplinkTeamingPolicy(uplinkTeamingPolicy);
         portgroupPolicy = new VMwareDVSPortgroupPolicy();
         portgroupPolicy.setBlockOverrideAllowed(false);
         portgroupPolicy.setShapingOverrideAllowed(false);
         portgroupPolicy.setVendorConfigOverrideAllowed(true);
         portgroupPolicy.setLivePortMovingAllowed(true);
         portgroupPolicy.setPortConfigResetAtDisconnect(true);
         portgroupPolicy.setVlanOverrideAllowed(true);
         portgroupPolicy.setUplinkTeamingOverrideAllowed(true);
         portgroupPolicy.setSecurityPolicyOverrideAllowed(false);
         this.dvPortgroupConfigSpecArray[0].setPolicy(portgroupPolicy);
         this.dvPortgroupConfigSpecArray[0].setName(this.getTestId() + "-pg");
         this.dvPortgroupConfigSpecArray[0].setDefaultPortConfig(portSetting);
         this.dvPortgroupConfigSpecArray[0].setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
         this.dvPortgroupConfigSpecArray[0].setConfigVersion(this.iDVPortgroup.getConfigInfo(
                  dvPortgroupMorList.get(0)).getConfigVersion());
         if (this.iDVPortgroup.reconfigure(dvPortgroupMorList.get(0),
                  this.dvPortgroupConfigSpecArray[0])) {
            log.info("Successfully reconfigured the portgroup");
            status = true;
         } else {
            log.error("Failed to reconfigure the portgroup");
         }
      } catch (Exception e) {
         status = false;
         TestUtil.handleException(e);
      }
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started. Destroy
    * the portgroup, followed by the distributed virtual switch
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         if (this.dvPortgroupMorList != null) {
            for (ManagedObjectReference mor : dvPortgroupMorList) {
               status &= this.iManagedEntity.destroy(mor);
            }
         }
         if (this.dvsMor != null) {
            status &= this.iManagedEntity.destroy(dvsMor);
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
         status = false;
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
