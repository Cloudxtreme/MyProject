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

import java.util.ArrayList;
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
import com.vmware.vc.HostInternetScsiHbaParamValue;
import com.vmware.vc.HostInternetScsiHbaSendTarget;
import com.vmware.vc.HostInternetScsiHbaStaticTarget;
import com.vmware.vc.HostInternetScsiHbaTargetSet;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostVirtualNicConfig;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.OptionDef;
import com.vmware.vc.OptionType;
import com.vmware.vc.OptionValue;
import com.vmware.vc.UserSession;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.StorageHelper;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.host.StorageSystem;

import dvs.VNicBase;

/**
 * Update an existing vmkernal nics to connect to an standalone port on an
 * existing DVSwitch. The distributedVirtualPort is of type DVSPortConnection.
 * Update with Advanced Options for valid hba id, valid targetSet and valid
 * optionValue
 */
public class Pos007 extends VNicBase
{
   private String dvSwitchUuid = null;
   private HostVirtualNicSpec origVnicSpec = null;
   private String vNicdevice = null;
   boolean updated = false;
   private String portKey = null;
   protected String userName = null;
   protected String password = null;
   protected AuthorizationManager authentication = null;
   protected UserSession loginSession = null;
   protected HostSystem ihs = null;
   protected StorageSystem iscsi = null;
   protected ManagedObjectReference authenticationMor = null;
   protected ManagedObjectReference hostMor = null;
   protected ManagedObjectReference storageSystemMor = null;
   protected OptionValue[] orgHbaAdvOptions = null;
   protected String iscsiHbaId = null;
   protected HostInternetScsiHba orgHba = null;
   protected boolean isScsiAdvOptionsChanged = false;
   protected HostInternetScsiHbaSendTarget[] orgSendTargets = null;
   protected HostInternetScsiHbaStaticTarget[] orgStaticTargets = null;
   protected OptionValue[] orgSendTargetAdvOptions = null;
   protected OptionValue[] orgStaticTargetAdvOptions = null;
   protected HostInternetScsiHbaTargetSet orgtargetSet = null;
   protected String iScsiHbaName = null;
   protected StorageSystem ss = null;

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
      ss = new StorageSystem(connectAnchor);
      hostMor = ihs.getConnectedHost(null);
      assertNotNull(hostMor, HOST_GET_PASS, HOST_GET_FAIL);
      log.info("Got host: {} ", ihs.getHostName(hostMor));
      iscsi = new StorageSystem(connectAnchor);
      storageSystemMor = ss.getStorageSystem(hostMor);
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
      assertNotEmpty(orgSendTargets, "Send Targets are empty");
      assertNotEmpty(orgStaticTargets, "Static Targets are empty");
      orgSendTargetAdvOptions = com.vmware.vcqa.util.TestUtil.vectorToArray(orgSendTargets[0].getAdvancedOptions(), com.vmware.vc.HostInternetScsiHbaParamValue.class);
      assertNotEmpty(orgSendTargetAdvOptions,
               "Send Target Adv Options are empty");
      orgStaticTargetAdvOptions = com.vmware.vcqa.util.TestUtil.vectorToArray(orgStaticTargets[0].getAdvancedOptions(), com.vmware.vc.HostInternetScsiHbaParamValue.class);
      assertNotEmpty(orgStaticTargetAdvOptions,
               "Static Target AdvOptions are empty");
      iscsiHbaId = orgHba.getDevice();
      iScsiHbaName = orgHba.getIScsiName();
      orgHbaAdvOptions = com.vmware.vcqa.util.TestUtil.vectorToArray(orgHba.getAdvancedOptions(), com.vmware.vc.HostInternetScsiHbaParamValue.class);
      return true;
   }

   @Override
   @Test(description = " Update an existing  vmkernal  nics  to connect"
            + " to an standalone port  on an existing DVSwitch. "
            + " The distributedVirtualPort is of type  DVSPortConnection."
            + " Update with Advanced Options for valid hba id, valid targetSet"
            + " and valid  optionValue")
   public void test()
      throws Exception
   {
      DistributedVirtualSwitchPortConnection portConnection = null;
      HostVirtualNicSpec updatedVNicSpec = null;
      final ArrayList<OptionValue> tempArrayOfOptions = new ArrayList<OptionValue>();
      final HostInternetScsiHbaTargetSet tempTargetSet = new HostInternetScsiHbaTargetSet();
      final HostInternetScsiHbaSendTarget[] sendTargetsArray = new HostInternetScsiHbaSendTarget[1];
      final HostInternetScsiHbaStaticTarget[] staticTargetsArray = new HostInternetScsiHbaStaticTarget[1];
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
               "Failed to updare vNic");
      log.info("Successfully updated VirtualNic {}", vNicdevice);
      /**
       * This test updates upto two non-readonly options to null
       */
      final OptionDef[] sendTargetSupportedOptions = com.vmware.vcqa.util.TestUtil.vectorToArray(orgSendTargets[0].getSupportedAdvancedOptions(), com.vmware.vc.OptionDef.class);
      if (sendTargetSupportedOptions != null) {
         for (int i = 0; i < sendTargetSupportedOptions.length; i++) {
            final OptionType opType = sendTargetSupportedOptions[i].getOptionType();
            if ((opType != null) && !opType.isValueIsReadonly()) {
               final OptionValue optVal = new OptionValue();
               final String optionKey = sendTargetSupportedOptions[i].getKey();
               if (StorageHelper.IsSettableKey(optionKey)) {
                  log.info("**************************optionKey = " + optionKey);
                  optVal.setKey(optionKey);
                  if (optionKey.equals(TestConstants.ADV_OPT_MAX_OUTSTANDING_R2T)) {
                     optVal.setValue(new Integer(StorageHelper.assignValue(
                              optionKey, orgHba).intValue()));
                     log.info("**************optionValue = "
                              + optVal.getValue());
                  } else {
                     optVal.setValue(StorageHelper.assignValue(optionKey,
                              orgHba));
                     log.info("**************optionValue = "
                              + optVal.getValue());
                  }
                  tempArrayOfOptions.add(optVal);
               }
            }
         }
         sendTargetsArray[0] = orgSendTargets[0];
         tempTargetSet.getSendTargets().clear();
         tempTargetSet.getSendTargets().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(sendTargetsArray));
      }
      final OptionDef[] staticTargetSupportedOptions = com.vmware.vcqa.util.TestUtil.vectorToArray(orgStaticTargets[0].getSupportedAdvancedOptions(), com.vmware.vc.OptionDef.class);
      if (staticTargetSupportedOptions != null) {
         for (int i = 0; i < staticTargetSupportedOptions.length; i++) {
            final OptionType opType = staticTargetSupportedOptions[i].getOptionType();
            if ((opType != null) && !opType.isValueIsReadonly()) {
               final OptionValue optVal = new OptionValue();
               final String optionKey = staticTargetSupportedOptions[i].getKey();
               log.info("*********************optionKey = " + optionKey);
               if (StorageHelper.IsSettableKey(optionKey)) {
                  optVal.setKey(optionKey);
                  if (optionKey.equals(TestConstants.ADV_OPT_MAX_OUTSTANDING_R2T)) {
                     optVal.setValue(new Integer(StorageHelper.assignValue(
                              optionKey, orgHba).intValue()));
                     log.info("**************optionValue = "
                              + optVal.getValue());
                  } else {
                     optVal.setValue(StorageHelper.assignValue(optionKey,
                              orgHba));
                     log.info("**************optionValue = "
                              + optVal.getValue());
                  }
                  tempArrayOfOptions.add(optVal);
               }
            }
         }
         staticTargetsArray[0] = orgStaticTargets[0];
         tempTargetSet.getStaticTargets().clear();
         tempTargetSet.getStaticTargets().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(staticTargetsArray));
      }
      final HostInternetScsiHbaParamValue[] paramOptions = new HostInternetScsiHbaParamValue[tempArrayOfOptions.size()];
      for (int k = 0; k < tempArrayOfOptions.size(); k++) {
         final HostInternetScsiHbaParamValue paramOption = new HostInternetScsiHbaParamValue();
         paramOption.setKey(tempArrayOfOptions.get(k).getKey());
         paramOption.setValue(tempArrayOfOptions.get(k).getValue());
         paramOption.setIsInherited(false);
         paramOptions[k] = paramOption;
      }
      assertTrue(iscsi.updateInternetScsiAdvancedOptions(storageSystemMor,
               iscsiHbaId, tempTargetSet, paramOptions), "");
      log.info("Advanced Options updated successfully for iSCSI {}",
               iScsiHbaName);
      isScsiAdvOptionsChanged = true;
   }

   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;
      boolean sendCleanupDone = true;
      boolean staticCleanupDone = true;
      boolean hbaCleanupDone = true;
      try {
         if (isScsiAdvOptionsChanged) {
            OptionValue[] optionValue;
            // optionValue[0] = new OptionValue();
            // Needs to put back original options for the sendTarget
            // staticTarget and the hostBusAdapter.
            // We cannot do all at once. So we need to update each at a time
            // put back sendTarget options
            final HostInternetScsiHbaSendTarget[] sendTargetsArray = new HostInternetScsiHbaSendTarget[1];
            final HostInternetScsiHbaStaticTarget[] staticTargetsArray = new HostInternetScsiHbaStaticTarget[1];
            if (orgSendTargets != null) {
               orgtargetSet = new HostInternetScsiHbaTargetSet();
               sendTargetsArray[0] = orgSendTargets[0];
               orgtargetSet.getSendTargets().clear();
               orgtargetSet.getSendTargets().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(sendTargetsArray));
               optionValue = orgSendTargetAdvOptions;
               final HostInternetScsiHbaParamValue[] paramOptions = new HostInternetScsiHbaParamValue[optionValue.length];
               for (int k = 0; k < optionValue.length; k++) {
                  final HostInternetScsiHbaParamValue paramOption = new HostInternetScsiHbaParamValue();
                  paramOption.setKey(optionValue[k].getKey());
                  paramOption.setValue(optionValue[k].getValue());
                  paramOption.setIsInherited(false);
                  paramOptions[k] = paramOption;
               }
               if (iscsi.updateInternetScsiAdvancedOptions(storageSystemMor,
                        iscsiHbaId, orgtargetSet, paramOptions)) {
                  log.info("Successfully updated original sendTarget options");
               } else {
                  sendCleanupDone = false;
                  log.info("Failed to update original advanced options");
               }
            }
            // put back staticTarget options
            if (orgStaticTargets != null) {
               orgtargetSet = new HostInternetScsiHbaTargetSet();
               staticTargetsArray[0] = orgStaticTargets[0];
               orgtargetSet.getStaticTargets().clear();
               orgtargetSet.getStaticTargets().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(staticTargetsArray));
               optionValue = orgStaticTargetAdvOptions;
               final HostInternetScsiHbaParamValue[] paramOptions = new HostInternetScsiHbaParamValue[optionValue.length];
               for (int k = 0; k < optionValue.length; k++) {
                  final HostInternetScsiHbaParamValue paramOption = new HostInternetScsiHbaParamValue();
                  paramOption.setKey(optionValue[k].getKey());
                  paramOption.setValue(optionValue[k].getValue());
                  paramOption.setIsInherited(false);
                  paramOptions[k] = paramOption;
               }
               if (iscsi.updateInternetScsiAdvancedOptions(storageSystemMor,
                        iscsiHbaId, orgtargetSet, paramOptions)) {
                  log.info("Successfully updated original staticTarget options");
               } else {
                  staticCleanupDone = false;
                  log.info("Failed to update original advanced options");
               }
            }
            // put back Hba Advanced Options
            optionValue = orgHbaAdvOptions;
            final HostInternetScsiHbaParamValue[] paramOptions = new HostInternetScsiHbaParamValue[optionValue.length];
            for (int k = 0; k < optionValue.length; k++) {
               final HostInternetScsiHbaParamValue paramOption = new HostInternetScsiHbaParamValue();
               paramOption.setKey(optionValue[k].getKey());
               paramOption.setValue(optionValue[k].getValue());
               paramOption.setIsInherited(false);
               paramOptions[k] = paramOption;
            }
            if (iscsi.updateInternetScsiAdvancedOptions(storageSystemMor,
                     iscsiHbaId, null, paramOptions)) {
               log.info("Successfully updated original hba advanced options");
            } else {
               hbaCleanupDone = false;
               log.info("Failed to update original advanced options");
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
