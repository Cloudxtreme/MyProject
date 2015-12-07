/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.merge;

import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVPortgroupConfigInfo;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMember;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostProxySwitchConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.ConnectAnchor;
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
 * Create one early and one late binding portgroups having the same names with
 * two VMvnics connected to each different portgroups having different
 * portNameFormat and no conflicting ports. Merge the switches
 */
public class Pos024 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference destDvsMor = null;
   private ManagedObjectReference srcDvsMor = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private HostSystem iHostSystem = null;
   private NetworkSystem iNetworkSystem = null;
   private VirtualMachine ivm = null;
   private DistributedVirtualPortgroup idvpg = null;

   private ManagedObjectReference destnDvsHostMor = null;
   private ManagedObjectReference srcDvsHostMor = null;
   private ManagedObjectReference firstNetworkMor = null;
   private ManagedObjectReference secondNetworkMor = null;
   private ManagedObjectReference srcfolder = null;
   private ManagedObjectReference destfolder = null;

   private HostNetworkConfig[][] hostNetworkConfig = null;
   private DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private Vector<ManagedObjectReference> hosts = null;
   private DistributedVirtualSwitchHostMember[] srcHostMembers = null;
   private int srcMaxPorts = 0;
   private int destnMaxPorts = 0;

   // variables for vm on the host on src dvs
   private ManagedObjectReference vmMor = null;
   private VirtualMachinePowerState oldPowerState = null;
   private VirtualMachineConfigSpec originalVMConfigSpec = null;
   private String vmName = null;
   private String srcDVSName = null;

   private DVPortgroupConfigInfo[] srcPortgroups = null;
   private DVPortSetting[] srcPortSetting = null;
   private DVPortgroupConfigInfo[] destPortgroups = null;
   private final String destPgName = DVSTestConstants.DV_PORTGROUP_CREATE_NAME_PREFIX;
   private final String srcPgName = DVSTestConstants.DV_PORTGROUP_CREATE_NAME_PREFIX;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Create two late binding portgroups (each having "
               + "2 ports) having the different names with two VMvnics connected to "
               + "each different portgroups having different portNameFormat and "
               + "no conflicting ports. Merge the switches");
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
      boolean destDvsConfigured = false;
      boolean srcDvsConfigured = false;
      final String dvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
               + getTestId();
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      Map<String, Object> portgroupInfo = null;
      log.info("Test setup Begin:");
     
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iHostSystem = new HostSystem(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.iNetworkSystem = new NetworkSystem(connectAnchor);
         this.ivm = new VirtualMachine(connectAnchor);
         this.idvpg = new DistributedVirtualPortgroup(connectAnchor);
         hosts = this.iHostSystem.getAllHost();
         if (hosts != null && hosts.size() >= 2) {
            log.info("Found two hosts");
            this.destnDvsHostMor = hosts.get(0);
            this.srcDvsHostMor = hosts.get(1);
            if (this.destnDvsHostMor != null && this.srcDvsHostMor != null) {
               this.rootFolderMor = this.iFolder.getRootFolder();
               if (this.rootFolderMor != null) {
                  // create the dvs spec
                  this.dvsConfigSpec = new DVSConfigSpec();
                  this.dvsConfigSpec.setConfigVersion("");
                  this.dvsConfigSpec.setName(dvsName + ".1");
                  hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
                  hostConfigSpecElement.setHost(this.destnDvsHostMor);
                  hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
                  pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                  pnicBacking.getPnicSpec().clear();
                  pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
                  hostConfigSpecElement.setBacking(pnicBacking);
                  this.dvsConfigSpec.getHost().clear();
                  this.dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
                  ManagedObjectReference networkFolder = this.iFolder.getNetworkFolder(this.iFolder.getDataCenter());
                  this.srcfolder = iFolder.createFolder(networkFolder,
                           this.getTestId() + "-srcFolder");
                  this.destDvsMor = this.iFolder.createDistributedVirtualSwitch(
                           srcfolder, dvsConfigSpec);
                  // get the max ports
                  this.destnMaxPorts = this.iDVSwitch.getConfig(this.destDvsMor).getMaxPorts();
                  if (this.destDvsMor != null) {
                     log.info("Successfully created the dvswitch");
                     hostNetworkConfig = new HostNetworkConfig[2][2];
                     hostNetworkConfig[0] = this.iDVSwitch.getHostNetworkConfigMigrateToDVS(
                              this.destDvsMor, this.destnDvsHostMor);
                     this.firstNetworkMor = this.iNetworkSystem.getNetworkSystem(this.destnDvsHostMor);
                     if (this.firstNetworkMor != null) {
                        if (this.iNetworkSystem.updateNetworkConfig(
                                 this.firstNetworkMor, hostNetworkConfig[0][0],
                                 TestConstants.CHANGEMODE_MODIFY)) {
                           // add the portgroup
                           String portgroupKey = this.iDVSwitch.addPortGroup(
                                    this.destDvsMor,
                                    DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING,
                                    0, this.destPgName);
                           if (portgroupKey != null) {
                              destDvsConfigured = true;
                              this.destPortgroups = getPortgroupList(this.destDvsMor);
                           }
                        } else {
                           log.error("Update network config failed");
                        }
                     } else {
                        log.error("Network config null");
                     }
                     hostConfigSpecElement.setHost(this.srcDvsHostMor);
                     this.dvsConfigSpec = new DVSConfigSpec();
                     this.dvsConfigSpec.getHost().clear();
                     this.dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
                     this.srcDVSName = dvsName + ".2";
                     this.dvsConfigSpec.setName(this.srcDVSName);
                     this.destfolder = iFolder.createFolder(networkFolder,
                              this.getTestId() + "-destFolder");
                     this.srcDvsMor = this.iFolder.createDistributedVirtualSwitch(
                              destfolder, dvsConfigSpec);
                     if (this.srcDvsMor != null) {
                        log.info("Successfully created the "
                                 + "second distributed virtual switch");
                        hostNetworkConfig[1] = this.iDVSwitch.getHostNetworkConfigMigrateToDVS(
                                 this.srcDvsMor, this.srcDvsHostMor);
                        this.secondNetworkMor = this.iNetworkSystem.getNetworkSystem(this.srcDvsHostMor);
                        if (this.secondNetworkMor != null) {
                           this.iNetworkSystem.updateNetworkConfig(
                                    this.secondNetworkMor,
                                    hostNetworkConfig[1][0],
                                    TestConstants.CHANGEMODE_MODIFY);
                           DVSConfigInfo srcDvsConfigInfo = this.iDVSwitch.getConfig(this.srcDvsMor);
                           this.srcHostMembers = com.vmware.vcqa.util.TestUtil.vectorToArray(srcDvsConfigInfo.getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class);
                           // get the max ports
                           this.srcMaxPorts = this.iDVSwitch.getConfig(
                                    this.srcDvsMor).getMaxPorts();
                           // create the pg, set the vm to connect to pg
                           srcDvsConfigured = configureSrcDvs(connectAnchor);
                           // get the portgroups
                           portgroupInfo = this.iDVSwitch.getPortgroupList(this.srcDvsMor);
                           if (portgroupInfo != null) {
                              this.srcPortgroups = (DVPortgroupConfigInfo[]) portgroupInfo.get(DVSTestConstants.PORT_GROUP_CONFIG_KEY);
                              this.srcPortSetting = (DVPortSetting[]) portgroupInfo.get(DVSTestConstants.PORT_GROUP_SETTING_KEY);
                           }
                           ;
                        } else {
                           log.error("Network config null");
                        }
                     }
                  }
               }
            }
         }
     
      return (destDvsConfigured && srcDvsConfigured);
   }

   /**
    * Get non uplink portgroups
    * 
    * @param dvsMor
    * @return
    * @throws Exception
    */
   private DVPortgroupConfigInfo[] getPortgroupList(ManagedObjectReference dvsMor)
      throws Exception
   {
      List<ManagedObjectReference> portgroups = this.iDVSwitch.getPortgroup(dvsMor);
      Vector<DVPortgroupConfigInfo> portgroupsConfigInfo = new Vector<DVPortgroupConfigInfo>();

      if (portgroups != null && !portgroups.isEmpty()) {
         for (Iterator iterator = portgroups.iterator(); iterator.hasNext();) {
            ManagedObjectReference dvPortgroupMor = (ManagedObjectReference) iterator.next();
            if (!this.idvpg.isUplinkPortgroup(dvPortgroupMor, dvsMor)) {
               portgroupsConfigInfo.add(this.idvpg.getConfigInfo(dvPortgroupMor));
            }
         }
      }
      return (DVPortgroupConfigInfo[]) TestUtil.vectorToArray(portgroupsConfigInfo);
   }

   /**
    * Method that merges two distributed virtual switches, each containing one
    * host with two uplink portgroups on each switch with the same name
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Create two late binding portgroups (each having "
               + "2 ports) having the different names with two VMvnics connected to "
               + "each different portgroups having different portNameFormat and "
               + "no conflicting ports. Merge the switches")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         if (this.iDVSwitch.merge(destDvsMor, srcDvsMor)) {
            log.info("Successfully merged the two switches");
            if (this.iNetworkSystem.refresh(this.secondNetworkMor)) {
               if (this.iDVSwitch.validateMergedMaxPorts(srcMaxPorts,
                        destnMaxPorts, this.destDvsMor)) {
                  log.info("Hosts max ports verified");
                  if (this.iDVSwitch.validateMergeHostsJoin(
                           this.srcHostMembers, this.destDvsMor)) {
                     log.info("Hosts join on merge verified");
                     if (this.iDVSwitch.validateMergePortgroups(
                              this.srcPortgroups, this.srcPortSetting,
                              this.srcDVSName, this.destDvsMor)) {
                        status = true;
                     } else {
                        log.info("Portgroup verification failed");
                     }
                  } else {
                     log.info("Hosts join on merge verification failed");
                  }
               } else {
                  log.info("Max ports verification failed");
               }
            } else {
               log.error("Can not refresh the network system of the host");
            }
         } else {
            log.error("Failed to merge the two switches");
         }
     
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test was started. Restore
    * the original state of the VM. Destroy the portgroup, followed by the
    * distributed virtual switch
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
     
         /*
          * Restore the original network config
          */
         status = this.iNetworkSystem.updateNetworkConfig(this.firstNetworkMor,
                  hostNetworkConfig[0][1], TestConstants.CHANGEMODE_MODIFY);
         HostProxySwitchConfig config = this.iDVSwitch.getDVSVswitchProxyOnHost(
                  this.destDvsMor, this.srcDvsHostMor);
         config.setSpec(com.vmware.vcqa.util.TestUtil.vectorToArray(hostNetworkConfig[1][1].getProxySwitch(), com.vmware.vc.HostProxySwitchConfig.class)[0].getSpec());
         hostNetworkConfig[1][1].getProxySwitch().clear();
         hostNetworkConfig[1][1].getProxySwitch().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new HostProxySwitchConfig[] { config }));
         status &= this.iNetworkSystem.updateNetworkConfig(
                  this.secondNetworkMor, hostNetworkConfig[1][1],
                  TestConstants.CHANGEMODE_MODIFY);
         // restore the vm's state
         status &= restoreVM();
         // check if src dvs exists
         if (this.iManagedEntity.isExists(this.srcDvsMor)) {
            // check if able to destroy it
            status &= this.iManagedEntity.destroy(this.srcDvsMor);
         }
         // check if destn dvs exists
         if (this.iManagedEntity.isExists(this.destDvsMor)) {
            // destroy the destn
            status &= this.iManagedEntity.destroy(this.destDvsMor);
         }
         if (this.srcfolder != null) {
            log.info("destroying the source folder");
            this.iFolder.destroy(this.srcfolder);
         }
         if (this.destfolder != null) {
            log.info("destroying the destination folder");
            this.iFolder.destroy(this.destfolder);
         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }

   private boolean restoreVM()
      throws Exception
   {
      boolean cleanUpDone = false;
      if (this.vmMor != null) {
         cleanUpDone = this.ivm.setVMState(this.vmMor, POWERED_OFF, false);
         if (cleanUpDone) {
            log.info("Successfully powered off the vm " + this.vmName);
            if (this.originalVMConfigSpec != null) {
               cleanUpDone &= this.ivm.reconfigVM(this.vmMor,
                        this.originalVMConfigSpec);
               if (cleanUpDone) {
                  log.info("Reconfigured the VM to the original "
                           + "configuration");
               } else {
                  log.error("Can not restore the VM to the original"
                           + " configuration");
               }
            }
            if (cleanUpDone) {
               if (this.oldPowerState != null) {
                  cleanUpDone &= this.ivm.setVMState(this.vmMor,
                           this.oldPowerState, false);
                  if (cleanUpDone) {
                     log.info("Successfully restored the original "
                              + "power state for the vm " + this.vmName);
                  } else {
                     log.error("Can not restore the original power state for"
                              + " the VM " + this.vmName);
                  }
               }
            }
         } else {
            log.error("Can not power off the VM " + this.vmName);
         }
      }
      assertTrue(cleanUpDone, "Cleanup failed");
      return cleanUpDone;
   }

   /**
    * Configures the src DVS. Retrieve a vm on the src host. Add a portgroup
    * with the num of ports equal to the number of ethernet cards on the vm.
    * Configure the VM to connect to ports on this portgroup.
    * 
    * @throws MethodFault,Exception
    */
   private boolean configureSrcDvs(ConnectAnchor connectAnchor)
      throws Exception
   {
      List<ManagedObjectReference> allVms = this.iHostSystem.getVMs(
               this.srcDvsHostMor, null);
      List<VirtualDeviceConfigSpec> vdConfigSpec = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      ArrayList<DistributedVirtualSwitchPortConnection> portConnectionList = null;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      boolean setUpDone = false;

      if (allVms != null && allVms.size() > 0) {
         this.vmMor = allVms.get(0);
         if (this.vmMor != null) {
            this.oldPowerState = this.ivm.getVMState(this.vmMor);
            this.vmName = this.ivm.getVMName(this.vmMor);
            setUpDone = this.ivm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false);
            if (setUpDone) {
               log.info("Succesfully powered off the vm " + this.vmName);
               vdConfigSpec = DVSUtil.getAllVirtualEthernetCardDevices(
                        this.vmMor, connectAnchor);
               if (vdConfigSpec != null) {
                  int numCards = vdConfigSpec.size();

                  // create a DVPortgroup with number of ports equal to vm
                  // ethernet cards
                  if (numCards > 0) {
                     // create DVPortgroup
                     String portgroupKey = this.iDVSwitch.addPortGroup(
                              this.srcDvsMor,
                              DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING,
                              numCards, this.srcPgName);
                     if (portgroupKey != null) {
                        portConnectionList = new ArrayList<DistributedVirtualSwitchPortConnection>(
                                 numCards);
                        for (int i = 0; i < numCards; i++) {
                           portConnection = new DistributedVirtualSwitchPortConnection();
                           portConnection.setPortgroupKey(portgroupKey);
                           portConnection.setSwitchUuid(this.iDVSwitch.getConfig(
                                    this.srcDvsMor).getUuid());
                           portConnectionList.add(portConnection);
                        }
                        vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                                 this.vmMor,
                                 connectAnchor,
                                 portConnectionList.toArray(new DistributedVirtualSwitchPortConnection[portConnectionList.size()]));
                        if (vmConfigSpec != null && vmConfigSpec.length == 2
                                 && vmConfigSpec[0] != null
                                 && vmConfigSpec[1] != null) {
                           this.originalVMConfigSpec = vmConfigSpec[1];
                           setUpDone = this.ivm.reconfigVM(this.vmMor,
                                    vmConfigSpec[0]);
                           if (setUpDone) {
                              log.info("Successfully reconfigured"
                                       + " the VM to use the DV " + "Ports");
                           } else {
                              log.error("Can not reconfigure the"
                                       + " VM to use the DV " + "Ports");
                           }
                        } else {
                           log.error("Can not generate the VM config spec"
                                    + " to connect to the DVPort");
                        }
                     } else {
                        setUpDone = false;
                        log.error("Could not create portgroup");
                     }
                  } else {
                     setUpDone = false;
                     log.error("There are no ethernet cards configured "
                              + "on the vm");
                  }
               } else {
                  setUpDone = false;
                  log.error("The vm does not have any ethernet"
                           + " cards configured");
               }
            } else {
               log.error("The vm state could not be configured");
            }
         } else {
            setUpDone = false;
            log.error("The vm mor object is null");
         }
      } else {
         setUpDone = false;
         log.error("Can not find any vm's on the host");
      }
      assertTrue(setUpDone, "Setup failed");
      return setUpDone;
   }
}
