/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostNetworkInfo;
import com.vmware.vc.HostNetworkTrafficShapingPolicy;
import com.vmware.vc.HostNicFailureCriteria;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareDVSPortgroupPolicy;
import com.vmware.vc.VMwareUplinkPortOrderPolicy;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vc.VmwareUplinkPortTeamingPolicy;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * Add a earlyBinding portgroup to an existing distributed virtual switch with
 * scope set to VMFolder mor
 */
public class Pos018 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private ManagedObjectReference dcMor = null;
   private ManagedObjectReference hostMor = null;
   private HostSystem iHostSystem = null;
   private DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
   private HostNetworkConfig[] hostNetworkConfig = null;
   private ManagedObjectReference nsMor = null;
   private NetworkSystem iNetworkSystem = null;
   private Vector allVMs = null;
   private ManagedObjectReference vmMor = null;
   private VirtualMachinePowerState vmPowerState = null;
   private VirtualMachine iVirtualMachine = null;
   private String portgroupKey = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private VirtualMachineConfigSpec[] vmDeltaConfigSpec = null;
   private ManagedObjectReference folderMor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Add a earlyBinding portgroup to an existing"
               + "distributed virtual switch with scope set to "
               + "VMFolder mor");
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
      HostNicFailureCriteria failureCriteria = null;
      VMwareDVSPortgroupPolicy portgroupPolicy = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      log.info("Test setup Begin:");
     
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.iHostSystem = new HostSystem(connectAnchor);
         this.rootFolderMor = this.iFolder.getRootFolder();
         this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         this.iNetworkSystem = new NetworkSystem(connectAnchor);
         this.iVirtualMachine = new VirtualMachine(connectAnchor);
         ;
         /*
          * Get a standalone host of version 4.0
          */
         this.hostMor = this.iHostSystem.getAllHost().get(0);
         this.dcMor = this.iFolder.getDataCenter();
         this.folderMor = this.iFolder.getVMFolder(dcMor);
         if (this.dcMor != null && this.hostMor != null
                  && this.folderMor != null) {
            this.dvsConfigSpec = new DVSConfigSpec();
            this.dvsConfigSpec.setConfigVersion("");
            this.dvsConfigSpec.setName(this.getClass().getName());
            hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
            hostConfigSpecElement.setHost(hostMor);
            hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
            /*
             * TODO Check whether the pnic devices need to be
             * set in the DistributedVirtualSwitchHostMemberPnicSpec
             */
            pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
            pnicBacking.getPnicSpec().clear();
            pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
            hostConfigSpecElement.setBacking(pnicBacking);
            this.dvsConfigSpec.getHost().clear();
            this.dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
            dvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
            if (dvsMor != null) {
               log.info("Successfully created the distributed "
                        + "virtual switch");
               hostNetworkConfig = this.iDVSwitch.getHostNetworkConfigMigrateToDVS(
                        this.dvsMor, this.hostMor);
               this.nsMor = this.iNetworkSystem.getNetworkSystem(hostMor);
               if (nsMor != null) {
                  this.iNetworkSystem.refresh(this.nsMor);
                  Thread.sleep(10000);
                  this.iNetworkSystem.updateNetworkConfig(nsMor,
                           hostNetworkConfig[0],
                           TestConstants.CHANGEMODE_MODIFY);
                  allVMs = this.iHostSystem.getVMs(hostMor, null);
                  /*
                   * Get the first VM in the list of VMs.
                   */
                  if (allVMs != null) {
                     this.vmMor = (ManagedObjectReference) allVMs.get(0);
                  }
                  if (this.vmMor != null) {
                     this.vmPowerState = this.iVirtualMachine.getVMState(vmMor);
                     if (this.iVirtualMachine.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false)) {
                        log.info("Successfully powered off the"
                                 + " virtual machine");
                        this.dvPortgroupConfigSpecArray = new DVPortgroupConfigSpec[1];
                        this.dvPortgroupConfigSpecArray[0] = new DVPortgroupConfigSpec();
                        this.dvPortgroupConfigSpecArray[0].setConfigVersion("");
                        this.dvPortgroupConfigSpecArray[0].setName(this.getTestId()
                                 + "-1");
                        this.dvPortgroupConfigSpecArray[0].setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
                        this.dvPortgroupConfigSpecArray[0].setNumPorts(8);
                        this.dvPortgroupConfigSpecArray[0].setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
                        this.dvPortgroupConfigSpecArray[0].setPortNameFormat(DVSTestConstants.DVPORTGROUP_PORTNAMEFORMAT_PORTINDEX);
                        this.dvPortgroupConfigSpecArray[0].getScope().clear();
                        this.dvPortgroupConfigSpecArray[0].getScope().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new ManagedObjectReference[] { this.folderMor }));
                        status = true;
                     } else {
                        log.error("Failed to power off the virtual "
                                 + "machine");
                     }
                  }
               } else {
                  log.error("Could not find the network system " + "MOR");
               }

            } else {
               log.error("Failed to create the distributed "
                        + "virtual switch");
            }
         } else {
            log.error("Failed to find a datacenter");
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that reconfigures a portgroup with scope set to datacenter mor
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Add a earlyBinding portgroup to an existing"
               + "distributed virtual switch with scope set to "
               + "VMFolder mor")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      String portKey = null;
      Map<String, List<String>> excludedPorts = null;
      HostNetworkInfo networkInfo = null;
      HostVirtualNicSpec hostVnicSpec = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      String device = null;
     

         this.dvPortgroupMorList = this.iDVSwitch.addPortGroups(dvsMor,
                  dvPortgroupConfigSpecArray);
         if (this.dvPortgroupMorList != null
                  && this.dvPortgroupMorList.size() == 1) {
            log.info("Successfully added the " + "portgroup");
            /*
             * Connect a virtual machine vnic to the portgroup
             */
            portgroupKey = this.iDVPortgroup.getKey(dvPortgroupMorList.get(0));
            portKey = this.iDVSwitch.getFreePortInPortgroup(dvsMor,
                     portgroupKey, excludedPorts);
            portConnection = new DistributedVirtualSwitchPortConnection();
            portConnection.setPortgroupKey(portgroupKey);
            portConnection.setSwitchUuid(this.iDVSwitch.getConfig(dvsMor).getUuid());
            vmDeltaConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                     vmMor,
                     connectAnchor,
                     new DistributedVirtualSwitchPortConnection[] { portConnection });
            if (vmDeltaConfigSpec != null) {
               log.info("Successfully obtained the VM config " + "specs");
               if (this.iVirtualMachine.reconfigVM(vmMor, vmDeltaConfigSpec[0])) {
                  log.info("Successfully "
                           + "reconfigured the VM to connect " + "to the port");
                  if (this.iVirtualMachine.setVMState(vmMor, VirtualMachinePowerState.POWERED_ON, true)) {
                     log.info("Successfully powered on the VM");
                     status = DVSUtil.checkNetworkConnectivity(
                              this.iHostSystem.getIPAddress(hostMor),
                              this.iVirtualMachine.getIPAddress(vmMor));
                  } else {
                     log.error("Failed to power on the VM");
                  }
               } else {
                  status = false;
                  log.error("Failed to " + "reconfigure the VM to "
                           + "connect to a port");
               }
            } else {
               log.error("Failed to obtain the VM config specs");
               status = false;
            }
         } else {
            log.error("Failed to add the portgroup");
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
         /*
          * Restore the virtual machine's original config spec
          */
         status &= this.iVirtualMachine.reconfigVM(vmMor, vmDeltaConfigSpec[1]);
         /*
          * Restore the original network config
          */
         status &= this.iNetworkSystem.updateNetworkConfig(this.nsMor,
                  hostNetworkConfig[1], TestConstants.CHANGEMODE_MODIFY);

         /*
          * Destroy the added portgroup
          */
         status &= this.iManagedEntity.destroy(dvPortgroupMorList.get(0));
         /*
          * Restore the original power state of the virtual machine
          */
         status &= this.iVirtualMachine.setVMState(vmMor, this.vmPowerState,
                  false);
      } catch (Exception e) {
         TestUtil.handleException(e);
         status = false;
      } finally {
         try {
            if (this.dvsMor != null) {
               status &= this.iManagedEntity.destroy(dvsMor);
            }
         } catch (Exception ex) {
            TestUtil.handleException(ex);
            status = false;
         }
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
