/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.updatevirtualnic;

import static com.vmware.vcqa.util.Assert.*;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

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
import com.vmware.vc.HostInternetScsiHba;
import com.vmware.vc.HostInternetScsiHbaSendTarget;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.HostVirtualNicConfig;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.host.StorageSystem;

import dvs.VNicBase;

/**
 * Update an existing nic to connect to an standalone port on an existing
 * DVSwitch. The distributedVirtualPort is of type DVSPortConnection. Add
 * Internet Scsi Send Target with valid hba id and 1 valid target by specifying
 * the port of the target
 */
public class Pos005 extends VNicBase
{
   private String dvSwitchUuid = null;
   private HostVirtualNicSpec origVnicSpec = null;
   private String vNicdevice = null;
   boolean updated = false;
   private String portKey = null;
   private StorageSystem iscsi = null;
   private ManagedObjectReference storageSystemMor = null;
   HostInternetScsiHba iScsiHba = null;
   private String iscsiHbaId = null;
   private final int SCSI_SEND_TARGET_SIZE = 1;
   private final HostInternetScsiHbaSendTarget sendTarget[] = new HostInternetScsiHbaSendTarget[SCSI_SEND_TARGET_SIZE];
   private boolean isScsiSendTargetAdded = false;
   private HostInternetScsiHba internetScsiHba = null;
   private int noOfLunsBeforeAddingTargets = 0;
   private int noOfLunsAfterAddingTargets = 0;
   private int noOfLunsAfterRemovingTargets = 0;
   private String hostName = null;

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Update an existing   nic to connect to an "
               + "standalone port on an existing DVSwitch. "
               + "The distributedVirtualPort is of type DVSPortConnection.\n"
               + "Add Internet Scsi Send Target with valid hba id and 1 valid"
               + " target by specifying the port of the target");
   }

   /**
    * Method to setup the environment for the test.
    *
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if setup is successful.
    */
   @Override
   @BeforeMethod(alwaysRun = true)
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
         final Set hostsSet = allHosts.keySet();
         if ((hostsSet != null) && (hostsSet.size() > 0)) {
            final Iterator hostsItr = hostsSet.iterator();
            if (hostsItr.hasNext()) {
               hostMor = (ManagedObjectReference) hostsItr.next();
            }
         }
         if (hostMor != null) {
            hostName = ihs.getName(hostMor);
            iscsi = new StorageSystem(connectAnchor);
            storageSystemMor = iscsi.getStorageSystem(hostMor);
            /*
             * Check for free Pnics
             */
            final String[] freePnics = ins.getPNicIds(hostMor);
            if ((freePnics != null) && (freePnics.length > 0)) {
               nwSystemMor = ins.getNetworkSystem(hostMor);
               if (nwSystemMor != null) {
                  hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
                  hostMember.setOperation(TestConstants.CONFIG_SPEC_ADD);
                  hostMember.setHost(hostMor);
                  pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                  pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                  pnicSpec.setPnicDevice(freePnics[0]);
                  pnicBacking.getPnicSpec().clear();
                  pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
                  hostMember.setBacking(pnicBacking);
                  dvsConfigSpec = new DVSConfigSpec();
                  dvsConfigSpec.setConfigVersion("");
                  dvsConfigSpec.setName(getTestId());
                  dvsConfigSpec.setNumStandalonePorts(1);
                  dvsConfigSpec.getHost().clear();
                  dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMember }));
                  dvsMor = iFolder.createDistributedVirtualSwitch(
                           iFolder.getNetworkFolder(iFolder.getDataCenter()),
                           dvsConfigSpec);
                  if ((dvsMor != null)
                           && ins.refresh(nwSystemMor)
                           && iDVSwitch.validateDVSConfigSpec(dvsMor,
                                    dvsConfigSpec, null)) {
                     log.info("Successfully created the distributed "
                              + "virtual switch");
                     /*
                      * Get existing vnics
                      */
                     final HostNetworkConfig nwCfg = ins.getNetworkConfig(nwSystemMor);
                     if ((nwCfg != null) && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class) != null)
                              && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class).length > 0)
                              && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0] != null)) {
                        final HostVirtualNicConfig vnicConfig = com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0];
                        origVnicSpec = vnicConfig.getSpec();
                        vNicdevice = vnicConfig.getDevice();
                        log.info("VnicDevice : " + vNicdevice);
                        portCriteria = iDVSwitch.getPortCriteria(false,
                                 null, null, null, null, false);
                        portCriteria.setUplinkPort(false);
                        portKeys = iDVSwitch.fetchPortKeys(dvsMor,
                                 portCriteria);
                        if ((portKeys != null) && (portKeys.size() > 0)) {
                           portKey = portKeys.get(0);
                           if (storageSystemMor != null) {
                              //
                              internetScsiHba = iscsi.getiScsiHba(
                                       storageSystemMor,
                                       TestConstants.ADAPTER_TYPE_SOFTWARE);
                              iscsiHbaId = internetScsiHba.getDevice();
                              log.info("iScsiHba found " + "= " + iscsiHbaId);
                              status = true;
                              //
                           } else {
                              log.error("Unable to find the"
                                       + " storage system mor");
                           }
                        }
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
   @Override
   @Test(description = "Update an existing   nic to connect to an "
            + "standalone port on an existing DVSwitch. "
            + "The distributedVirtualPort is of type DVSPortConnection.\n"
            + "Add Internet Scsi Send Target with valid hba id and 1 valid"
            + " target by specifying the port of the target")
   public void test()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchPortConnection portConnection = null;
      final HostVirtualNic vNic = null;
      HostVirtualNicSpec updatedVNicSpec = null;
      log.info("test setup Begin:");
      final DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
      dvSwitchUuid = info.getUuid();
      portConnection = new DistributedVirtualSwitchPortConnection();
      portConnection.setSwitchUuid(dvSwitchUuid);
      portConnection.setPortKey(portKey);
      if (portConnection != null) {
         updatedVNicSpec = (HostVirtualNicSpec) TestUtil.deepCopyObject(origVnicSpec);
         updatedVNicSpec.setDistributedVirtualPort(portConnection);
         updatedVNicSpec.setPortgroup(null);
         if (ins.updateVirtualNic(nwSystemMor, vNicdevice, updatedVNicSpec)) {
            log.info("Successfully updated VirtualNic " + vNicdevice);
            for (int i = 0; i < SCSI_SEND_TARGET_SIZE; i++) {
               sendTarget[i] = new HostInternetScsiHbaSendTarget();
               sendTarget[i].setAddress(TestConstants.HOST_INTERNET_SCSI_HBA_IP_ADDRESS1);
               sendTarget[i].setPort(new Integer(
                        TestConstants.HOST_INTERNET_SCSI_HBA_DEFAULT_PORT));
            }
            noOfLunsBeforeAddingTargets = iscsi.getNumberOfStorageDevicesForHba(
                     storageSystemMor, iscsiHbaId);
            log.info("No. of Luns before adding targets = "
                     + noOfLunsBeforeAddingTargets);
            if (iscsi.addInternetScsiSendTargets(storageSystemMor, iscsiHbaId,
                     sendTarget)) {
               isScsiSendTargetAdded = true;
               log.info("Send Targets added sucessfully");
               iscsi.rescanHba(storageSystemMor, iscsiHbaId);
               log.info("Rescanned Hba successfully");
               noOfLunsAfterAddingTargets = iscsi.getNumberOfStorageDevicesForHba(
                        storageSystemMor, iscsiHbaId);
               log.info("No. of Luns before adding targets = "
                        + noOfLunsBeforeAddingTargets + " No. of Luns "
                        + "after adding targets = "
                        + noOfLunsAfterAddingTargets);
               status = true;
            } else {
               log.error("Unable to add send targets");
               status = false;
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
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         if (isScsiSendTargetAdded) {
            if (iscsi.removeInternetScsiSendTargets(storageSystemMor,
                     iscsiHbaId, sendTarget)) {
               log.info("Successfully removed SendTargets");
               hostMor = ihs.getHost(hostName);
               if (hostMor != null) {
                  storageSystemMor = iscsi.getStorageSystem(hostMor);
                  if (storageSystemMor != null) {
                     noOfLunsAfterRemovingTargets = iscsi.getNumberOfStorageDevicesForHba(
                              storageSystemMor, iscsiHbaId);
                     log.info("No. of Luns before adding targets = "
                              + noOfLunsBeforeAddingTargets + " No. of"
                              + " Luns after removing targets = "
                              + noOfLunsAfterRemovingTargets);
                     if (noOfLunsBeforeAddingTargets == noOfLunsAfterRemovingTargets) {
                        log.info("Luns removed successfully");
                     }
                  } else {
                     log.error("Unable to find the" + " storage system mor");
                     status = false;
                  }
               } else {
                  log.error("Unable to find the host mor");
                  status = false;
               }
            } else {
               log.info("Failed to remove SendTargets");
               status = false;
            }
         }
      } catch (final Exception e) {
         status = false;
         TestUtil.handleException(e);
      }
      try {
         if (origVnicSpec != null) {
            if (ins.updateVirtualNic(nwSystemMor, vNicdevice, origVnicSpec)) {
               log.info("Successfully restored original VirtualNic "
                        + "config: " + vNicdevice);
            } else {
               log.error("Unable to update VirtualNic " + vNicdevice);
               status = false;
            }
         }
      } catch (final Exception e) {
         status = false;
         TestUtil.handleException(e);
      }
      status &= super.testCleanUp();
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
