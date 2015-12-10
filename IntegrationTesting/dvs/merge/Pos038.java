/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.merge;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnecteeConnecteeType;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.HostIpConfig;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostNetworkInfo;
import com.vmware.vc.HostProxySwitchConfig;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
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
 * Merge two distributed virtual switches with two hosts, each connected to one
 * switch and the source switch contains three ports in a portgroup attached to
 * a host service console vnic, vmkernel nic and a VM virtual nic
 */
public class Pos038 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference destDvsMor = null;
   private ManagedObjectReference srcDvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private VirtualMachine iVirtualMachine = null;
   private HostSystem iHostSystem = null;
   private NetworkSystem iNetworkSystem = null;
   private ManagedObjectReference firstHostMor = null;
   private ManagedObjectReference secondHostMor = null;
   private ManagedObjectReference vmMor = null;
   private ManagedObjectReference firstNetworkMor = null;
   private ManagedObjectReference secondNetworkMor = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private HostNetworkConfig[][] hostNetworkConfig = null;
   private VirtualMachinePowerState vmPowerState = null;
   private DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private String portgroupKey = null;
   private Map<String, List<String>> usedPorts = null;
   private VirtualMachineConfigSpec[] vmDeltaConfigSpec = null;
   private Vector<ManagedObjectReference> hosts = null;
   private DistributedVirtualSwitchPortCriteria portCriteria = null;
   private Vector allVMs = null;
   private ManagedObjectReference dcMor = null;
   private String scVnicId = null;
   private String vnicId = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Merge two distributed virtual switches with two "
               + "hosts, each connected to one switch and the "
               + "source switch contains three ports in a portgroup "
               + "attached to a host service console vnic, VMkernel nic"
               + " and a VM virtual nic");
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
      final String dvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
               + getTestId();
      HostNetworkInfo networkInfo = null;
      HostIpConfig ipConfig = null;
      HostVirtualNicSpec hostVnicSpec = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      DVPortConfigSpec portConfigSpec = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      log.info("Test setup Begin:");

         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         this.iVirtualMachine = new VirtualMachine(connectAnchor);
         this.iHostSystem = new HostSystem(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.iNetworkSystem = new NetworkSystem(connectAnchor);
         hosts = this.iHostSystem.getAllHost();
         if (hosts != null && hosts.size() >= 2) {
            log.info("Found two hosts");
            this.firstHostMor = hosts.get(0);
            this.secondHostMor = hosts.get(1);
            if (this.firstHostMor != null && this.secondHostMor != null) {
               this.rootFolderMor = this.iFolder.getRootFolder();
               this.dcMor = this.iFolder.getDataCenter();
               if (this.rootFolderMor != null) {
                  this.dvsConfigSpec = new DVSConfigSpec();
                  this.dvsConfigSpec.setConfigVersion("");
                  this.dvsConfigSpec.setNumStandalonePorts(1);
                  this.dvsConfigSpec.setName(dvsName + ".1");
                  hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
                  hostConfigSpecElement.setHost(this.firstHostMor);
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
                  this.destDvsMor = this.iFolder.createDistributedVirtualSwitch(
                           this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
                  if (this.destDvsMor != null) {
                     log.info("Successfully created the dvswitch");
                     hostNetworkConfig = new HostNetworkConfig[2][2];
                     hostNetworkConfig[0] = this.iDVSwitch.getHostNetworkConfigMigrateToDVS(
                              this.destDvsMor, this.firstHostMor);
                     this.firstNetworkMor = this.iNetworkSystem.getNetworkSystem(this.firstHostMor);
                     if (this.firstNetworkMor != null) {
                        this.iNetworkSystem.refresh(this.firstNetworkMor);
                        this.iNetworkSystem.updateNetworkConfig(
                                 this.firstNetworkMor, hostNetworkConfig[0][0],
                                 TestConstants.CHANGEMODE_MODIFY);
                        hostConfigSpecElement.setHost(this.secondHostMor);
                        this.dvsConfigSpec.getHost().clear();
                        this.dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
                        this.dvsConfigSpec.setNumStandalonePorts(3);
                        this.dvsConfigSpec.setName(dvsName + ".2");
                        this.srcDvsMor = this.iFolder.createDistributedVirtualSwitch(
                                 this.iFolder.getNetworkFolder(dcMor),
                                 dvsConfigSpec);
                        if (this.srcDvsMor != null) {
                           log.info("Successfully created the "
                                    + "second distributed virtual switch");
                           this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
                           this.dvPortgroupConfigSpec.setName(this.getClass().getName());
                           this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
                           this.dvPortgroupConfigSpec.setNumPorts(3);
                           dvPortgroupMorList = this.iDVSwitch.addPortGroups(
                                    srcDvsMor,
                                    new DVPortgroupConfigSpec[] { this.dvPortgroupConfigSpec });
                           if (dvPortgroupMorList != null) {
                              status = true;
                              log.info("Successfully added the "
                                       + "portgroup");
                              this.portgroupKey = this.iDVPortgroup.getKey(dvPortgroupMorList.get(0));
                           } else {
                              log.error("Failed to add the "
                                       + "portgroup");
                           }
                           hostNetworkConfig[1] = this.iDVSwitch.getHostNetworkConfigMigrateToDVS(
                                    this.srcDvsMor, this.secondHostMor);
                           this.secondNetworkMor = this.iNetworkSystem.getNetworkSystem(this.secondHostMor);
                           if (this.secondNetworkMor != null) {
                              this.iNetworkSystem.refresh(this.secondNetworkMor);
                              this.iNetworkSystem.updateNetworkConfig(
                                       this.secondNetworkMor,
                                       hostNetworkConfig[1][0],
                                       TestConstants.CHANGEMODE_MODIFY);
                              hostVnicSpec = new HostVirtualNicSpec();
                              usedPorts = new HashMap<String, List<String>>();
                              if (portgroupKey != null) {
                                 portConnection = this.iDVSwitch.getPortConnection(
                                          srcDvsMor, null, false, usedPorts,
                                          new String[] { portgroupKey });
                              }
                              if (portConnection != null) {
                                 portConfigSpec = new DVPortConfigSpec();
                                 portConfigSpec.setName(this.getClass().getName()
                                          + ".1");
                                 portConfigSpec.setKey(portConnection.getPortKey());
                                 portConfigSpec.setOperation(TestConstants.CONFIG_SPEC_EDIT);
                                 if (this.iDVSwitch.reconfigurePort(
                                          this.srcDvsMor,
                                          new DVPortConfigSpec[] { portConfigSpec })) {
                                    log.info("Successfully "
                                             + "reconfigured the port");
                                 } else {
                                    log.error("Could not "
                                             + "reconfigure the port");
                                    status = false;
                                 }
                                 log.info("Successfully obtained "
                                          + "a DistributedVirtualSwitchPortConnection");
                                 hostVnicSpec = new HostVirtualNicSpec();
                                 ipConfig = new HostIpConfig();
                                 ipConfig.setDhcp(false);
                                 String ipAddress = TestUtil.
                                 getAlternateServiceConsoleIP(this.iHostSystem.
                                          getIPAddress(this.secondHostMor));
                                 if(ipAddress != null){
                                    ipConfig.setIpAddress(ipAddress);
                                 } else {
                                    ipConfig.setDhcp(true);
                                 }

                                 hostVnicSpec.setDistributedVirtualPort(portConnection);
                                 networkInfo = this.iNetworkSystem.getNetworkInfo(this.secondNetworkMor);
                                 if (networkInfo != null) {
                                    log.info("Successfully "
                                             + "obtained the network information"
                                             + " for the host");
                                    /*
                                     * Connect the service console vnic to
                                     * a port
                                     */
                                    if (!this.iHostSystem.isEesxHost(this.secondHostMor)
                                             && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0] != null) {
                                       ipConfig.setSubnetMask(com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec().getIp().getSubnetMask());
                                       hostVnicSpec.setIp(ipConfig);
                                       /*
                                        * Add a service console virtual nic
                                        */
                                       scVnicId = this.iNetworkSystem.addServiceConsoleVirtualNic(
                                                this.secondNetworkMor, "",
                                                hostVnicSpec);
                                       if (scVnicId != null
                                                && DVSUtil.checkNetworkConnectivity(
                                                         ipConfig.getIpAddress(),
                                                         null)) {
                                          log.info("Successfully added "
                                                   + "the service console vnic");
                                       } else {
                                          log.error("Failed to add the "
                                                   + "service console virtual nic");
                                          status = false;
                                       }
                                    }
                                    portConnection = this.iDVSwitch.getPortConnection(
                                             this.srcDvsMor, null, false,
                                             usedPorts,
                                             new String[] { portgroupKey });
                                    if (portConnection != null) {
                                       portConfigSpec = new DVPortConfigSpec();
                                       portConfigSpec.setName(this.getClass().getName()
                                                + ".2");
                                       portConfigSpec.setOperation(TestConstants.CONFIG_SPEC_EDIT);
                                       portConfigSpec.setKey(portConnection.getPortKey());
                                       if (this.iDVSwitch.reconfigurePort(
                                                this.srcDvsMor,
                                                new DVPortConfigSpec[] { portConfigSpec })) {
                                          log.info("Successfully "
                                                   + "reconfigured the port");
                                       } else {
                                          log.error("Could not "
                                                   + "reconfigure the port");
                                          status = false;
                                       }
                                    } else {
                                       log.error("Cannot obtain a"
                                                + " DistributedVirtualSwitchPortConnection for vmknic");
                                       status = false;
                                    }
                                    /*
                                     * Connect the VMKernel nic to a
                                     * port
                                     */
                                    hostVnicSpec = new HostVirtualNicSpec();
                                    ipConfig = new HostIpConfig();
                                    ipConfig.setDhcp(false);
                                    if(ipAddress != null){
                                       ipConfig.setIpAddress(ipAddress);
                                    } else {
                                       ipConfig.setDhcp(true);
                                    }
                                    hostVnicSpec.setDistributedVirtualPort(portConnection);
                                    if (networkInfo != null) {
                                       if (!this.iHostSystem.isEesxHost(this.secondHostMor)) {
                                          ipConfig.setSubnetMask(com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec().getIp().getSubnetMask());
                                       } else {
                                          ipConfig.setSubnetMask(com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec().getIp().getSubnetMask());
                                       }

                                       hostVnicSpec.setIp(ipConfig);
                                       /*
                                        *Add a VMKernel nic
                                        */
                                       vnicId = this.iNetworkSystem.addVirtualNic(
                                                this.secondNetworkMor, "",
                                                hostVnicSpec);
                                       if (vnicId != null) {
                                          log.info("Successfully added "
                                                   + "the VMKernel nic");
                                       } else {
                                          log.error("Failed to add the "
                                                   + "VMKernel nic");
                                          status = false;
                                       }
                                    } else {
                                       log.error("Cannot obtain "
                                                + "the virtual NIC");
                                       status = false;
                                    }
                                    /*
                                     * Connect a VM virtual NIC to a port
                                     * in the source dvswitch
                                     */
                                    allVMs = this.iHostSystem.getVMs(
                                             this.secondHostMor, null);
                                    /*
                                     * Get the first VM in the list of VMs.
                                     */
                                    if (allVMs != null) {
                                       this.vmMor = (ManagedObjectReference) allVMs.get(0);
                                    }
                                    if (this.vmMor != null) {
                                       this.vmPowerState = this.iVirtualMachine.getVMState(vmMor);
                                       if (this.iVirtualMachine.setVMState(
                                                vmMor, VirtualMachinePowerState.POWERED_OFF, false)) {
                                          log.info("Successfully "
                                                   + "powered off the"
                                                   + " virtual machine");
                                       } else {
                                          log.error("Could not "
                                                   + "power off the virtual machine");
                                          status = false;
                                       }
                                    } else {
                                       log.error("Cannot find " + "a VM");
                                       status = false;
                                    }
                                    portConnection = this.iDVSwitch.getPortConnection(
                                             this.srcDvsMor, null, false,
                                             usedPorts,
                                             new String[] { portgroupKey });
                                    if (portConnection != null) {
                                       portConfigSpec = new DVPortConfigSpec();
                                       portConfigSpec.setName(this.getClass().getName()
                                                + ".3");
                                       portConfigSpec.setOperation(TestConstants.CONFIG_SPEC_EDIT);
                                       portConfigSpec.setKey(portConnection.getPortKey());
                                       if (this.iDVSwitch.reconfigurePort(
                                                this.srcDvsMor,
                                                new DVPortConfigSpec[] { portConfigSpec })) {
                                          log.info("Successfully "
                                                   + "reconfigured the port");
                                       } else {
                                          log.error("Could not "
                                                   + "reconfigure the port");
                                          status = false;
                                       }
                                    } else {
                                       log.error("Could not "
                                                + "obtain a DistributedVirtualSwitchPortConnection");
                                       status = false;
                                    }
                                    vmDeltaConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                                             vmMor,
                                             connectAnchor,
                                             new DistributedVirtualSwitchPortConnection[] { portConnection });
                                    if (vmDeltaConfigSpec != null) {
                                       if (this.iVirtualMachine.reconfigVM(
                                                vmMor, vmDeltaConfigSpec[0])) {
                                          log.info("Successfully "
                                                   + "reconfigured the VM to connect "
                                                   + "to the port");
                                       } else {
                                          status = false;
                                          log.error("Failed to "
                                                   + "reconfigure the VM to "
                                                   + "connect to a port");
                                       }
                                    }
                                 } else {
                                    log.error("Cannot obtain the "
                                             + "network information for the host");
                                    status = false;
                                 }
                              } else {
                                 log.error("Failed to obtain a "
                                          + "DistributedVirtualSwitchPortConnection");
                              }
                           } else {
                              log.error("Cannot find the second "
                                       + "network MOR");
                           }
                        } else {
                           log.error("Failed to create the second"
                                    + " distributed virtual switch");
                        }
                     } else {
                        log.error("Cannot find the first network"
                                 + " MOR");
                     }
                  } else {
                     log.error("Failed to create the dvswitch");
                  }
               } else {
                  log.error("Cannot find the root folder");
               }
            } else {
               log.error("The host MOR is null");
            }
         } else {
            log.error("Cannot find two valid hosts");
         }

      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that merges two distributed virtual switches, each containing one
    * host and the source switch contains three ports in a portgroup attached to
    * a host service console vnic, VMKernel nic and VM virtual nic
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Merge two distributed virtual switches with two "
               + "hosts, each connected to one switch and the "
               + "source switch contains three ports in a portgroup "
               + "attached to a host service console vnic, VMkernel nic"
               + " and a VM virtual nic")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      List<DistributedVirtualPort> port = null;
      List<String> portKeys = null;
      boolean status = false;

         if (this.iDVSwitch.merge(destDvsMor, srcDvsMor)) {
            log.info("Successfully merged the two switches");
            portKeys = usedPorts.get(portgroupKey);
            if (portKeys != null
                     && com.vmware.vcqa.util.TestUtil.vectorToArray(this.iDVSwitch.getConfig(destDvsMor).getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class).length == 2) {
               portCriteria = new DistributedVirtualSwitchPortCriteria();
               portCriteria.setConnected(true);
               portCriteria.setUplinkPort(false);
               portCriteria.setInside(true);
               port = this.iDVSwitch.fetchPorts(destDvsMor, portCriteria);
               if (port != null) {
                  status = true;
                  for (DistributedVirtualPort spec : port) {
                     if (spec.getConfig().getName().indexOf(
                              this.getClass().getName() + ".1") != -1) {
                        status &= spec.getConnectee().getType().equals(
                                 DistributedVirtualSwitchPortConnecteeConnecteeType.HOST_CONSOLE_VNIC.value());
                     } else if (spec.getConfig().getName().indexOf(
                              this.getClass().getName() + ".2") != -1) {
                        status &= spec.getConnectee().getType().equals(
                                 DistributedVirtualSwitchPortConnecteeConnecteeType.HOST_VMK_VNIC.value());
                     } else if (spec.getConfig().getName().indexOf(
                              this.getClass().getName() + ".3") != -1) {
                        status &= spec.getConnectee().getType().equals(
                                 DistributedVirtualSwitchPortConnecteeConnecteeType.VM_VNIC.value());
                     } else {
                        status = false;
                     }
                  }
               } else {
                  log.error("Could not retrieve the port config spec "
                           + "objects from the destination dvswitch");
               }
            } else {
               log.error("The portkeys are null");
            }
         } else {
            log.error("Failed to merge the two switches");
         }

      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test was started. Restore
    * the original state of the VM. Destroy the distributed virtual switch
    *
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;

         /*
          * Restore the virtual machine's original config spec
          */
         status &= this.iVirtualMachine.reconfigVM(vmMor, vmDeltaConfigSpec[1]);
         /*
          * Restore the power state of the virtual machine
          */
         status &= this.iVirtualMachine.setVMState(vmMor, this.vmPowerState,
                  false);
         /*
          * Remove the service console virtual nic
          */
         if (this.scVnicId != null) {
            status &= this.iNetworkSystem.removeServiceConsoleVirtualNic(
                     this.secondNetworkMor, scVnicId);
         }

         /*
          * Remove the VMKernel nic
          */
         if (this.vnicId != null) {
            status &= this.iNetworkSystem.removeVirtualNic(
                     this.secondNetworkMor, vnicId);
         }
         if (this.hostNetworkConfig != null) {
            if (this.hostNetworkConfig[0][1] != null) {
               /*
                * Restore the original network config for the first host
                */
               status = this.iNetworkSystem.updateNetworkConfig(
                        this.firstNetworkMor, hostNetworkConfig[0][1],
                        TestConstants.CHANGEMODE_MODIFY);
            }

            if (this.hostNetworkConfig[1][1] != null) {
               /*
                * Restore the original network config of the second host
                */
               HostProxySwitchConfig config = this.iDVSwitch.getDVSVswitchProxyOnHost(
                        this.destDvsMor, this.secondHostMor);
               if (config != null) {
                  config.setSpec(com.vmware.vcqa.util.TestUtil.vectorToArray(hostNetworkConfig[1][1].getProxySwitch(), com.vmware.vc.HostProxySwitchConfig.class)[0].getSpec());
                  this.hostNetworkConfig[1][1].getProxySwitch().clear();
                  this.hostNetworkConfig[1][1].getProxySwitch().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new HostProxySwitchConfig[] { config }));
               }
               status &= this.iNetworkSystem.updateNetworkConfig(
                        this.secondNetworkMor, this.hostNetworkConfig[1][1],
                        TestConstants.CHANGEMODE_MODIFY);
            }
         }

         /*
          * Destroy the destination DVS
          */
         if (this.destDvsMor != null) {
            status &= this.iManagedEntity.destroy(destDvsMor);
         }
         /*
          * Destroy the source DVS
          */
         if (this.srcDvsMor != null
                  && this.iManagedEntity.isExists(this.srcDvsMor)) {
            status &= this.iManagedEntity.destroy(srcDvsMor);
         }

      assertTrue(status, "Cleanup failed");
      return status;
   }
}
