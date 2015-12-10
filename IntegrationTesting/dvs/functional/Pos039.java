/*
 * ************************************************************************
 *
 * Copyright 2008-2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.TestConstants.VM_DEFAULT_GUEST_WINDOWS;
import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_SCSI_BUSL_CONTROLLER;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.HostVirtualNicConfig;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * 1. Create a DVS while simultaneously adding the host.<br>
 * 2. Add an early binding portgroup with one port to the DVS <br>
 * 3. Create a VM<br>
 * 4. reconfigure VM to connect to this early binding portgroup.<br>
 * 5. Verify the power ops of the VM.<br>
 * 6. Delete the VM <br>
 * 7. Update the existing service console to connect to early binding portgroup<br>
 * 8. Reconfigure the portgroup 9. Reboot the host<br>
 */
public class Pos039 extends TestBase
{
   private HostSystem ihs = null;
   private ManagedObjectReference hostMor = null;
   private NetworkSystem ins = null;
   private HostNetworkConfig originalNetworkConfig = null;
   private ManagedObjectReference nsMor = null;
   private VirtualMachine ivm = null;
   private DistributedVirtualSwitchHelper iDVS = null;
   private DistributedVirtualPortgroup iDVPG = null;
   private Folder iFolder = null;
   private DVSConfigSpec configSpec = null;
   private DistributedVirtualSwitchHostMemberConfigSpec hostMember = null;
   private DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
   private ManagedObjectReference dvsMor = null;
   private HostNetworkConfig[] hostNetworkConfig = null;
   private String dvSwitchName = getTestId() + "-dvs";
   private HostVirtualNicSpec origconsoleVnicSpec = null;
   private String consoleVnicdevice = null;
   private String dvSwitchUuid = null;
   boolean updated = false;
   private String portgroupKey = null;
   private String hostName = null;
   private ManagedObjectReference pgMor = null;
   private String pgName = null;
   private boolean isEsx = false;
   private HostVirtualNicSpec origVnicSpec = null;
   private String vNicdevice = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      super.setTestDescription("This is the stress test for DVS related "
               + "operations.\n "
               + "This does the following operations on the VC."
               + "1. Create a DVS while simultaneously adding " + "the host.\n"
               + "2. Add an early binding portgroup to the DVS\n"
               + "3. Attach a VM on the host added to this \n"
               + "early binding portgroup."
               + "4. Verify the power ops of the VM\n" + "5. Delete the VM\n"
               + "6. Update the existing service console to connect "
               + "to early binding portgroup \n"
               + "7. Reconfigure the portgroup\n" + "8. Reboot the host");
   }

   /**
    * Method to setup the environment for the test. testSetUp requires multiple
    * hosts equal to the number of instances. There should be 1:1 matching
    * between number of hosts and number of instances
    * 
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      HashMap allHosts = null;
      log.info("Stress test setup Begin:");
      String[] pnicIds = null;
     
         iFolder = new Folder(connectAnchor);
         ivm = new VirtualMachine(connectAnchor);
         iDVS = new DistributedVirtualSwitchHelper(connectAnchor);
         iDVPG = new DistributedVirtualPortgroup(connectAnchor);
         ihs = new HostSystem(connectAnchor);
         ins = new NetworkSystem(connectAnchor);
         allHosts = ihs.getAllHosts(VersionConstants.ESX4x, HostSystemConnectionState.CONNECTED);
         Set hostsSet = allHosts.keySet();
         if (hostsSet != null && hostsSet.size() > 0) {
            Iterator hostsItr = hostsSet.iterator();
            if (hostsItr.hasNext()) {
               hostMor = (ManagedObjectReference) hostsItr.next();
               log.info("Version :"
                        + ihs.getHostProductIdVersion(hostMor));
            }
         }
         if (hostMor != null) {
            log.info("Got ESX4x host");
            hostName = ihs.getHostName(hostMor);
            log.info("hostName : " + hostName);
            ;
            isEsx = !ihs.isEesxHost(hostMor);
            nsMor = ins.getNetworkSystem(hostMor);
            if (nsMor != null) {
               originalNetworkConfig = ins.getNetworkConfig(nsMor);
               pnicIds = ins.getPNicIds(hostMor);
               if (pnicIds != null) {
                  log.info("Free pnics are available on host");
                  configSpec = new DVSConfigSpec();
                  configSpec.setConfigVersion("");
                  configSpec.setName(dvSwitchName);
                  configSpec.setNumStandalonePorts(5);
                  hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
                  pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                  pnicBacking.getPnicSpec().clear();
                  pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
                  hostMember.setBacking(pnicBacking);
                  hostMember.setOperation(TestConstants.CONFIG_SPEC_ADD);
                  hostMember.setHost(hostMor);
                  configSpec.getHost().clear();
                  configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMember }));
                  dvsMor = iFolder.createDistributedVirtualSwitch(
                           iFolder.getNetworkFolder(iFolder.getDataCenter()),
                           configSpec);
                  if (dvsMor != null) {
                     log.info("Successfully created the DVS "
                              + dvSwitchName);
                     if (ins.refresh(nsMor)) {
                        log.info("Refreshed the network system of the host");
                        if (iDVS.validateDVSConfigSpec(dvsMor, configSpec, null)) {
                           log.info("Successfully validated the DVS config spec");
                           hostNetworkConfig = iDVS.getHostNetworkConfigMigrateToDVS(
                                    dvsMor, hostMor);
                           if (hostNetworkConfig != null
                                    && hostNetworkConfig.length == 2
                                    && hostNetworkConfig[0] != null
                                    && hostNetworkConfig[1] != null) {
                              log.info("Successfully retrieved the original "
                                       + "and the updated network config of the host");
                              originalNetworkConfig = hostNetworkConfig[1];
                              if (ins.updateNetworkConfig(nsMor,
                                       hostNetworkConfig[0],
                                       TestConstants.CHANGEMODE_MODIFY)) {
                                 log.info("Successfully updated the host network"
                                          + "  config");
                                 status = true;
                              } else {
                                 log.error("Can not update the host network config");
                              }
                           } else {
                              log.error("Can not retrieve the original and the updated "
                                       + "network config");
                           }
                        } else {
                           log.error("The config spec does not match");
                        }
                     } else {
                        log.error("Can not refresh the network system of the host");
                     }
                  } else {
                     log.error("Can not create the DVS " + dvSwitchName);
                  }
               } else {
                  log.error("There are no free pnics on the host");
               }
            } else {
               log.error("The network system MOR is null");
            }
         } else {
            log.error("The host mor is null");
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "This is the stress test for DVS related "
               + "operations.\n "
               + "This does the following operations on the VC."
               + "1. Create a DVS while simultaneously adding " + "the host.\n"
               + "2. Add an early binding portgroup to the DVS\n"
               + "3. Attach a VM on the host added to this \n"
               + "early binding portgroup."
               + "4. Verify the power ops of the VM\n" + "5. Delete the VM\n"
               + "6. Update the existing service console to connect "
               + "to early binding portgroup \n"
               + "7. Reconfigure the portgroup\n" + "8. Reboot the host")
   public void test()
      throws Exception
   {
      log.info("Stress test Begin:");
      ManagedObjectReference vmMor = null;
      VirtualMachineConfigSpec originalVMConfigSpec = null;
      boolean status = false;
      DVPortgroupConfigSpec pgConfigSpec = null;
      List<ManagedObjectReference> pgList = null;
      String portgroupKey = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      VirtualMachineConfigSpec vmConfigSpec = null;
      String vmName = getTestId() + "-vm";
      HostVirtualNicSpec updatedconsoleVnicSpec = null;
      HostVirtualNicSpec updatedVNicSpec = null;
     
         HostNetworkConfig nwCfg = ins.getNetworkConfig(nsMor);
         if (isEsx) {
            if (nwCfg != null && com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class) != null
                     && com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class).length > 0) {
               HostVirtualNicConfig consoleVnicConfig = com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0];
               origconsoleVnicSpec = consoleVnicConfig.getSpec();
               consoleVnicdevice = consoleVnicConfig.getDevice();
               log.info("consoleVnicDevice : " + consoleVnicdevice);
            }
         } else {
            if (nwCfg != null && com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class) != null
                     && com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class).length > 0
                     && com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0] != null) {
               HostVirtualNicConfig vnicConfig = com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0];
               origVnicSpec = vnicConfig.getSpec();
               vNicdevice = vnicConfig.getDevice();
               log.info("VnicDevice : " + vNicdevice);
            } else {
               log.error("Unable to find valid Vnic");
            }
         }
         vmConfigSpec = buildDefaultSpec(connectAnchor, hostMor,
                  TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32, vmName);
         vmMor = new Folder(super.getConnectAnchor()).createVM(
                  ivm.getVMFolder(), vmConfigSpec, ihs.getPoolMor(hostMor),
                  hostMor);
         if (vmMor != null) {
            log.info("Successfully created the VM " + vmName);
            pgConfigSpec = new DVPortgroupConfigSpec();
            pgName = getTestId() + "-earlypg";
            pgConfigSpec.setName(pgName);
            pgConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
            pgConfigSpec.setNumPorts(1);
            if (iDVS.isExists(dvsMor)) {
               pgList = iDVS.addPortGroups(dvsMor,
                        new DVPortgroupConfigSpec[] { pgConfigSpec });
               if (pgList != null && pgList.size() == 1) {
                  log.info("Successfully added the early binding "
                           + "portgroup to the DVS " + pgName);
                  pgMor = pgList.get(0);
                  if (pgMor != null) {
                     portgroupKey = iDVPG.getKey(pgMor);
                     if (portgroupKey != null) {
                        portConnection = iDVS.getPortConnection(dvsMor, null,
                                 false, null, portgroupKey);
                        if (portConnection != null) {
                           originalVMConfigSpec = reconfigVM(vmMor,
                                    portConnection, connectAnchor);
                           if (originalVMConfigSpec == null) {
                              log.error("Can not retreive the "
                                       + "original VM config spec");
                           } else {
                              if (ivm.verifyPowerOps(vmMor, false)) {
                                 log.info("Successfully verified the power "
                                          + "ops of the VM");
                                 log.info("Restoring the VM to its original"
                                          + " configuration");
                                 if (vmMor != null
                                          && ivm.reconfigVM(vmMor,
                                                   originalVMConfigSpec)) {
                                    if (ivm.setVMState(
                                             vmMor, VirtualMachinePowerState.POWERED_OFF, false)) {
                                       log.info("Destroying the created VM");
                                       if (ivm.destroy(vmMor)) {
                                          log.info("Destroyed the created VM"
                                                   + " :" + vmName);
                                          DVSConfigInfo info = iDVS.getConfig(dvsMor);
                                          dvSwitchUuid = info.getUuid();
                                          portConnection = new DistributedVirtualSwitchPortConnection();
                                          portConnection.setSwitchUuid(dvSwitchUuid);
                                          portConnection.setPortgroupKey(portgroupKey);
                                          if (isEsx) {
                                             if (portConnection != null) {
                                                updatedconsoleVnicSpec = (HostVirtualNicSpec) TestUtil.deepCopyObject(origconsoleVnicSpec);
                                                updatedconsoleVnicSpec.setDistributedVirtualPort(portConnection);
                                                updatedconsoleVnicSpec.setPortgroup(null);
                                                if (ins.updateServiceConsoleVirtualNic(
                                                         nsMor,
                                                         consoleVnicdevice,
                                                         updatedconsoleVnicSpec)) {
                                                   log.info("Successfully updated serviceconsole VirtualNic "
                                                            + consoleVnicdevice);
                                                   updated = status = rebootAndVerifyNetworkConnectivity(hostMor);
                                                } else {
                                                   log.info("Unable to update serviceconsole VirtualNic "
                                                            + consoleVnicdevice);
                                                   status = false;
                                                }
                                             } else {
                                                status = false;
                                                log.error("can not get a free port on the dvswitch");
                                             }
                                          } else {
                                             if (portConnection != null) {
                                                updatedVNicSpec = (HostVirtualNicSpec) TestUtil.deepCopyObject(origVnicSpec);
                                                updatedVNicSpec.setDistributedVirtualPort(portConnection);
                                                updatedVNicSpec.setPortgroup(null);
                                                if (ins.updateVirtualNic(nsMor,
                                                         vNicdevice,
                                                         updatedVNicSpec)) {
                                                   log.info("Successfully updated VirtualNic "
                                                            + vNicdevice);
                                                   updated = status = rebootAndVerifyNetworkConnectivity(hostMor);
                                                } else {
                                                   log.error("Unable to update VirtualNic "
                                                            + vNicdevice);
                                                   status = false;
                                                }
                                             } else {
                                                status = false;
                                                log.error("can not get a free port on the dvswitch");
                                             }
                                          }
                                       } else {
                                          log.error("Unable to destroy the"
                                                   + " created VM :" + vmName);
                                       }
                                    } else {
                                       log.error("Can not power off the VM");
                                    }
                                 }
                              } else {
                                 log.error("Can not verify the power ops for the VM "
                                          + ivm.getVMName(vmMor));
                              }
                           }
                        } else {
                           log.error("Can not get a free port in "
                                    + "the newly added portgroup");
                        }
                     } else {
                        log.error("The port group key is null");
                     }
                  } else {
                     log.error("The portgroup object is null");
                  }
               } else {
                  log.error("The dvs mor is is null");
               }
            } else {
               log.error("Can not find the dvs entity, doesn't Exists In "
                        + "Inventory");
            }
         } else {
            log.error("Can not create the VM " + vmName);
         }
     
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
     
         if (isEsx && origconsoleVnicSpec != null) {
            if (ins.updateServiceConsoleVirtualNic(nsMor, consoleVnicdevice,
                     origconsoleVnicSpec)) {
               log.info("Successfully restored original console  VirtualNic "
                        + "config: " + consoleVnicdevice);
               status &= true;
            } else {
               log.info("Unable to restore console VirtualNic "
                        + consoleVnicdevice);
               status = false;
            }
         }
         if (!isEsx && origVnicSpec != null) {
            if (ins.updateVirtualNic(nsMor, vNicdevice, origVnicSpec)) {
               log.info("Successfully restored original VirtualNic "
                        + "config: " + vNicdevice);
               status &= true;
            } else {
               log.info("Unable to update VirtualNic " + vNicdevice);
               status = false;
            }
         }
         if (ivm.destroy(pgMor)) {
            log.info("Successfully deleted port group : " + pgName);
            status &= ins.refresh(nsMor);
         } else {
            log.info("Unable to delete the port group : " + pgName);
            status = false;
         }
         if (originalNetworkConfig != null) {
            log.info("Restoring the network setting of the host");
            status &= ins.updateNetworkConfig(nsMor, originalNetworkConfig,
                     TestConstants.CHANGEMODE_MODIFY);
         }
         if (dvsMor != null) {
            status &= iDVS.destroy(dvsMor);
         }
     
      return status;
   }

   /*
    * This method reconfigures a VM to connect to a DV port
    */
   private VirtualMachineConfigSpec reconfigVM(ManagedObjectReference vmMor,
                                               DistributedVirtualSwitchPortConnection portConnection,
                                               ConnectAnchor connectAnchor)
      throws Exception
   {
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      VirtualMachineConfigSpec originalVMConfigSpec = null;
      vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(vmMor, connectAnchor,
               new DistributedVirtualSwitchPortConnection[] { portConnection });
      if (vmConfigSpec != null && vmConfigSpec.length == 2
               && vmConfigSpec[0] != null && vmConfigSpec[1] != null) {
         log.info("Successfully obtained the original and the updated virtual"
                  + " machine config spec");
         originalVMConfigSpec = vmConfigSpec[1];
         if (ivm.reconfigVM(vmMor, vmConfigSpec[0])) {
            log.info("Successfully reconfigured the virtual machine to use "
                     + "the DV port");
            originalVMConfigSpec = vmConfigSpec[1];
         } else {
            log.error("Can not reconfigure the virtual machine to use the "
                     + "DV port");
         }
      }
      return originalVMConfigSpec;
   }

   /**
    * Create a default VMConfigSpec.
    * 
    * @param connectAnchor ConnectAnchor
    * @param hostMor The MOR of the host where the defaultVMSpec has to be
    *           created.
    * @param deviceType type of the device.
    * @param vmName String
    * @return vmConfigSpec VirtualMachineConfigSpec.
    * @throws MethodFault, Exception
    */
   private VirtualMachineConfigSpec buildDefaultSpec(ConnectAnchor connectAnchor,
                                                     ManagedObjectReference hostMor,
                                                     String deviceType,
                                                     String vmName)
      throws Exception
   {
      ManagedObjectReference poolMor = null;
      VirtualMachineConfigSpec vmConfigSpec = null;
      HostSystem ihs = new HostSystem(connectAnchor);
      VirtualMachine ivm = new VirtualMachine(connectAnchor);
      Vector<String> deviceTypesVector = new Vector<String>();
      poolMor = ihs.getPoolMor(hostMor);
      if (poolMor != null) {
         deviceTypesVector.add(TestConstants.VM_VIRTUALDEVICE_DISK);
         deviceTypesVector.add(VM_VIRTUALDEVICE_SCSI_BUSL_CONTROLLER);
         deviceTypesVector.add(deviceType);
         // create the VMCfg with the default devices.
         vmConfigSpec = ivm.createVMConfigSpec(poolMor, hostMor, vmName,
                  VM_DEFAULT_GUEST_WINDOWS, deviceTypesVector, null);
      } else {
         log.error("Unable to get the resource pool from the host.");
      }
      return vmConfigSpec;
   }

   /**
    * This method reboots and checks the network connectivity of the host
    * 
    * @param hostMor HostMor object
    * @return boolean, true if network connectivity is available, false
    *         otherwise
    * @throws MethodFault, Exception
    */
   private boolean rebootAndVerifyNetworkConnectivity(ManagedObjectReference hostMor)
      throws Exception
   {
      boolean status = false;
      if (hostMor != null) {
         ihs.rebootHost(hostMor, data.getInt(TestConstants.TESTINPUT_PORT),
                  true, data.getString(TestConstants.TESTINPUT_USERNAME),
                  data.getString(TestConstants.TESTINPUT_PASSWORD));
         log.info("Rebooted the host:" + hostName);
         if (DVSUtil.checkNetworkConnectivity(ihs.getIPAddress(hostMor), null,
                  null)) {
            status = true;
         } else {
            log.error("Unable to obtain NetworkConnectivity of the host :"
                     + hostName);
         }
      } else {
         log.error("hostMor is null");
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}