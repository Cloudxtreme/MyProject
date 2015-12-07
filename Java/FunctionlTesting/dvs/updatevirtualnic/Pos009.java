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
import com.vmware.vc.HostInternetScsiHbaDigestProperties;
import com.vmware.vc.HostInternetScsiHbaDigestType;
import com.vmware.vc.HostInternetScsiHbaSendTarget;
import com.vmware.vc.HostInternetScsiHbaStaticTarget;
import com.vmware.vc.HostInternetScsiHbaTargetSet;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.HostVirtualNicConfig;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.StorageHelper;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.host.StorageSystem;

import dvs.VNicBase;

/**
 * Update an existing vmkernal nics to connect to an standalone port on an
 * existing DVSwitch. The distributedVirtualPort is of type DVSPortConnection.
 * Update the Digest properties valid hba id, valid targetSet and valid digest
 * properties (only dataDigest is set)
 */
public class Pos009 extends VNicBase
{
   private String dvSwitchUuid = null;
   private HostVirtualNicSpec origVnicSpec = null;
   private String vNicdevice = null;
   private String portKey = null;
   private HostSystem ihs = null;
   private StorageSystem iscsi = null;
   private ManagedObjectReference hostMor = null;
   private ManagedObjectReference storageSystemMor = null;
   private HostInternetScsiHbaDigestProperties orgHbaDigestProperties = null;
   private String iscsiHbaId = null;
   private boolean isScsiDigestPropertiesChanged = false;
   private HostInternetScsiHbaSendTarget[] orgSendTargets = null;
   private HostInternetScsiHbaStaticTarget[] orgStaticTargets = null;
   private HostInternetScsiHba orgHba = null;
   private HostInternetScsiHbaDigestProperties orgStaticDigestProperties = null;
   private final String[] digestType = {
            HostInternetScsiHbaDigestType.DIGEST_PREFERRED.value(), HostInternetScsiHbaDigestType.DIGEST_REQUIRED.value(), HostInternetScsiHbaDigestType.DIGEST_DISCOURAGED.value(), HostInternetScsiHbaDigestType.DIGEST_PROHIBITED.value() };
   private HostInternetScsiHbaTargetSet orgtargetSet = null;

   @SuppressWarnings("deprecation")
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
      ihs = new HostSystem(connectAnchor);
      hostMor = ihs.getConnectedHost(null);
      assertNotNull(hostMor, HOST_GET_PASS, HOST_GET_FAIL);
      log.info("Got host: {} ", ihs.getHostName(hostMor));
      iscsi = new StorageSystem(connectAnchor);
      storageSystemMor = iscsi.getStorageSystem(hostMor);
      orgtargetSet = new HostInternetScsiHbaTargetSet();
      final String[] freePnics = ins.getPNicIds(hostMor);
      assertNotEmpty(freePnics, "No free pnics are found");
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
      ins.refresh(nwSystemMor);
      log.info("Successfully created the distributed virtual switch");
      final HostNetworkConfig nwCfg = ins.getNetworkConfig(nwSystemMor);
      assertNotEmpty(com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class), "Failed to get a VNIC");
      final HostVirtualNicConfig vnicConfig = com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0];
      origVnicSpec = vnicConfig.getSpec();
      vNicdevice = vnicConfig.getDevice();
      log.info("VnicDevice : " + vNicdevice);
      portCriteria = iDVSwitch.getPortCriteria(false, null, null, null, null,
               false);
      portCriteria.setUplinkPort(false);
      portKeys = iDVSwitch.fetchPortKeys(dvsMor, portCriteria);
      assertNotEmpty(portKeys, "Failed to get ports");
      portKey = portKeys.get(0);
      orgHba = iscsi.getiScsiHba(storageSystemMor,
               TestConstants.ADAPTER_TYPE_SOFTWARE);
      assertNotNull(orgHba, "Found adapter " + orgHba.getDevice(),
               "No software iSCSI adapter found");
      orgSendTargets = com.vmware.vcqa.util.TestUtil.vectorToArray(orgHba.getConfiguredSendTarget(), com.vmware.vc.HostInternetScsiHbaSendTarget.class);
      iscsiHbaId = orgHba.getDevice();
      log.info("Adding necvessary targets if not present");
      boolean targetsAdded = false;
      final HostInternetScsiHbaSendTarget[] tempSendTarget = { new HostInternetScsiHbaSendTarget() };
      tempSendTarget[0].setAddress(TestConstants.HOST_INTERNET_SCSI_HBA_IP_ADDRESS1);
      tempSendTarget[0].setPort(new Integer(
               TestConstants.HOST_INTERNET_SCSI_HBA_DEFAULT_PORT));
      if (!StorageHelper.sendTargetExists(orgSendTargets, tempSendTarget[0])) {
         iscsi.addInternetScsiSendTargets(storageSystemMor, iscsiHbaId,
                  tempSendTarget);
         targetsAdded = true;
      }
      if (targetsAdded) {
         iscsi.rescanHba(storageSystemMor, iscsiHbaId);
         orgHba = (HostInternetScsiHba) iscsi.getHba(storageSystemMor,
                  iscsiHbaId);
      }
      orgSendTargets = com.vmware.vcqa.util.TestUtil.vectorToArray(orgHba.getConfiguredSendTarget(), com.vmware.vc.HostInternetScsiHbaSendTarget.class);
      orgStaticTargets = com.vmware.vcqa.util.TestUtil.vectorToArray(orgHba.getConfiguredStaticTarget(), com.vmware.vc.HostInternetScsiHbaStaticTarget.class);
      if (orgStaticTargets != null) {
         orgStaticDigestProperties = orgStaticTargets[0].getDigestProperties();
      }
      iscsiHbaId = orgHba.getDevice();
      orgHbaDigestProperties = orgHba.getDigestProperties();
      return true;
   }

   @Override
   @Test(description = "Update an existing  vmkernal  nics  to connect to an"
            + " standalone port on an existing DVSwitch. "
            + "The distributedVirtualPort is of type DVSPortConnection. "
            + "Update the Digest properties valid hba id, valid targetSet"
            + " and valid digest properties (only dataDigest is set")
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
      updatedVNicSpec = (HostVirtualNicSpec) TestUtil.deepCopyObject(origVnicSpec);
      updatedVNicSpec.setDistributedVirtualPort(portConnection);
      updatedVNicSpec.setPortgroup(null);
      if (ins.updateVirtualNic(nwSystemMor, vNicdevice, updatedVNicSpec)) {
         log.info("Successfully updated VirtualNic " + vNicdevice);
         final HostInternetScsiHbaDigestProperties tempDigestProperties = new HostInternetScsiHbaDigestProperties();
         tempDigestProperties.setDataDigestInherited(false);
         tempDigestProperties.setHeaderDigestInherited(false);
         for (int i = 0; i < digestType.length; i++) {
            log.info("Updating with digestType = " + digestType[i]);
            log.info("***************************************");
            tempDigestProperties.setHeaderDigestType(digestType[i]);
            tempDigestProperties.setDataDigestType(digestType[i]);
            HostInternetScsiHbaTargetSet tempTargetSet = new HostInternetScsiHbaTargetSet();
            final HostInternetScsiHbaSendTarget[] sendTargetsArray = new HostInternetScsiHbaSendTarget[1];
            final HostInternetScsiHbaStaticTarget[] staticTargetsArray = new HostInternetScsiHbaStaticTarget[1];
            if ((orgSendTargets != null) && (orgStaticTargets != null)) {
               sendTargetsArray[0] = orgSendTargets[0];
               tempTargetSet.getSendTargets().clear();
               tempTargetSet.getSendTargets().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(sendTargetsArray));
               staticTargetsArray[0] = orgStaticTargets[0];
               tempTargetSet.getStaticTargets().clear();
               tempTargetSet.getStaticTargets().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(staticTargetsArray));
            } else if ((orgSendTargets != null) && (orgStaticTargets == null)) {
               sendTargetsArray[0] = orgSendTargets[0];
               tempTargetSet.getSendTargets().clear();
               tempTargetSet.getSendTargets().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(sendTargetsArray));
            } else if ((orgSendTargets == null) && (orgStaticTargets != null)) {
               staticTargetsArray[0] = orgStaticTargets[0];
               tempTargetSet.getStaticTargets().clear();
               tempTargetSet.getStaticTargets().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(staticTargetsArray));
            } else {
               tempTargetSet = null;
            }
            if (iscsi.updateInternetScsiDigestProperties(storageSystemMor,
                     iscsiHbaId, tempTargetSet, tempDigestProperties)) {
               log.info("Digest properties updated successfully");
               status = true;
               isScsiDigestPropertiesChanged = true;
            } else {
               status = false;
               log.info("Failed to update Digest properties");
               break;
            }
         }
      } else {
         log.info("Unable to update VirtualNic " + vNicdevice);
         status = false;
      }
      assertTrue(status, "Test Failed");
   }

   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;
      final boolean sendCleanupDone = true;
      boolean staticCleanupDone = true;
      boolean hbaCleanupDone = true;
      try {
         if (isScsiDigestPropertiesChanged) {
            // Needs to put back original authentication prop for the
            // sendTarget
            // staticTarget and the hostBusAdapter.
            // We cannot do all at once. So we need to update each at a time
            // put back sendTarget authentication properties
            final HostInternetScsiHbaStaticTarget[] staticTargetsArray = new HostInternetScsiHbaStaticTarget[1];
            /*
             * if (orgSendTargets != null) { orgtargetSet = new
             * HostInternetScsiHbaTargetSet(); sendTargetsArray[0] =
             * orgSendTargets[0]; orgtargetSet.setSendTargets(sendTargetsArray);
             * //orgtargetSet.setSendTargets(0, orgSendTargets[0]); if
             * (iscsi.updateInternetScsiDigestProperties(storageSystemMor,
             * iscsiHbaId, orgtargetSet, orgSendDigestProperties)) {
             * log.info("Successfully updated original sendTarget digest " +
             * "properties"); } else { sendCleanupDone = false;
             * log.info("Failed to update original sendTarget " +
             * "digest properties"); } }
             */
            // put back staticTarget options
            if (orgStaticTargets != null) {
               orgtargetSet = new HostInternetScsiHbaTargetSet();
               staticTargetsArray[0] = orgStaticTargets[0];
               orgtargetSet.getStaticTargets().clear();
               orgtargetSet.getStaticTargets().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(staticTargetsArray));
               // orgtargetSet.setStaticTargets(0, orgStaticTargets[0]);
               if (iscsi.updateInternetScsiDigestProperties(storageSystemMor,
                        iscsiHbaId, orgtargetSet, orgStaticDigestProperties)) {
                  log.info("Successfully updated original staticTarget digest "
                           + "properties");
               } else {
                  staticCleanupDone = false;
                  log.info("Failed to update original digest properties");
               }
            }
            // put back Hba Advanced Options
            if (iscsi.updateInternetScsiDigestProperties(storageSystemMor,
                     iscsiHbaId, null, orgHbaDigestProperties)) {
               log.info("Successfully updated original hba digest properties");
            } else {
               hbaCleanupDone = false;
               log.info("Failed to update original digest properties");
            }
            if (sendCleanupDone && staticCleanupDone && hbaCleanupDone) {
               status = true;
            }
         }
      } catch (final Exception ex) {
         TestUtil.handleException(ex);
         status = false;
      }
      try {
         if (origVnicSpec != null) {
            if (ins.updateVirtualNic(nwSystemMor, vNicdevice, origVnicSpec)) {
               log.info("Successfully restored original VirtualNic "
                        + "config: " + vNicdevice);
            } else {
               log.info("Unable to update VirtualNic " + vNicdevice);
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
