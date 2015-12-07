/*
 * ************************************************************************
 *
 * Copyright 2008-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigureportgroups;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;
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
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.ResourceInUse;
import com.vmware.vc.VirtualDevice;
import com.vmware.vc.VirtualMachineConfigInfo;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
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
 * Reconfigure an early binding portgroup to an existing distributed virtual
 * switch with one port and reconfigure 2 VMs(or 2 vnics on the same VM) to
 * connect to this portgroup
 */
public class Neg012 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private VirtualMachine iVirtualMachine = null;
   private HostSystem iHostSystem = null;
   private NetworkSystem iNetworkSystem = null;
   private ManagedObjectReference dvPortgroupMor = null;
   private ManagedObjectReference hostMor = null;
   private ManagedObjectReference[] vmMor = null;
   private ManagedObjectReference nsMor = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private HostNetworkConfig[] hostNetworkConfig = null;
   private HostNetworkConfig originalNetworkConfig = null;
   private VirtualMachinePowerState[] vmPowerState = null;
   private DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private DistributedVirtualSwitchPortConnection prtConnection = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private String portgroupKey = null;
   private String portKey = null;
   private VirtualMachineConfigSpec[][] updatedDeltaConfigSpec = null;
   private DistributedVirtualSwitchHostMemberPnicSpec[] dvsHostMemberPnicSpec = null;
   private int numEthernetCards = 0;
   private ManagedObjectReference dcMor = null;

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
      String className = null;
      String nameParts[] = null;
      String portgroupName = null;
      final String dvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
               + getTestId();
      int len = 0;
      int i = 0;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      VirtualMachineConfigInfo vmConfigInfo = null;
      VirtualDevice[] vds = null;
      Vector allVMs = null;
      log.info("Test setup Begin:");
      try {
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         this.iVirtualMachine = new VirtualMachine(connectAnchor);
         this.iHostSystem = new HostSystem(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.iNetworkSystem = new NetworkSystem(connectAnchor);
         this.dcMor = this.iFolder.getDataCenter();
         /*
          * Get a standalone host of version 4.0
          */
         this.hostMor = this.iHostSystem.getAllHost().get(0);
         /*
          * If there is no standalone host available,  try to
          * get a clustered host of version 4.0
          */
         if (this.hostMor == null) {
            this.hostMor = this.iHostSystem.getClusteredHost();
            if (TestUtil.compareVersion(
                     this.iHostSystem.getHostVersion(this.hostMor),
                     VersionConstants.ESX400) != VersionConstants.EQUAL_VERSION) {
               this.hostMor = null;
            }
         }
         if (hostMor != null) {
            this.rootFolderMor = this.iFolder.getRootFolder();
            if (this.rootFolderMor != null) {
               this.dvsConfigSpec = new DVSConfigSpec();
               this.dvsConfigSpec.setConfigVersion("");
               this.dvsConfigSpec.setName(dvsName);
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
                     this.iNetworkSystem.refresh(nsMor);
                     Thread.sleep(5000);
                     this.iNetworkSystem.updateNetworkConfig(nsMor,
                              hostNetworkConfig[0],
                              TestConstants.CHANGEMODE_MODIFY);
                     this.originalNetworkConfig = hostNetworkConfig[1];
                     allVMs = this.iHostSystem.getVMs(hostMor, null);
                     /*
                      * Get 2 VMs in the list of VMs.
                      */
                     if (allVMs != null && allVMs.size() >= 2) {
                        this.vmMor = new ManagedObjectReference[] {
                                 (ManagedObjectReference) allVMs.get(0),
                                 (ManagedObjectReference) allVMs.get(1) };
                     }
                     numEthernetCards = DVSUtil.getAllVirtualEthernetCardDevices(
                              vmMor[0], connectAnchor).size();
                     this.vmPowerState = new VirtualMachinePowerState[vmMor.length];
                     this.vmPowerState[0] = this.iVirtualMachine.getVMState(vmMor[0]);
                     if (this.iVirtualMachine.setVMState(vmMor[0], VirtualMachinePowerState.POWERED_OFF, false)) {
                        log.info("Successfully powered off the "
                                 + "first VM");
                        status = true;
                        /*
                         * If number of ethernet cards is less than two,
                         * let us setup the second VM.
                         */
                        if (numEthernetCards < 2) {
                           this.vmPowerState[1] = this.iVirtualMachine.getVMState(vmMor[1]);
                           if (this.iVirtualMachine.setVMState(vmMor[1], VirtualMachinePowerState.POWERED_OFF, false)) {
                              log.info("Successfully powered off "
                                       + "the second VM");
                           } else {
                              log.error("Could not power off the "
                                       + "second VM");
                              status = false;
                           }
                        }
                        this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
                        this.dvPortgroupConfigSpec.setConfigVersion("");
                        this.dvPortgroupConfigSpec.setName(this.getTestId());
                        this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
                        dvPortgroupConfigSpecArray = new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec };
                        dvPortgroupMorList = this.iDVSwitch.addPortGroups(
                                 dvsMor, dvPortgroupConfigSpecArray);
                        if (dvPortgroupMorList != null
                                 && dvPortgroupMorList.get(0) != null) {
                           log.info("Successfully added the "
                                    + "portgroup");
                        } else {
                           log.error("Failed to add the portgroup");
                           status = false;
                        }
                     } else {
                        log.error("Could not power off the "
                                 + "first VM");
                     }
                  } else {
                     log.error("The network system MOR is null");
                  }
               } else {
                  log.error("Failed to create the distributed "
                           + "virtual switch");
               }
            } else {
               log.error("Failed to find a folder");
            }
         } else {
            log.error("Failed to login");
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that reconfigures an early binding portgroup with one port to the
    * distributed virtual switch and 2 VMs(or 2 vnics in the same VM) are
    * reconfigured to connect to the created portgroup
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure an early binding portgroup to an existing"
            + " distributed virtual switch with one port and "
            + "reconfigure two VMs(or 2 vnics on the same VM) to "
            + "connect to this portgroup")
   public void test()
      throws Exception
   {
      try {
            log.info("Test Begin:");
            DistributedVirtualSwitchPortConnection[] dvsPortConn = null;
            this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
            this.dvPortgroupConfigSpec.setConfigVersion(this.iDVPortgroup.getConfigInfo(
                     this.dvPortgroupMorList.get(0)).getConfigVersion());
            this.dvPortgroupConfigSpec.setNumPorts(1);
            if (this.iDVPortgroup.reconfigure(dvPortgroupMorList.get(0),
                     dvPortgroupConfigSpec)) {
               log.info("Successfully reconfigured the portgroup");
               portgroupKey = this.iDVPortgroup.getKey(dvPortgroupMorList.get(0));
               if (portgroupKey != null) {
                  portKey = iDVSwitch.getFreePortInPortgroup(dvsMor, portgroupKey,
                           null);
                  if (portKey != null) {
                     prtConnection = new DistributedVirtualSwitchPortConnection();
                     prtConnection.setPortgroupKey(portgroupKey);
                     prtConnection.setPortKey(portKey);
                     prtConnection.setSwitchUuid(this.iDVSwitch.getConfig(dvsMor).getUuid());
                     updatedDeltaConfigSpec = new VirtualMachineConfigSpec[2][2];
                     dvsPortConn = new DistributedVirtualSwitchPortConnection[2];
                     for (int i = 0; i < 2; i++) {
                        dvsPortConn[i] = prtConnection;
                     }
                     updatedDeltaConfigSpec[0] = DVSUtil.getVMConfigSpecForDVSPort(
                              vmMor[0], connectAnchor, dvsPortConn);
                     if (this.iVirtualMachine.reconfigVM(vmMor[0],
                              updatedDeltaConfigSpec[0][0])) {
                        if (numEthernetCards > 1) {
                           log.error("Successfully reconfigured "
                                    + "the VM to connect to the early binding "
                                    + "portgroup. The API did not throw an "
                                    + "exception");
                        } else {
                           log.info("Successfully reconfigured the "
                                    + "VM to connect to the early binding "
                                    + "portgroup");
                        }
                     }
                     if (numEthernetCards < 2) {
                        updatedDeltaConfigSpec[1] = DVSUtil.getVMConfigSpecForDVSPort(
                                 vmMor[1], connectAnchor, dvsPortConn);
                        if (this.iVirtualMachine.reconfigVM(vmMor[1],
                                 updatedDeltaConfigSpec[1][0])) {
                           log.error("Successfully reconfigured "
                                    + "the second VM to connect to the early "
                                    + "binding portgroup. The API did not "
                                    + "throw an exception");
                        } else {
                           log.error("Could not reconfigure the "
                                    + "second VM to connect to the early "
                                    + "binding portgroup. The API did not "
                                    + "throw an exception.");
                        }
                     }
                  } else {
                     log.error("Port key is null");
                  }
               } else {
                  log.error("Portgroup key is null");
               }
            } else {
               log.error("Failed to reconfigure the portgroup");
            }
            com.vmware.vcqa.util.Assert.assertTrue(false,
                     "No Exception Thrown!");
         } catch (Exception excep) {
            com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
            com.vmware.vc.MethodFault expectedMethodFault = new ResourceInUse();
            com.vmware.vcqa.util.Assert.assertTrue(
                     com.vmware.vcqa.util.TestUtil.checkMethodFault(
                              actualMethodFault, expectedMethodFault),
                     "MethodFault mismatch!");
         }


   }

   /**
    * Method to restore the state as it was before the test was started. Restore
    * the original state of the VM.Destroy the portgroup, followed by the
    * distributed virtual switch
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
          * Reconfigure both the VMs to their original configuration and
          * restore the original power states of the respective VMs
          */
         for (int i = 0; i < vmMor.length; i++) {
            if (!(i == 1 && numEthernetCards > 1)) {
               status &= this.iVirtualMachine.reconfigVM(vmMor[i],
                        updatedDeltaConfigSpec[i][1]);
               status &= this.iVirtualMachine.setVMState(vmMor[i],
                        this.vmPowerState[i], false);
            }
         }
         /*
          * Restore the original network config
          */
         if (this.originalNetworkConfig != null) {
            status &= this.iNetworkSystem.updateNetworkConfig(nsMor,
                     originalNetworkConfig, TestConstants.CHANGEMODE_MODIFY);
         }
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
