/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
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
import com.vmware.vc.HostIpConfig;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostNetworkInfo;
import com.vmware.vc.HostProxySwitchConfig;
import com.vmware.vc.HostProxySwitchSpec;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.ClusterComputeResource;
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
 * Add an early binding portgroup to an existing distributed virtual switch with
 * scope set to compute resource mor, datacenter mor
 */
public class Pos021 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private DistributedVirtualPortgroup iDvPortgroup = null;
   private ManagedObjectReference dvPortgroupMor = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private ManagedObjectReference computeResourceMor = null;
   private ClusterComputeResource iComputeResource = null;
   private ManagedObjectReference hostMor = null;
   private HostSystem iHostSystem = null;
   private DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
   private NetworkSystem iNetworkSystem = null;
   private ManagedObjectReference networkMor = null;
   private HostNetworkConfig[] hostNetworkConfig = null;
   private String portgroupKey = null;
   private ManagedObjectReference vmMor = null;
   private VirtualMachine iVirtualMachine = null;
   private Vector allVMs = null;
   private Map<String, List<String>> usedPorts = null;
   private VirtualMachinePowerState vmPowerState = null;
   private VirtualMachineConfigSpec[] vmDeltaConfigSpec = null;
   private ManagedObjectReference dcMor = null;
   private boolean isEesx = false;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Add an early binding portgroup to an existing"
               + " distributed virtual switch with scope"
               + " set to compute resource mor, datacenter mor");
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
      String className = null;
      String nameParts[] = null;
      String portgroupName = null;
      int len = 0;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      log.info("Test setup Begin:");

         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iDvPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.iHostSystem = new HostSystem(connectAnchor);
         this.iNetworkSystem = new NetworkSystem(connectAnchor);
         this.iComputeResource = new ClusterComputeResource(connectAnchor);
         this.iVirtualMachine = new VirtualMachine(connectAnchor);
         this.rootFolderMor = this.iFolder.getRootFolder();
         this.dcMor = this.iFolder.getDataCenter();
         if (this.iComputeResource.getAllComputeResources() != null
                  && this.iComputeResource.getAllComputeResources().size() >= 1) {
            log.info("Successfully found compute resource mor "
                     + "objects ");
            this.computeResourceMor = (ManagedObjectReference) this.iComputeResource.getAllComputeResources().get(
                     0);
            if (this.dcMor != null && this.computeResourceMor != null) {
               this.hostMor = this.iComputeResource.getHosts(computeResourceMor).get(
                        0);
               if (this.hostMor != null) {
                  log.info("Successfully found a host");
                  this.isEesx = this.iHostSystem.isEesxHost(hostMor);
                  this.networkMor = this.iNetworkSystem.getNetworkSystem(hostMor);
                  this.dvsConfigSpec = new DVSConfigSpec();
                  this.dvsConfigSpec.setConfigVersion("");
                  this.dvsConfigSpec.setName(this.getClass().getName());
                  this.hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
                  this.hostConfigSpecElement.setHost(this.hostMor);
                  this.hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
                  /*
                   * TODO Check whether the pnic devices need to be
                   * set in the DistributedVirtualSwitchHostMemberPnicSpec
                   */
                  pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                  pnicBacking.getPnicSpec().clear();
                  pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
                  hostConfigSpecElement.setBacking(pnicBacking);
                  dvsConfigSpec.getHost().clear();
                  dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
                  dvsMor = this.iFolder.createDistributedVirtualSwitch(
                           this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
                  allVMs = this.iHostSystem.getAllVirtualMachine(hostMor);
                  if (this.networkMor != null && allVMs != null
                           && dvsMor != null) {
                     log.info("Successfully created the "
                              + "distributed virtual switch");
                     log.info("Successfully obtained the network "
                              + "Mor");
                     this.hostNetworkConfig = this.iDVSwitch.getHostNetworkConfigMigrateToDVS(
                              dvsMor, hostMor);
                     this.iNetworkSystem.refresh(this.networkMor);
                     Thread.sleep(10000);
                     this.iNetworkSystem.updateNetworkConfig(this.networkMor,
                              hostNetworkConfig[0],
                              TestConstants.CHANGEMODE_MODIFY);
                     this.vmMor = (ManagedObjectReference) allVMs.get(0);
                     this.vmPowerState = this.iVirtualMachine.getVMState(vmMor);
                     if (this.iVirtualMachine.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false)) {
                        log.info("Successfully powered off the VM");
                        status = true;
                     } else {
                        log.error("Failed to power off the VM");
                     }
                     this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
                     this.dvPortgroupConfigSpec.setConfigVersion("");
                     this.dvPortgroupConfigSpec.setName(this.getTestId());
                     this.dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
                     this.dvPortgroupConfigSpec.setNumPorts(4);
                     this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
                     this.dvPortgroupConfigSpec.getScope().clear();
                     this.dvPortgroupConfigSpec.getScope().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new ManagedObjectReference[] {
                              this.computeResourceMor, this.dcMor }));
                     status = true;
                  } else {
                     log.error("Failed to obtain the network Mor "
                              + "for the host or there are no VMs"
                              + " on the host");
                  }
               } else {
                  log.error("Cannot find a valid host");
               }
            } else {
               log.error("Failed to find a folder or a compute "
                        + "resource Mor");
            }
         } else {
            log.error("Failed to find compute resource mor " + "objects");
         }

      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that adds an early binding portgroup to the distributed virtual
    * switch with scope set to compute resource mor
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Add an early binding portgroup to an existing"
               + " distributed virtual switch with scope"
               + " set to compute resource mor, datacenter mor")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      HostNetworkInfo networkInfo = null;
      HostVirtualNicSpec hostVnicSpec = null;
      String device = null;
      HostProxySwitchConfig hostProxySwitchConfig = null;
      HostProxySwitchSpec proxySwitchSpec = null;
      DistributedVirtualSwitchHostMemberPnicSpec[] pnicSpec = null;
      Vector physicalNics = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      String vnicId = null;
      HostIpConfig ipConfig = null;
      usedPorts = new HashMap<String, List<String>>();

         this.dvPortgroupMorList = this.iDVSwitch.addPortGroups(dvsMor,
                  new DVPortgroupConfigSpec[] { this.dvPortgroupConfigSpec });
         if (this.dvPortgroupMorList != null
                  && this.dvPortgroupMorList.get(0) != null) {
            log.info("Successfully added the " + "portgroup");
            portgroupKey = this.iDvPortgroup.getKey(dvPortgroupMorList.get(0));
            if (portgroupKey != null) {
               log.info("Successfully found the portgroup key");
               portConnection = this.iDVSwitch.getPortConnection(dvsMor, null,
                        false, usedPorts, new String[] { portgroupKey });
               if (portConnection != null && !isEesx) {
                  /*
                   * Connect the service console virtual nic to
                   * a free port in the portgroup
                   */
                  log.info("Successfully obtained a "
                           + "DistributedVirtualSwitchPortConnection for the service console "
                           + "virtual nic");
                  hostVnicSpec = new HostVirtualNicSpec();
                  ipConfig = new HostIpConfig();
                  networkInfo = this.iNetworkSystem.getNetworkInfo(this.networkMor);
                  String ipAddress = TestUtil.getAlternateServiceConsoleIP(
                           this.iHostSystem.getIPAddress(hostMor));
                  if(ipAddress != null){
                     ipConfig.setDhcp(false);
                     ipConfig.setIpAddress(ipAddress);
                     ipConfig.setSubnetMask(com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0].
                              getSpec().getIp().getSubnetMask());
                  }else{
                     ipConfig.setDhcp(true);
                  }
                  hostVnicSpec.setIp(ipConfig);
                  hostVnicSpec.setDistributedVirtualPort(portConnection);
                  if (networkInfo != null) {
                     log.info("Successfully obtained the "
                              + "network information for the host");
                     device = com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0].getDevice();
                     vnicId = this.iNetworkSystem.addServiceConsoleVirtualNic(
                              this.networkMor, "", hostVnicSpec);
                     if (vnicId != null
                              && DVSUtil.checkNetworkConnectivity(
                                       ipConfig.getIpAddress(), null)) {
                        log.info("Successfully added the "
                                 + "service console virtual NIC to connect "
                                 + "to the DVPort");
                        if (this.iNetworkSystem.removeServiceConsoleVirtualNic(
                                 this.networkMor, vnicId)) {
                           log.info("Successfully removed the "
                                    + "service console virtual nic");
                           status = true;
                        } else {
                           log.error("Failed to remove "
                                    + "the service console virtual nic");
                        }
                     } else {
                        log.error("Failed to add the "
                                 + "service console virtual NIC to connect "
                                 + "to the DVPort");
                     }
                  } else {
                     log.error("Failed to obtain the network "
                              + "information for the host");

                  }
               } else {
                  log.error("Could not obtain a "
                           + "DistributedVirtualSwitchPortConnection for the "
                           + "service console vnic");
               }
               portConnection = this.iDVSwitch.getPortConnection(dvsMor, null,
                        false, usedPorts, new String[] { portgroupKey });
               if (portConnection != null) {
                  /*
                   * Connect the VMKernel nic to
                   * a free port in the portgroup
                   */
                  log.info("Successfully obtained a "
                           + "DistributedVirtualSwitchPortConnection for the VMKernel nic");
                  hostVnicSpec = new HostVirtualNicSpec();
                  hostVnicSpec.setDistributedVirtualPort(portConnection);
                  networkInfo = this.iNetworkSystem.getNetworkInfo(this.networkMor);
                  if (networkInfo != null) {
                     log.info("Successfully obtained the "
                              + "network information for the host");
                     ipConfig = new HostIpConfig();
                     ipConfig.setDhcp(true);
                     if (this.isEesx) {
                        status = true;
                     } else {
                        ipConfig.setSubnetMask(com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec().getIp().getSubnetMask());
                     }
                     hostVnicSpec.setIp(ipConfig);
                     hostVnicSpec.setDistributedVirtualPort(portConnection);
                     vnicId = this.iNetworkSystem.addVirtualNic(
                              this.networkMor, "", hostVnicSpec);
                     if (vnicId != null) {
                        log.info("Successfully added the "
                                 + "virtual nic to connect to a DVPort");
                        if (this.iNetworkSystem.removeVirtualNic(
                                 this.networkMor, vnicId)) {
                           log.info("Successfully removed the "
                                    + "virtual nic");
                        } else {
                           log.error("Failed to remove the "
                                    + "virtual nic");
                           status = false;
                        }
                     } else {
                        log.error("Failed to add the virtual " + "nic");
                        status = false;
                     }
                  } else {
                     log.error("Failed to obtain the network "
                              + "information for the host");
                     status = false;
                  }
               } else {
                  log.error("Could not obtain a "
                           + "DistributedVirtualSwitchPortConnection for the VMKernel nic");
                  status = false;
               }
               portConnection = this.iDVSwitch.getPortConnection(dvsMor, null,
                        false, usedPorts, new String[] { portgroupKey });
               /*
                * Connect a VM virtual nic to the portgroup
                */
               if (portConnection != null) {
                  log.info("Successfully obtained the port "
                           + "connection for connecting a VM virtual nic");
                  vmDeltaConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                           vmMor,
                           connectAnchor,
                           new DistributedVirtualSwitchPortConnection[] { portConnection });
                  if (this.iVirtualMachine.reconfigVM(vmMor,
                           vmDeltaConfigSpec[0])) {
                     log.info("Successfully reconfigured the "
                              + "portgroup");
                     if (this.iVirtualMachine.setVMState(vmMor, VirtualMachinePowerState.POWERED_ON, true)) {
                        log.info("Successfully powered on the VM");
                        status = DVSUtil.checkNetworkConnectivity(
                                 this.iHostSystem.getIPAddress(hostMor),
                                 this.iVirtualMachine.getIPAddress(vmMor));
                     } else {
                        log.error("Failed to power on the VM");
                     }
                  } else {
                     log.error("Failed to reconfigure the portgroup");
                  }
               } else {
                  log.error("Successfully obtained the port "
                           + "connection for connecting a VM virtual nic");
               }
            } else {
               log.error("Cannot obtain the portgroup key");
            }
         } else {
            log.error("Failed to add the portgroup");
            status = false;
         }

      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test was started. Destroy
    * the distributed virtual switch
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
          * Restore the original power state of the VM
          */
         status &= this.iVirtualMachine.setVMState(vmMor, this.vmPowerState,
                  false);
         /*
          * Restore the original configuration of the virtual machine
          */
         status &= this.iVirtualMachine.reconfigVM(vmMor, vmDeltaConfigSpec[1]);
         /*
          * Restore the original network configuration of the host
          */
         status &= this.iNetworkSystem.updateNetworkConfig(this.networkMor,
                  hostNetworkConfig[1], TestConstants.CHANGEMODE_MODIFY);

      } catch (Exception e) {
         TestUtil.handleException(e);
         status = false;
      } finally {
         try {
            /*
             * Destroy the distributed virtual switch
             */
            status &= this.iManagedEntity.destroy(dvsMor);
         } catch (Exception ex) {
            TestUtil.handleException(ex);
            status = false;
         }
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
