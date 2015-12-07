/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualPortgroupPortgroupType;
import com.vmware.vc.DistributedVirtualSwitchHostMember;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.host.HostSystemInformation;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure an existing DVS as follows: - Set the DVSConfigSpec.configVersion
 * to a valid config version string - set muliple portgroups previously added to
 * be the uplink portgoups.
 */
public class Pos067 extends CreateDVSTestBase
{

   /*
    * private data variables
    */
   private DistributedVirtualSwitch iDistributedVirtualSwitch = null;
   private DVSConfigSpec deltaConfigSpec = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpec = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure an existing DVS as follows:\n"
               + "  - Set the DVSConfigSpec.configVersion to a valid config version"
               + " string\n"
               + "  - Set muliple portgroups previously added to be the uplink portgroups");
   }

   /**
    * Method to setup the environment for the test.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      DVSConfigInfo dvsConfigInfo = null;
      DVPortgroupConfigSpec pgConfigSpecElement = null;
      List<ManagedObjectReference> dvPortgroupMorList = null;
      log.info("Test setup Begin:");
     
         if (super.testSetUp()) {
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               this.iDistributedVirtualSwitch = new DistributedVirtualSwitch(
                        connectAnchor);
               this.configSpec = new DVSConfigSpec();
               this.configSpec.setName(this.getClass().getName());
               this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                        this.networkFolderMor, this.configSpec);
               if (this.dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  dvsConfigInfo = this.iDistributedVirtualSwitch.getConfig(this.dvsMOR);
                  this.deltaConfigSpec = new DVSConfigSpec();
                  this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec[2];
                  for (int i = 0; i < this.dvPortgroupConfigSpec.length; i++) {
                     pgConfigSpecElement = new DVPortgroupConfigSpec();
                     pgConfigSpecElement.setName(this.getClass().getName()
                              + "-upg" + i);
                     pgConfigSpecElement.setType(DistributedVirtualPortgroupPortgroupType.EARLY_BINDING.value());
                     this.dvPortgroupConfigSpec[i] = pgConfigSpecElement;
                  }
                  dvPortgroupMorList = this.iDistributedVirtualSwitch.addPortGroups(
                           this.dvsMOR, this.dvPortgroupConfigSpec);
                  if (dvPortgroupMorList != null
                           && dvPortgroupMorList.size() == this.dvPortgroupConfigSpec.length) {
                     log.info("The portgroup was successfully"
                              + " added to the dvswitch");
                     this.deltaConfigSpec.setConfigVersion(this.iDistributedVirtualSwitch.getConfig(
                              this.dvsMOR).getConfigVersion());
                     dvPortgroupMorList.addAll(TestUtil.arrayToVector(com.vmware.vcqa.util.TestUtil.vectorToArray(dvsConfigInfo.getUplinkPortgroup(), com.vmware.vc.ManagedObjectReference.class)));
                     this.deltaConfigSpec.getUplinkPortgroup().clear();
                     this.deltaConfigSpec.getUplinkPortgroup().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(dvPortgroupMorList.toArray(new ManagedObjectReference[dvPortgroupMorList.size()])));
                     status = true;
                  } else {
                     log.error("Failed to add the portgroup to the"
                              + " dvswitch");
                  }
               } else {
                  log.error("Cannot create the distributed virtual "
                           + "switch with the config spec passed");
               }
            } else {
               log.error("Failed to create the network folder");
            }
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure an existing DVS as follows:\n"
               + "  - Set the DVSConfigSpec.configVersion to a valid config version"
               + " string\n"
               + "  - Set muliple portgroups previously added to be the uplink portgroups")
   public void test()
      throws Exception
   {

      log.info("Test Begin:");
      boolean status = false;
      DVSConfigSpec dvsConfigSpec = null;
      DVSConfigInfo dvsConfigInfo = null;
      ManagedObjectReference hostMor = null;
      Map<ManagedObjectReference, HostSystemInformation> allHosts = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostMemberConfigSpec = null;
      DistributedVirtualSwitchHostMemberPnicBacking currentPnicBacking = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
      DistributedVirtualSwitchHostMember[] hostMembers = null;
      String currentPortgroup = null;
      String newPortgroup = null;
      String[] freePnics = null;
     
         if (this.iDistributedVirtualSwitch.reconfigure(this.dvsMOR,
                  this.deltaConfigSpec)) {
            log.info("Successfully reconfigured DVS");
            dvsConfigInfo = this.iDistributedVirtualSwitch.getConfig(this.dvsMOR);
            dvsConfigSpec = new DVSConfigSpec();
            dvsConfigSpec.setConfigVersion(dvsConfigInfo.getConfigVersion());
            allHosts = this.ihs.getAllHosts(VersionConstants.ESX4x, HostSystemConnectionState.CONNECTED);
            if (allHosts != null && allHosts.keySet() != null
                     && allHosts.keySet().size() > 0) {
               hostMor = allHosts.keySet().iterator().next();
               if (hostMor != null) {
                  freePnics = this.ins.getPNicIds(hostMor);
                  if (freePnics != null && freePnics.length > 0
                           && freePnics[0] != null) {
                     pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                     pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                     pnicSpec.setPnicDevice(freePnics[0]);
                     pnicBacking.getPnicSpec().clear();
                     pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
                     hostMemberConfigSpec = new DistributedVirtualSwitchHostMemberConfigSpec();
                     hostMemberConfigSpec.setOperation(TestConstants.CONFIG_SPEC_ADD);
                     hostMemberConfigSpec.setHost(hostMor);
                     hostMemberConfigSpec.setBacking(pnicBacking);
                     dvsConfigSpec.getHost().clear();
                     dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMemberConfigSpec }));
                     if (this.iDistributedVirtualSwitch.reconfigure(
                              this.dvsMOR, dvsConfigSpec)) {
                        dvsConfigInfo = this.iDistributedVirtualSwitch.getConfig(this.dvsMOR);
                        hostMembers = com.vmware.vcqa.util.TestUtil.vectorToArray(dvsConfigInfo.getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class);
                        if (hostMembers != null
                                 && hostMembers[0] != null
                                 && hostMembers[0].getConfig() != null
                                 && hostMembers[0].getConfig().getBacking() != null
                                 && hostMembers[0].getConfig().getBacking() instanceof DistributedVirtualSwitchHostMemberPnicBacking) {
                           currentPnicBacking = (DistributedVirtualSwitchHostMemberPnicBacking) hostMembers[0].getConfig().getBacking();
                           currentPortgroup = com.vmware.vcqa.util.TestUtil.vectorToArray(currentPnicBacking.getPnicSpec(), com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec.class)[0].getUplinkPortgroupKey();
                           Assert.assertNotNull(currentPortgroup,
                                    "The current uplink portgroup is null");
                           for (ManagedObjectReference uplinkPgMor : com.vmware.vcqa.util.TestUtil.vectorToArray(dvsConfigInfo.getUplinkPortgroup(), com.vmware.vc.ManagedObjectReference.class)) {
                              if (!this.idvpg.getKey(uplinkPgMor).equals(
                                       currentPortgroup)) {
                                 newPortgroup = this.idvpg.getKey(uplinkPgMor);
                                 break;
                              }
                           }
                           Assert.assertNotNull(newPortgroup,
                                    "The uplink porgroup is null");
                           hostMemberConfigSpec.setOperation(TestConstants.CONFIG_SPEC_EDIT);
                           pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                           pnicBacking.getPnicSpec().clear();
                           pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
                           hostMemberConfigSpec.setBacking(pnicBacking);
                           dvsConfigSpec.setConfigVersion(dvsConfigInfo.getConfigVersion());
                           dvsConfigSpec.getHost().clear();
                           dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMemberConfigSpec }));
                           if (this.iDistributedVirtualSwitch.reconfigure(
                                    this.dvsMOR, dvsConfigSpec)) {
                              dvsConfigInfo = this.iDistributedVirtualSwitch.getConfig(this.dvsMOR);
                              dvsConfigSpec.setConfigVersion(dvsConfigInfo.getConfigVersion());
                              pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                              pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                              pnicSpec.setUplinkPortgroupKey(newPortgroup);
                              pnicSpec.setPnicDevice(freePnics[0]);
                              pnicBacking.getPnicSpec().clear();
                              pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
                              hostMemberConfigSpec.setBacking(pnicBacking);
                              dvsConfigSpec.getHost().clear();
                              dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMemberConfigSpec }));
                              if (this.iDistributedVirtualSwitch.reconfigure(
                                       this.dvsMOR, dvsConfigSpec)) {
                                 status = true;
                              }
                           }
                        } else {
                           log.error("The host member backing is incorrect");
                        }
                     } else {
                        log.error("Cannot reconfigure the DVS");
                     }
                  }
               } else {
                  log.error("The hsot mor is null");
               }
            } else {
               log.error("Cannot obtain a valid host in the setup");
            }
         } else {
            log.error("Failed to reconfigure dvs");
         }
     
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
     
         status &= super.testCleanUp();
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}