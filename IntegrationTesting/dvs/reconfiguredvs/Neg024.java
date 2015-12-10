/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.ResourceInUse;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure an existing DVSwitch by setting the ManagedObjectReference to a
 * valid DVSwitch Mor and DVSConfigSpec.configVersion to a valid config version
 * string and uplinkPortgroup to an invalid array.
 */

public class Neg024 extends CreateDVSTestBase
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitch iDistributedVirtualSwitch = null;
   private DVSConfigSpec deltaConfigSpec = null;
   private HostSystem ihs = null;
   private Vector<ManagedObjectReference> allHosts = null;
   private ManagedObjectReference hostMor = null;
   private HostNetworkConfig[] preSetupNetworkConfig = null;
   private ManagedObjectReference iNetworkMor = null;
   private NetworkSystem iNetworkSystem = null;
   private Map<String, List<String>> usedPorts = null;
   private VirtualMachine iVirtualMachine = null;
   private VirtualMachineConfigSpec[] vmDeltaConfigSpec = null;
   private ManagedObjectReference vmMor = null;
   private VirtualMachinePowerState vmPowerState = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure an existing DVSwitch by setting "
               + "the ManagedObjectReference to a valid DVSwitch Mor and "
               + "DVSConfigSpec.configVersion to a valid config version string and "
               + "uplinkPortgroup to an invalid array.");
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
      DistributedVirtualSwitchPortConnection portConnection = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
      log.info("Test setup Begin:");
     
         if (super.testSetUp()) {
            this.ihs = new HostSystem(connectAnchor);
            this.iNetworkSystem = new NetworkSystem(connectAnchor);
            allHosts = this.ihs.getAllHost();
            if (allHosts != null) {
               this.hostMor = (ManagedObjectReference) allHosts.get(0);
            } else {
               log.error("Valid Host MOR not found");
            }
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            this.iNetworkMor = this.iNetworkSystem.getNetworkSystem(this.hostMor);
            if (this.networkFolderMor != null) {
               this.iDistributedVirtualSwitch = new DistributedVirtualSwitch(
                        connectAnchor);
               this.iVirtualMachine = new VirtualMachine(connectAnchor);
               this.configSpec = new DVSConfigSpec();
               this.configSpec.setName(this.getClass().getName());
               this.configSpec.setNumStandalonePorts(1);
               hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
               hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
               hostConfigSpecElement.setHost(this.hostMor);
               this.configSpec.getHost().clear();
               this.configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
               this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                        this.networkFolderMor, this.configSpec);
               if (this.dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  Thread.sleep(10000);
                  preSetupNetworkConfig = iDistributedVirtualSwitch.getHostNetworkConfigMigrateToDVS(
                           this.dvsMOR, hostMor);
                  this.iNetworkSystem.refresh(this.iNetworkMor);
                  Thread.sleep(10000);
                  if (this.iNetworkMor != null) {
                     iNetworkSystem.updateNetworkConfig(iNetworkMor,
                              preSetupNetworkConfig[0],
                              TestConstants.CHANGEMODE_MODIFY);
                     usedPorts = new HashMap<String, List<String>>();
                     portConnection = this.iDistributedVirtualSwitch.getPortConnection(
                              this.dvsMOR, null, false, usedPorts);
                     /*
                      * Connect a VM virtual NIC to a port
                      * in the source dvswitch
                      */
                     Vector<ManagedObjectReference> allVMs = this.ihs.getVMs(
                              this.hostMor, null);
                     /*
                      * Get the first VM in the list of VMs.
                      */
                     if (allVMs != null) {
                        this.vmMor = (ManagedObjectReference) allVMs.get(0);
                     }
                     if (this.vmMor != null) {
                        this.vmPowerState = this.iVirtualMachine.getVMState(this.vmMor);
                        if (!(this.vmPowerState.equals(VirtualMachinePowerState.POWERED_OFF))) {
                           if (this.iVirtualMachine.powerOffVM(this.vmMor)) {
                              log.info("Successfully powered off "
                                       + "the virtual machine");
                           } else {
                              log.error("Could not power off the "
                                       + "virtual machine");
                           }
                        }
                     } else {
                        log.error("Cannot find a VM");
                     }
                     if (portConnection != null) {
                        this.vmDeltaConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                                 this.vmMor,
                                 connectAnchor,
                                 new DistributedVirtualSwitchPortConnection[] { portConnection });
                        if (this.vmDeltaConfigSpec != null) {
                           if (this.iVirtualMachine.reconfigVM(this.vmMor,
                                    this.vmDeltaConfigSpec[0])) {
                              log.info("Successfully reconfigured"
                                       + " the VM to connect to the" + " port");
                              if (this.iVirtualMachine.setVMState(vmMor, VirtualMachinePowerState.POWERED_ON, false)) {
                                 log.info("Successfully powered"
                                          + " on the VM");
                                 this.deltaConfigSpec = new DVSConfigSpec();
                                 this.deltaConfigSpec.setConfigVersion(this.iDistributedVirtualSwitch.getConfig(
                                          this.dvsMOR).getConfigVersion());
                                 hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_REMOVE);
                                 this.deltaConfigSpec.getHost().clear();
                                 this.deltaConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
                                 status = true;
                              } else {
                                 log.error("Failed to power on "
                                          + "the VM");
                              }
                           } else {
                              log.error("Failed to reconfigure "
                                       + "the VM to connect to " + "a port");
                           }
                        }
                     } else {
                        log.error("Failed to obtain a dvs port "
                                 + "connection");
                     }
                  } else {
                     log.error("Cannot find the network MOR");
                  }
               } else {
                  log.error("Cannot create the distributed virtual "
                           + "switch with the config spec passed");
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
   @Test(description = "Reconfigure an existing DVSwitch by setting "
               + "the ManagedObjectReference to a valid DVSwitch Mor and "
               + "DVSConfigSpec.configVersion to a valid config version string and "
               + "uplinkPortgroup to an invalid array.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      try {
         this.iDistributedVirtualSwitch.reconfigure(this.dvsMOR,
                  this.deltaConfigSpec);
         log.error("The API did not throw Exception");
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         MethodFault expectedMethodFault = new ResourceInUse();
         status = TestUtil.checkMethodFault(actualMethodFault,
                  expectedMethodFault);
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
      try {
         if (this.vmMor != null) {
            /*
             * Restore the original configuration of the virtual machine
             */
            if (this.vmDeltaConfigSpec != null
                     && this.vmDeltaConfigSpec.length >= 2
                     && this.vmDeltaConfigSpec[1] != null) {
               status &= this.iVirtualMachine.reconfigVM(this.vmMor,
                        vmDeltaConfigSpec[1]);
            }

            if (this.vmPowerState != null) {
               /*
                * Restore the original power state of the VM
                */
               status &= this.iVirtualMachine.setVMState(this.vmMor,
                        this.vmPowerState, false);
            }
         }
         /*
          * Restore the original network configuration of the host
          */
         if (this.preSetupNetworkConfig != null
                  && this.preSetupNetworkConfig.length == 2
                  && this.preSetupNetworkConfig[1] != null) {
            log.info("Restoring the original network config on the host");
            status &= this.iNetworkSystem.updateNetworkConfig(this.iNetworkMor,
                     this.preSetupNetworkConfig[1],
                     TestConstants.CHANGEMODE_MODIFY);
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
         status = false;
      } finally {
         status &= super.testCleanUp();
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}