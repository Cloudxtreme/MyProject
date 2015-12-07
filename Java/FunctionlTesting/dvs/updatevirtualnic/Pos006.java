/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.updatevirtualnic;

import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;

import java.util.List;

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
import com.vmware.vc.HostInternetScsiHbaStaticTarget;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostVirtualNicConfig;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.host.StorageSystem;
import com.vmware.vcqa.vim.host.StorageSystemHbaHelper;

import dvs.VNicBase;

/**
 * Update an existing nic to connect to an standalone port on an existing
 * DVSwitch. The distributedVirtualPort is of type DVSPortConnection. Add
 * Internet Scsi static Target with valid hba id and 1 valid target by
 * specifying the port of the target
 */
public class Pos006 extends VNicBase
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
   private final int SCSI_STATIC_TARGET_SIZE = 1;
   private final HostInternetScsiHbaStaticTarget staticTarget[] = new HostInternetScsiHbaStaticTarget[SCSI_STATIC_TARGET_SIZE];
   private HostInternetScsiHba internetScsiHba = null;
   private int noOfLunsBeforeAddingTargets = 0;
   private int noOfLunsAfterAddingTargets = 0;
   private int noOfLunsAfterRemovingTargets = 0;
   private String hostName;
   private boolean isScsiStaticTargetAdded = false;

   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      DVSConfigSpec dvsConfigSpec = null;
      List<String> portKeys = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostMember = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      assertTrue(super.testSetUp(), TB_SETUP_PASS, TB_SETUP_FAIL);
      hostMor = ihs.getConnectedHost(null);
      assertNotNull(hostMor, HOST_GET_PASS, HOST_GET_FAIL);
      hostName = ihs.getName(hostMor);
      log.info("Got Host {}", hostName);
      iscsi = new StorageSystem(connectAnchor);
      storageSystemMor = iscsi.getStorageSystem(hostMor);
      final String[] freePnics = ins.getPNicIds(hostMor);
      assertNotEmpty(freePnics, "No free nics in host " + hostName);
      nwSystemMor = ins.getNetworkSystem(hostMor);
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
               iFolder.getNetworkFolder(iFolder.getDataCenter()), dvsConfigSpec);
      assertNotNull(dvsMor, DVS_CREATE_FAIL);
      log.info("Successfully created the DVS {}", dvsConfigSpec.getName());
      ins.refresh(nwSystemMor);
      /*
       * Get existing vnics
       */
      final HostNetworkConfig nwCfg = ins.getNetworkConfig(nwSystemMor);
      assertNotNull(nwCfg, "Failed to get network config");
      assertNotEmpty(com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class), "Failed to get VNIC");
      final HostVirtualNicConfig vnicConfig = com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0];
      origVnicSpec = vnicConfig.getSpec();
      vNicdevice = vnicConfig.getDevice();
      log.info("VnicDevice : {} ", vNicdevice);
      portCriteria = iDVSwitch.getPortCriteria(false, null, null, null, null,
               false);       
      portCriteria.setUplinkPort(false);
      portKeys = iDVSwitch.fetchPortKeys(dvsMor, portCriteria);
      assertNotEmpty(portKeys, "No ports found in DVS");
      portKey = portKeys.get(0);
      final StorageSystemHbaHelper helper = new StorageSystemHbaHelper(
               connectAnchor, hostMor);
      internetScsiHba = (HostInternetScsiHba) helper.getHbasByType(
               TestConstants.ADAPTER_TYPE_SOFTWARE).get(0);
      iscsiHbaId = internetScsiHba.getDevice();
      log.info("iScsiHba found {} ", iscsiHbaId);
      return true;
   }

   @Override
   @Test(description = "Update an existing   nic to connect to an "
            + "standalone port on an existing DVSwitch. "
            + "The distributedVirtualPort is of type DVSPortConnection.\n"
            + "Add Internet Scsi static  Target with valid hba id and 1 valid"
            + " target by specifying the port of the target")
   public void test()
      throws Exception
   {
      DistributedVirtualSwitchPortConnection portConnection = null;
      HostVirtualNicSpec updatedVNicSpec = null;
      final DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
      dvSwitchUuid = info.getUuid();
      portConnection = new DistributedVirtualSwitchPortConnection();
      portConnection.setSwitchUuid(dvSwitchUuid);
      portConnection.setPortKey(portKey);
      updatedVNicSpec = (HostVirtualNicSpec) TestUtil.deepCopyObject(origVnicSpec);
      updatedVNicSpec.setDistributedVirtualPort(portConnection);
      updatedVNicSpec.setPortgroup(null);
      assertTrue(
               ins.updateVirtualNic(nwSystemMor, vNicdevice, updatedVNicSpec),
               "Failed to update vNic to use DVS");
      log.info("Successfully updated VirtualNic to use DVS");
      for (int i = 0; i < SCSI_STATIC_TARGET_SIZE; i++) {
         staticTarget[i] = new HostInternetScsiHbaStaticTarget();
         staticTarget[i].setAddress(TestConstants.HOST_INTERNET_SCSI_HBA_IP_ADDRESS1);
         staticTarget[i].setPort(new Integer(
                  TestConstants.HOST_INTERNET_SCSI_HBA_DEFAULT_PORT));
         staticTarget[i].setIScsiName(TestConstants.HOST_INTERNET_SCSI_DEFAULT_NAME);
      }
      noOfLunsBeforeAddingTargets = iscsi.getNumberOfStorageDevicesForHba(
               storageSystemMor, iscsiHbaId);
      log.info("No. of Luns before adding targets {}",
               noOfLunsBeforeAddingTargets);
      isScsiStaticTargetAdded = iscsi.addInternetScsiStaticTargets(
               storageSystemMor, iscsiHbaId, staticTarget);
      assertTrue(isScsiStaticTargetAdded, "Failed to add iSCSI target");
      log.info("Static Targets added sucessfully");
      iscsi.rescanHba(storageSystemMor, iscsiHbaId);
      log.info("Rescanned Hba successfully {}", iscsiHbaId);
      noOfLunsAfterAddingTargets = iscsi.getNumberOfStorageDevicesForHba(
               storageSystemMor, iscsiHbaId);
      log.info("No. of Luns before adding targets = "
               + noOfLunsBeforeAddingTargets
               + " No. of Luns after adding targets = "
               + noOfLunsAfterAddingTargets);
   }

   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         if (isScsiStaticTargetAdded) {
            if (iscsi.removeInternetScsiStaticTargets(storageSystemMor,
                     iscsiHbaId, staticTarget)) {
               log.info("Successfully removed SendTargets");
               isScsiStaticTargetAdded = false;
               iscsi.rescanHba(storageSystemMor, iscsiHbaId);
               log.info("Rescanned Hba successfully after removing targets");
               hostMor = ihs.getHost(hostName);
               if (hostMor != null) {
                  storageSystemMor = iscsi.getStorageSystem(hostMor);
                  if (storageSystemMor != null) {
                     noOfLunsAfterRemovingTargets = iscsi.getNumberOfStorageDevicesForHba(
                              storageSystemMor, iscsiHbaId);
                     log.info("No. of Luns before adding targets = "
                              + noOfLunsBeforeAddingTargets
                              + " No. of Luns after removing targets = "
                              + noOfLunsAfterRemovingTargets);
                     if (noOfLunsBeforeAddingTargets == noOfLunsAfterRemovingTargets) {
                        log.info("Luns removed successfully");
                     }
                  } else {
                     log.error("Unable to find the storage system mor");
                     status = false;
                  }
               } else {
                  log.error("Unable to find the host mor");
                  status = false;
               }
            } else {
               log.info("Failed to remove StaticTargets");
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
