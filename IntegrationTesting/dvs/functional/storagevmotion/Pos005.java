/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.functional.storagevmotion;

import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_DISK;
import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32;
import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_SCSI_BUSL_CONTROLLER;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import java.util.ArrayList;
import java.util.List;
import java.util.Vector;

import org.testng.annotations.BeforeMethod;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualDeviceFileBackingInfo;
import com.vmware.vc.VirtualDisk;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vc.VirtualMachineRelocateSpec;
import com.vmware.vc.VirtualMachineRelocateSpecDiskLocator;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.Datastore;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.VMSpecManager;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.DatastoreInformation;
import com.vmware.vcqa.vim.host.VmotionSystem;

/**
 * Storage vmotion a powered on VM which has multiple disks that are on multiple
 * datastores via a vmotion virtual nic that is connected to a port in an early
 * binding portgroup of the DVSwitch. The disks are relocated to the destination
 * datastores.
 */
public class Pos005 extends SVMFunctionalTestBase
{

   private Datastore ids = null;
   private String hostName = null;

   public void setTestDescription()
   {
      setTestDescription("Storage vmotion a powered on VM which has multiple "
               + "disks that are on multiple data stores to move the"
               + " disks from one datastore to another via a vmotion"
               + " virtual nic that is connected to a port in an "
               + "earlybinding dvport of the DVSwitch");
   }

   /**
    * Method to set up the Environment for the test.
    * 
    * @param connectAnchor Reference to the ConnectAnchor object.
    * @return Return true, if test set up was sucessful false, if test set up
    *         was not sucessful
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean setupDone = false;
      String portgroupKey = null;
      DVSConfigInfo configInfo = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      VirtualMachineConfigSpec vmConfigSpec = null;
      HostVirtualNic vmotionNic = null;
      HostVirtualNicSpec updatedVnicSpec = null;
      VirtualDeviceConfigSpec[] deviceConfigSpec = null;
      List<VirtualMachineRelocateSpecDiskLocator> diskLocatorList = new ArrayList<VirtualMachineRelocateSpecDiskLocator>();
      VirtualMachineRelocateSpecDiskLocator diskLocator = null;
      VirtualDisk vdisk = null;
      VirtualDeviceFileBackingInfo fileBacking = null;
      Vector<Integer> diskIDs = null;

         if (super.testSetUp()) {
            this.iVmotionSystem = new VmotionSystem(connectAnchor);
            this.ids = new Datastore(connectAnchor);
            this.vmotionSystem = this.iVmotionSystem.getVMotionSystem(this.hostMor);
            hostName = this.ihs.getHostName(this.hostMor);
            if (this.vmotionSystem != null) {
               configInfo = this.iDVS.getConfig(this.dvsMor);
               portgroupKey = this.iDVS.addPortGroup(this.dvsMor,
                        DVPORTGROUP_TYPE_EARLY_BINDING, 2, this.getTestId()
                                 + "-epg");
               if (portgroupKey != null) {
                  portConnection = new DistributedVirtualSwitchPortConnection();
                  portConnection.setPortgroupKey(portgroupKey);
                  portConnection.setSwitchUuid(configInfo.getUuid());
                  portConnection.setPortKey(this.iDVS.getFreePortInPortgroup(
                           this.dvsMor, portgroupKey, null));
                  vmConfigSpec = DVSUtil.buildCreateVMCfg(connectAnchor,
                           portConnection, VM_VIRTUALDEVICE_ETHERNET_PCNET32,
                           this.getTestId() + "-VM", this.hostMor);
                  if (vmConfigSpec != null) {
                     vmConfigSpec = addVirtualDisk(vmConfigSpec);
                     if (vmConfigSpec != null) {
                        this.vmMor = new Folder(super.getConnectAnchor()).createVM(
                                 this.ivm.getVMFolder(), vmConfigSpec,
                                 this.ihs.getResourcePool(this.hostMor).get(0),
                                 this.hostMor);
                        if (this.vmMor != null) {
                           this.vmName = this.ivm.getName(this.vmMor);
                           vmConfigSpec = this.ivm.getVMConfigSpec(this.vmMor);
                           deviceConfigSpec = com.vmware.vcqa.util.TestUtil.vectorToArray(vmConfigSpec.getDeviceChange(), com.vmware.vc.VirtualDeviceConfigSpec.class);
                           diskIDs = this.ivm.getDeviceInfo(this.vmMor,
                                    VM_VIRTUALDEVICE_DISK);
                           if (diskIDs != null && diskIDs.size() == 2) {
                              for (Integer diskID : diskIDs) {
                                 for (VirtualDeviceConfigSpec vdConfigSpec : deviceConfigSpec) {
                                    if (vdConfigSpec.getDevice() != null
                                             && vdConfigSpec.getDevice() instanceof VirtualDisk) {
                                       vdisk = (VirtualDisk) vdConfigSpec.getDevice();
                                       if (vdisk.getKey() != diskID.intValue()
                                                && vdisk.getBacking() instanceof VirtualDeviceFileBackingInfo) {
                                          fileBacking = (VirtualDeviceFileBackingInfo) vdisk.getBacking();
                                          diskLocator = new VirtualMachineRelocateSpecDiskLocator();
                                          diskLocator.setDiskId(diskID);
                                          diskLocator.setDatastore(fileBacking.getDatastore());
                                          diskLocatorList.add(diskLocator);
                                          break;
                                       } else {
                                          continue;
                                       }
                                    }
                                 }
                              }
                           }
                           if (diskLocatorList.size() == 2) {
                              this.vmRelocateSpec = new VirtualMachineRelocateSpec();
                              this.vmRelocateSpec.getDisk().clear();
                              this.vmRelocateSpec.getDisk().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(diskLocatorList.toArray(new VirtualMachineRelocateSpecDiskLocator[diskLocatorList.size()])));
                              if (this.ivm.setVMState(this.vmMor, VirtualMachinePowerState.POWERED_ON, false)) {
                                 log.info("Successfully powered on the VM "
                                          + this.vmName);
                                 portConnection = new DistributedVirtualSwitchPortConnection();
                                 portConnection.setSwitchUuid(configInfo.getUuid());
                                 portConnection.setPortgroupKey(portgroupKey);
                                 portConnection.setPortKey(this.iDVS.getFreePortInPortgroup(
                                         this.dvsMor, portgroupKey, null));
                                 vnicDevice = DVSUtil.addVnic(connectAnchor, hostMor, portConnection);
                                 if (vnicDevice != null) {
                                     boolean status = iVmotionSystem.selectVnic(vmotionSystem,
                                         vnicDevice);
                                     if (status) {
                                        log.info("Successfully selected the added vnic to be "
                                                 + "vmotion virtual nic");
                                        setupDone = true;
                                     }
                                 }
                              } else {
                                 log.error("Can not power on the VM "
                                          + this.vmName);
                              }
                           }
                        } else {
                           log.error("Can not create a new VM");
                        }
                     } else {
                        log.error("Cannot obtain the new VM config spec to "
                                 + "add the disk");
                     }
                  } else {
                     log.error("Can not create a new virtual machine config "
                              + "spec");
                  }
               } else {
                  log.error("There are no standalone dv ports on the DVS");
               }
            }
         }
     
      Assert.assertTrue(setupDone, "Setup failed");
      return setupDone;
   }

   /**
    * Method to add an extra virtual disk in a different datastore to that of
    * the disk in the config spec passed.
    * 
    * @param vmConfigSpec VirtualMachineConfigSpec with a single disk.
    * @return VirtualMachineConfigSpec
    * @throws MethodFault, Exception
    */
   private VirtualMachineConfigSpec addVirtualDisk(VirtualMachineConfigSpec vmConfigSpec)
      throws Exception
   {
      VMSpecManager vmSpecManager = null;
      boolean deviceAdded = false;
      VirtualDeviceConfigSpec diskDeviceSpec = null;
      Vector<VirtualDeviceConfigSpec> vdConfigSpecVector = null;
      VirtualDisk virtualDisk = null;
      VirtualDeviceFileBackingInfo fileBacking = null;
      DatastoreInformation vmDatastoreInformation = null;
      ManagedObjectReference unusedDataStore = null;
      VirtualDeviceConfigSpec[] vdConfigSpecs = com.vmware.vcqa.util.TestUtil.vectorToArray(vmConfigSpec.getDeviceChange(), com.vmware.vc.VirtualDeviceConfigSpec.class);
      Vector<DatastoreInformation> dataStoresinfo = this.ihs.getDatastoresInfo(this.hostMor);
      if (dataStoresinfo != null && dataStoresinfo.size() >= 2) {
         for (DatastoreInformation dataStoreInfo : dataStoresinfo) {
            if (dataStoreInfo != null) {
               if (vdConfigSpecs != null && vdConfigSpecs.length > 0) {
                  for (VirtualDeviceConfigSpec vdConfigSpec : vdConfigSpecs) {
                     if (vdConfigSpec != null
                              && vdConfigSpec.getDevice() != null
                              && vdConfigSpec.getDevice() instanceof VirtualDisk) {
                        virtualDisk = (VirtualDisk) vdConfigSpec.getDevice();
                        if (virtualDisk.getBacking() != null
                                 && virtualDisk.getBacking() instanceof VirtualDeviceFileBackingInfo) {
                           fileBacking = (VirtualDeviceFileBackingInfo) virtualDisk.getBacking();
                           if (fileBacking != null
                                    && fileBacking.getDatastore() == null) {
                              fileBacking.setDatastore(dataStoreInfo.getDatastoreMor());
                           }
                           vmDatastoreInformation = this.ids.getDatastoreInfo(fileBacking.getDatastore());
                           if (vmDatastoreInformation != null
                                    && vmDatastoreInformation.getName().equals(
                                             dataStoreInfo.getName())) {
                              continue;
                           } else if (dataStoreInfo.isAccessible()
                                           && ids.isDsWritable(dataStoreInfo, hostName, ihs)) {
                              unusedDataStore = dataStoreInfo.getDatastoreMor();
                              break;
                           }
                        }
                     }
                  }
               } else {
                  log.error("The virtual device config spec array is either"
                           + " empty or null");
               }
            } else {
               log.error("The datastore information is null");
            }
         }
      } else {
         log.error("The host does not have multiple datastores "
                  + this.ihs.getHostName(this.hostMor));
      }
      if (unusedDataStore != null) {
         vmSpecManager = this.ivm.getVMSpecManager(this.ihs.getResourcePool(
                  this.hostMor).get(0), this.hostMor);
         diskDeviceSpec = vmSpecManager.createDiskSpec(
                  TestUtil.arrayToVector(vdConfigSpecs), unusedDataStore, 0,
                  VM_VIRTUALDEVICE_SCSI_BUSL_CONTROLLER, false, null);
         if (diskDeviceSpec != null) {
            vdConfigSpecVector = TestUtil.arrayToVector(vdConfigSpecs);
            vdConfigSpecVector.add(diskDeviceSpec);
            vmConfigSpec.getDeviceChange().clear();
            vmConfigSpec.getDeviceChange().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(vdConfigSpecVector.toArray(new VirtualDeviceConfigSpec[vdConfigSpecVector.size()])));
            deviceAdded = true;
         } else {
            log.error("Can not generate the virtual device config spec to "
                     + "add a virtual disk");
         }
      } else {
         log.error("Can not find an unused datastore for the VM");
      }
      if (deviceAdded) {
         return vmConfigSpec;
      } else {
         return null;
      }
   }
}