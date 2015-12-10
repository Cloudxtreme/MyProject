/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareUplinkPortOrderPolicy;
import com.vmware.vc.VmwareUplinkPortTeamingPolicy;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

import dvs.CreateDVSTestBase;

/**
 * Create a DVSwitch inside a valid folder with the following configuration:
 * configVersion - empty string name - "Create DVS-Pos060" numPort - valid
 * number maxPort - valid number For DVPortSetting: blocked - false
 * uplinkTeamingPolicy.notifySwitches - false uplinkTeamingPolicy.reversePolicy
 * - false uplinkTeamingPolicy.rollingOrder - false
 * uplinkTeamingPolicy.uplinkPortOrder.standbyUplinkPort - valid array
 * containing valid uplink port names
 */

public class Pos061 extends CreateDVSTestBase
{
   private HostSystem ihs = null;
   private NetworkSystem iNetworkSystem = null;
   private ManagedObjectReference hostMor = null;
   private Vector<ManagedObjectReference> allHosts = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Create a DVSwitch inside a valid folder with"
               + "the following configuration:\n "
               + "configVersion - empty string\n"
               + "name - 'Create DVS-Pos060'\n " + "numPort - valid number\n"
               + "maxPort - valid number\n" + "For DVPortSetting:\n"
               + "blocked - false\n"
               + "uplinkTeamingPolicy.notifySwitches - false\n "
               + "uplinkTeamingPolicy.reversePolicy - false\n"
               + "uplinkTeamingPolicy.rollingOrder - false\n"
               + "uplinkTeamingPolicy.uplinkPortOrder.standbyUplinkPort - "
               + "valid array containing valid uplink port names.\n");
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
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostMember = null;
      DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new DVSNameArrayUplinkPortPolicy();
      String[] uplinkPortNames = null;
      VMwareDVSPortSetting dvPort = new VMwareDVSPortSetting();
      log.info("Test setup Begin:");
     
         if (super.testSetUp()) {
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               this.ihs = new HostSystem(connectAnchor);
               this.iNetworkSystem = new NetworkSystem(connectAnchor);
               allHosts = this.ihs.getAllHost();
               if (allHosts != null) {
                  this.hostMor = (ManagedObjectReference) allHosts.get(0);
                  if (this.hostMor != null
                           && this.ihs.isHostConnected(this.hostMor)) {
                     log.info("Using the host "
                              + this.ihs.getHostName(this.hostMor));
                     VmwareUplinkPortTeamingPolicy portTeamingPolicy = new VmwareUplinkPortTeamingPolicy();
                     VMwareUplinkPortOrderPolicy portOrderPolicy = new VMwareUplinkPortOrderPolicy();
                     this.configSpec = new DVSConfigSpec();
                     this.configSpec.setConfigVersion("");
                     this.configSpec.setName(getTestId());
                     this.configSpec.setMaxPorts(5);
                     this.configSpec.setNumStandalonePorts(4);
                     String[] physicalNics = iNetworkSystem.getPNicIds(hostMor);
                     if (physicalNics != null) {
                        pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                        pnicSpec.setPnicDevice(physicalNics[0]);
                        pnicSpec.setUplinkPortKey(null);
                        uplinkPortNames = new String[1];
                        for (int i = 0; i < uplinkPortNames.length; i++) {
                           uplinkPortNames[i] = "uplink" + i;
                        }
                        pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                        pnicBacking.getPnicSpec().clear();
                        pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
                        hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
                        hostMember.setOperation(TestConstants.CONFIG_SPEC_ADD);
                        hostMember.setBacking(pnicBacking);
                        hostMember.setHost(this.hostMor);
                        this.configSpec.getHost().clear();
                        this.configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMember }));
                        uplinkPolicyInst.getUplinkPortName().clear();
                        uplinkPolicyInst.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
                        this.configSpec.setUplinkPortPolicy(uplinkPolicyInst);
                        dvPort.setBlocked(DVSUtil.getBoolPolicy(false, false));
                        portTeamingPolicy.setNotifySwitches(DVSUtil.getBoolPolicy(
                                 false, false));
                        portTeamingPolicy.setReversePolicy(DVSUtil.getBoolPolicy(
                                 false, false));
                        portTeamingPolicy.setRollingOrder(DVSUtil.getBoolPolicy(
                                 false, false));
                        portOrderPolicy.setInherited(false);
                        portOrderPolicy.getStandbyUplinkPort().clear();
                        portOrderPolicy.getStandbyUplinkPort().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] { "uplink0" }));
                        portOrderPolicy.getActiveUplinkPort().clear();
                        portOrderPolicy.getActiveUplinkPort().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] {}));
                        portTeamingPolicy.setUplinkPortOrder(portOrderPolicy);
                        dvPort.setUplinkTeamingPolicy(portTeamingPolicy);
                        this.configSpec.setDefaultPortConfig(dvPort);
                        status = true;
                     } else {
                        log.info("No physical nics found on the host");
                     }
                  }
               } else {
                  log.error("Valid Host MOR not found");
               }

            } else {
               log.error("Failed to create the network folder");
            }
         } else {
            log.error("Failed to login");
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Create a DVSwitch inside a valid folder with"
               + "the following configuration:\n "
               + "configVersion - empty string\n"
               + "name - 'Create DVS-Pos060'\n " + "numPort - valid number\n"
               + "maxPort - valid number\n" + "For DVPortSetting:\n"
               + "blocked - false\n"
               + "uplinkTeamingPolicy.notifySwitches - false\n "
               + "uplinkTeamingPolicy.reversePolicy - false\n"
               + "uplinkTeamingPolicy.rollingOrder - false\n"
               + "uplinkTeamingPolicy.uplinkPortOrder.standbyUplinkPort - "
               + "valid array containing valid uplink port names.\n")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         if (this.configSpec != null) {
            this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                     this.networkFolderMor, this.configSpec);
            if (this.dvsMOR != null) {
               log.info("Successfully created the DVSwitch");
               if (iDistributedVirtualSwitch.validateDVSConfigSpec(this.dvsMOR,
                        this.configSpec, null)) {
                  status = true;
               } else {
                  log.info("The config spec of the Distributed Virtual Switch"
                           + "is not created as per specifications");
               }
            } else {
               log.error("Cannot create the distributed "
                        + "virtual switch with the config spec passed");
            }
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
      boolean status = false;
     
         status = super.testCleanUp();
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}