/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.updatevirtualnic;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.HostNasVolumeSpec;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.HostVirtualNicConfig;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.host.DatastoreInformation;
import com.vmware.vcqa.vim.host.DatastoreSystem;
import com.vmware.vcqa.vim.host.StorageSystem;
import com.vmware.vcqa.vim.vm.Snapshot;

import dvs.VNicBase;

/**
 * Update an existing vmkernal nics to connect to an standalone port on an
 * existing DVSwitch. The distributedVirtualPort is of type DVSPortConnection.
 * Add 1 NFS Server with 1 single mount point (client Path).� Add a VM using the
 * corresponding datastore and then Poweron the VM, Create Snapshot, Poweroff
 * the VM, Revert the Snapshot and then remove the Snapshot
 */
public class Pos014 extends VNicBase
{
   private String dvSwitchUuid = null;
   private HostVirtualNicSpec origVnicSpec = null;
   private String vNicdevice = null;
   boolean updated = false;
   private String portKey = null;
   private DatastoreSystem iDatastoreSystem = null;
   private StorageSystem iss = null;
   private VirtualMachine ivm = null;
   private ManagedObjectReference datastoreSystemMor = null;
   private ManagedObjectReference datastoreMor = null;
   private ManagedObjectReference snapshotMor = null;
   private ManagedObjectReference vmMor = null;
   private VirtualMachinePowerState initialState = null;
   private boolean created = false;
   private boolean vmCreated = false;
   private boolean snapshotCreated = false;
   private String vmName = null;
   private String datastoreName = getTestId();

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Update an existing  vmkernal  nics  to connect"
               + " to an standalone port on an existing DVSwitch."
               + " The distributedVirtualPort is of type DVSPortConnection.\n "
               + "Add 1 NFS Server with 1 single mount point (client Path)."
               + "Add a VM using the corresponding datastore and then Poweron the VM,"
               + " Create Snapshot, Poweroff the VM, Revert the Snapshot and then "
               + "remove the Snapshot");
   }

   /**
    * Method to setup the environment for the test.
    *
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if setup is successful.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      DVSConfigSpec dvsConfigSpec = null;
      List<String> portKeys = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostMember = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      HashMap allHosts = null;
      log.info("test setup Begin:");
      if (super.testSetUp()) {

            allHosts = ihs.getAllHosts(VersionConstants.ESX4x, HostSystemConnectionState.CONNECTED);
            Set hostsSet = allHosts.keySet();
            if ((hostsSet != null) && (hostsSet.size() > 0)) {
               Iterator hostsItr = hostsSet.iterator();
               if (hostsItr.hasNext()) {
                  hostMor = (ManagedObjectReference) hostsItr.next();
               }
            }
            if (hostMor != null) {
               iss = new StorageSystem(connectAnchor);
               ivm = new VirtualMachine(connectAnchor);
               iDatastoreSystem = new DatastoreSystem(connectAnchor);
               datastoreSystemMor = iDatastoreSystem.getDatastoreSystem(hostMor);
               /*
                * Check for free Pnics
                */
               String[] freePnics = ins.getPNicIds(hostMor);
               if ((freePnics != null) && (freePnics.length > 0)) {
                  nwSystemMor = ins.getNetworkSystem(hostMor);
                  if (nwSystemMor != null) {
                     hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
                     hostMember.setOperation(TestConstants.CONFIG_SPEC_ADD);
                     hostMember.setHost(this.hostMor);
                     pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                     pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                     pnicSpec.setPnicDevice(freePnics[0]);
                     pnicBacking.getPnicSpec().clear();
                     pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
                     hostMember.setBacking(pnicBacking);
                     dvsConfigSpec = new DVSConfigSpec();
                     dvsConfigSpec.setConfigVersion("");
                     dvsConfigSpec.setName(this.getTestId());
                     dvsConfigSpec.setNumStandalonePorts(1);
                     dvsConfigSpec.getHost().clear();
                     dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMember }));
                     this.dvsMor = this.iFolder.createDistributedVirtualSwitch(
                              this.iFolder.getNetworkFolder(this.iFolder.getDataCenter()),
                              dvsConfigSpec);
                     if ((this.dvsMor != null)
                              && this.ins.refresh(this.nwSystemMor)
                              && this.iDVSwitch.validateDVSConfigSpec(
                                       this.dvsMor, dvsConfigSpec, null)) {
                        log.info("Successfully created the distributed "
                                 + "virtual switch");
                        /*
                         * Get existing vnics
                         */
                        HostNetworkConfig nwCfg = ins.getNetworkConfig(nwSystemMor);
                        if ((nwCfg != null) && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class) != null)
                                 && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class).length > 0)
                                 && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0] != null)) {
                           HostVirtualNicConfig vnicConfig = com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0];
                           this.origVnicSpec = vnicConfig.getSpec();
                           vNicdevice = vnicConfig.getDevice();
                           log.info("VnicDevice : " + vNicdevice);
                           portCriteria = this.iDVSwitch.getPortCriteria(false,
                                    null, null, null, null, false);
                           portCriteria.setUplinkPort(false);
                           portKeys = this.iDVSwitch.fetchPortKeys(dvsMor,
                                    portCriteria);
                           if ((portKeys != null) && (portKeys.size() > 0)) {
                              this.portKey = portKeys.get(0);
                           }
                           status = true;
                        } else {
                           log.error("Unable to find valid Vnic");
                        }
                     } else {
                        log.error("Unable to create DistributedVirtualSwitch");
                     }
                  } else {
                     log.error("The network system Mor is null");
                  }
               } else {
                  log.error("Unable to get free pnics");
               }

            } else {
               log.error("Unable to find the host.");
            }

      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test.
    *
    * @param connectAnchor ConnectAnchor.
    */
   @Test(description = "Update an existing  vmkernal  nics  to connect"
               + " to an standalone port on an existing DVSwitch."
               + " The distributedVirtualPort is of type DVSPortConnection.\n "
               + "Add 1 NFS Server with 1 single mount point (client Path)."
               + "Add a VM using the corresponding datastore and then Poweron the VM,"
               + " Create Snapshot, Poweroff the VM, Revert the Snapshot and then "
               + "remove the Snapshot")
   public void test()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchPortConnection portConnection = null;
      HostVirtualNic vNic = null;
      HostVirtualNicSpec updatedVNicSpec = null;
      DatastoreInformation dataInfo = null;
      log.info("test setup Begin:");

         DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
         dvSwitchUuid = info.getUuid();
         portConnection = new DistributedVirtualSwitchPortConnection();
         portConnection.setSwitchUuid(dvSwitchUuid);
         portConnection.setPortKey(this.portKey);
         if (portConnection != null) {
            updatedVNicSpec = (HostVirtualNicSpec) TestUtil.deepCopyObject(this.origVnicSpec);
            updatedVNicSpec.setDistributedVirtualPort(portConnection);
            updatedVNicSpec.setPortgroup(null);
            if (ins.updateVirtualNic(nwSystemMor, vNicdevice, updatedVNicSpec)) {
               log.info("Successfully updated VirtualNic " + vNicdevice);
               HostNasVolumeSpec nasSpec = iDatastoreSystem.createHostNasVolumeSpec(
                        hostMor, datastoreName);
               datastoreMor = iDatastoreSystem.createNasDatastore(
                        datastoreSystemMor, nasSpec);
               if (iDatastoreSystem.dataStoreExists(datastoreSystemMor,
                        datastoreMor)) {
                  created = true;
                  log.info("Successfully created the Nas Datastore");
               } else {
                  log.error("Unable to create the Nas Datastore");
               }
               if (created) {
                  Vector datastoreInfo = ihs.getDatastoresInfo(hostMor);
                  for (int i = 0; i < datastoreInfo.size(); i++) {
                     dataInfo = (DatastoreInformation) datastoreInfo.get(i);
                     if (datastoreName.equalsIgnoreCase(dataInfo.getName())) {
                        log.info("Found Datastore " + datastoreName);
                        break;
                     }
                  }

                  log.info("Attempting to create VM using Datastore "
                           + datastoreName);
                  vmMor = iss.createVirtualMachine(ihs, hostMor, ivm,
                           datastoreName, dataInfo);

                  if (vmMor != null) {
                     log.info("VM creation successfull");
                     vmCreated = true;
                     vmName = ivm.getName(vmMor);
                     initialState = ivm.getVMState(vmMor);

                     if (ivm.setVMState(vmMor, VirtualMachinePowerState.POWERED_ON, false)) {
                        log.info("VM power on success");

                        // Create Snapshot
                        snapshotMor = this.ivm.createSnapshot(this.vmMor,
                                 "name", "description", false, false);
                        if (snapshotMor != null) {
                           log.info("Successfully created snapshot.");
                           snapshotCreated = true;

                           if (ivm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false)) {
                              log.info("VM power off success");
                              // Revert Snapshot
                              boolean makeCurrent = new com.vmware.vcqa.vim.vm.Snapshot(
                                       super.getConnectAnchor()).revertToSnapshot(
                                       snapshotMor, null, false);
                              if (makeCurrent) {
                                 log.info("Successfully made the "
                                          + "snapshot current for VM:" + vmName);

                                 boolean remove = new Snapshot(
                                          super.getConnectAnchor()).removeSnapshot(
                                          snapshotMor, true, false);
                                 if (remove) {
                                    log.info("Successfully removed"
                                             + " snapshot for " + vmName);
                                    snapshotCreated = false;
                                    status = true;
                                 } else {
                                    log.error("Unable to remove "
                                             + "snapshot for " + vmName);
                                 }
                              } else {
                                 log.error("Unable to make the snapshot"
                                          + " current for VM:" + vmName);
                              }
                           } else {
                              log.error("VM power off failed");
                           }
                        } else {
                           log.error("Unable to create snapshot for VM: "
                                    + vmName);
                        }

                     } else {
                        log.error("VM power on failed");
                     }
                  } else {
                     log.error("VM creation failed");
                  }
               }
            } else {
               log.error("Unable to update VirtualNic " + vNicdevice);
               status = false;
            }
         } else {
            status = false;
            log.error("can not get a free port on the dvswitch");
         }

      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started. 1.
    * Migrate the VM back to Source host. 3. Remove the vNic and DVSMor.
    *
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if successful.
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;

         try {
            if (vmCreated) {
               if (ivm.setVMState(vmMor, initialState, false)) {
                  log.info("VM state set to initial state success");

                  if (snapshotCreated) {
                     boolean remove = new Snapshot(super.getConnectAnchor()).removeSnapshot(
                              snapshotMor, true, false);
                     if (remove) {
                        log.info("Successfully removed snapshot for "
                                 + this.vmName);
                     } else {
                        log.error("Unable to remove snapshot for "
                                 + this.vmName);
                        status = false;
                     }
                  }
                  if (ivm.destroy(vmMor)) {
                     log.info("VM destroyed successfully");
                  } else {
                     log.error("VM destroyed failed");
                     status = false;
                  }
               } else {
                  log.error("VM state set to initial state failed");
                  status = false;
               }
            } else {
               log.error("VM creation not successfull. No cleanup"
                        + " required");
               status = false;
            }

            if (created) {
               if (iDatastoreSystem.removeDatastore(datastoreSystemMor,
                        datastoreMor)) {
                  log.info("Sucessfully removed the NAS Datastore");
               } else {
                  log.info("Unable to remove the NAS Datastore");
                  status = false;
               }
            }
         } catch (Exception ex) {
            TestUtil.handleException(ex);
            status = false;
         }
         try {

            if (this.origVnicSpec != null) {
               if (ins.updateVirtualNic(nwSystemMor, vNicdevice, origVnicSpec)) {
                  log.info("Successfully restored original VirtualNic "
                           + "config: " + vNicdevice);
               } else {
                  log.info("Unable to update VirtualNic " + vNicdevice);
                  status = false;
               }
            }
         } catch (Exception e) {
            status = false;
            TestUtil.handleException(e);
         }

         status &= super.testCleanUp();

      assertTrue(status, "Cleanup failed");
      return status;
   }
}
