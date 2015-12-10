/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.updatevirtualnic;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

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
import com.vmware.vc.HostInternetScsiHbaAuthenticationProperties;
import com.vmware.vc.HostInternetScsiHbaSendTarget;
import com.vmware.vc.HostInternetScsiHbaStaticTarget;
import com.vmware.vc.HostInternetScsiHbaTargetSet;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.HostVirtualNicConfig;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.UserSession;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.host.StorageSystem;

import dvs.VNicBase;

/**
 * Update an existing vmkernal nics to connect to an standalone port on an
 * existing DVSwitch. The distributedVirtualPort is of type DVSPortConnection.
 * Update the Authentication properties valid hba id, valid targetSet and chap
 * Auth disabled and chap name and chap secret are null
 */
public class Pos008 extends VNicBase
{
   private String dvSwitchUuid = null;
   private HostVirtualNicSpec origVnicSpec = null;
   private String vNicdevice = null;
   private String portKey = null;

   private UserSession loginSession = null;
   private HostSystem ihs = null;
   private StorageSystem iscsi = null;
   private ManagedObjectReference authenticationMor = null;
   private ManagedObjectReference hostMor = null;
   private ManagedObjectReference storageSystemMor = null;
   private HostInternetScsiHbaAuthenticationProperties orgHbaAuthProperties = null;
   private String iscsiHbaId = null;
   private boolean isScsiAuthPropertiesChanged = false;
   private HostInternetScsiHba orgHba = null;
   private HostInternetScsiHbaSendTarget[] orgSendTargets = null;
   private HostInternetScsiHbaStaticTarget[] orgStaticTargets = null;
   private HostInternetScsiHbaAuthenticationProperties orgSendAuthProperties = null;
   private HostInternetScsiHbaAuthenticationProperties orgStaticAuthProperties = null;
   private String[] chapType = { "chapPreferred" }; // ,"chapPreferred"};//,
   // "discouraged",
   // "encouraged",
   // "chapProhibited" };
   private HostInternetScsiHbaTargetSet orgtargetSet = null;
   private StorageSystem ss = null;

   /**
    * Set test description.
    */
   public void setTestDescription()
   {
      setTestDescription("Update an existing  vmkernal  nics  to connect to"
               + " an standalone port on an existing DVSwitch.\n "
               + "The distributedVirtualPort is of type DVSPortConnection."
               + "Update the Authentication properties valid hba id, "
               + "valid targetSet and chap Auth disabled and chap"
               + " name and chap secret are null");
   }

   /**
    * Method to setup the environment for the test.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if setup is successful.
    */
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
        
            ihs = new HostSystem(connectAnchor);
            ss = new StorageSystem(connectAnchor);
            allHosts = ihs.getAllHosts(VersionConstants.ESX4x, HostSystemConnectionState.CONNECTED);
            Set hostsSet = allHosts.keySet();
            if ((hostsSet != null) && (hostsSet.size() > 0)) {
               Iterator hostsItr = hostsSet.iterator();
               if (hostsItr.hasNext()) {
                  hostMor = (ManagedObjectReference) hostsItr.next();
               }
            }
            if (hostMor != null) {
               iscsi = new StorageSystem(connectAnchor);
               storageSystemMor = ss.getStorageSystem(hostMor);
               orgtargetSet = new HostInternetScsiHbaTargetSet();
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
                           if (storageSystemMor != null) {
                              orgHba = iscsi.getiScsiHba(
                                       storageSystemMor,
                                       data.getString(TestConstants.ADAPTER_TYPE));
                              assertNotNull(
                                       orgHba,
                                       "Found adapter " + orgHba.getDevice(),
                                       "No adapter found of type "
                                                + data.getString(TestConstants.ADAPTER_TYPE));
                              orgSendTargets = com.vmware.vcqa.util.TestUtil.vectorToArray(orgHba.getConfiguredSendTarget(), com.vmware.vc.HostInternetScsiHbaSendTarget.class);
                              if (orgSendTargets != null) {
                                 orgSendAuthProperties = orgSendTargets[0].getAuthenticationProperties();
                              }
                              orgStaticTargets = com.vmware.vcqa.util.TestUtil.vectorToArray(orgHba.getConfiguredStaticTarget(), com.vmware.vc.HostInternetScsiHbaStaticTarget.class);
                              if (orgStaticTargets != null) {
                                 orgStaticAuthProperties = orgStaticTargets[0].getAuthenticationProperties();
                              }
                              iscsiHbaId = orgHba.getDevice();
                              orgHbaAuthProperties = orgHba.getAuthenticationProperties();
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
        
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Test(description = "Update an existing  vmkernal  nics  to connect to"
               + " an standalone port on an existing DVSwitch.\n "
               + "The distributedVirtualPort is of type DVSPortConnection."
               + "Update the Authentication properties valid hba id, "
               + "valid targetSet and chap Auth disabled and chap"
               + " name and chap secret are null")
   public void test()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchPortConnection portConnection = null;
      HostVirtualNic vNic = null;
      HostVirtualNicSpec updatedVNicSpec = null;
      String[] chapType = { "chapPreferred" };
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
               for (int i = 0; i < chapType.length; i++) {
                  HostInternetScsiHbaAuthenticationProperties tempAuthProperties = orgHbaAuthProperties;
                  // orgStaticAuthProperties;
                  // orgHbaAuthProperties;

                  tempAuthProperties.setChapAuthEnabled(true);
                  tempAuthProperties.setChapName("test8");
                  tempAuthProperties.setChapAuthenticationType(chapType[i]);
                  tempAuthProperties.setChapSecret("xyz");
                  tempAuthProperties.setMutualChapAuthenticationType("chapProhibited");

                  HostInternetScsiHbaTargetSet tempTargetSet = new HostInternetScsiHbaTargetSet();

                  HostInternetScsiHbaSendTarget[] sendTargetsArray = new HostInternetScsiHbaSendTarget[1];
                  HostInternetScsiHbaStaticTarget[] staticTargetsArray = new HostInternetScsiHbaStaticTarget[1];
                  if ((orgSendTargets != null) && (orgStaticTargets != null)) {
                     sendTargetsArray[0] = orgSendTargets[0];
                     tempTargetSet.getSendTargets().clear();
                     tempTargetSet.getSendTargets().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(sendTargetsArray));

                  } else if ((orgSendTargets != null)
                           && (orgStaticTargets == null)) {
                     sendTargetsArray[0] = orgSendTargets[0];
                     tempTargetSet.getSendTargets().clear();
                     tempTargetSet.getSendTargets().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(sendTargetsArray));
                  } else if ((orgSendTargets == null)
                           && (orgStaticTargets != null)) {
                     // staticTargetsArray[0] = orgStaticTargets[0];
                     // tempTargetSet.setStaticTargets(staticTargetsArray);
                  } else {
                     tempTargetSet = null;
                  }

                  try {
                     if (iscsi.updateInternetScsiAuthenticationProperties(
                              storageSystemMor, iscsiHbaId, null,
                              tempAuthProperties)) {
                        log.info("Authentication properties updated successfully");
                        status = true;
                        ss.rescanAllHba(storageSystemMor);
                        isScsiAuthPropertiesChanged = true;
                     } else {
                        status = false;
                        log.info("Failed to update authentication properties");
                     }
                  } catch (Exception e) {
                     TestUtil.handleException(e);
                  }
               }
            } else {
               log.info("Unable to update VirtualNic " + vNicdevice);
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
      boolean status = false;
      boolean sendCleanupDone = true;
      boolean staticCleanupDone = true;
      boolean hbaCleanupDone = true;
     
         try {
            if (isScsiAuthPropertiesChanged) {
               // Needs to put back original authentication prop for the
               // sendTarget
               // staticTarget and the hostBusAdapter.
               // We cannot do all at once. So we need to update each at a time
               // put back sendTarget authentication properties
               HostInternetScsiHbaSendTarget[] sendTargetsArray = new HostInternetScsiHbaSendTarget[1];
               HostInternetScsiHbaStaticTarget[] staticTargetsArray = new HostInternetScsiHbaStaticTarget[1];

               if (orgSendTargets != null) {
                  orgtargetSet = new HostInternetScsiHbaTargetSet();

                  sendTargetsArray[0] = orgSendTargets[0];
                  orgtargetSet.getSendTargets().clear();
                  orgtargetSet.getSendTargets().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(sendTargetsArray));

                  // orgtargetSet.setSendTargets(0, orgSendTargets[0]);
                  if (iscsi.updateInternetScsiAuthenticationProperties(
                           storageSystemMor, iscsiHbaId, orgtargetSet,
                           orgSendAuthProperties)) {
                     log.info("Successfully updated original sendTarget authentication "
                              + "properties");
                  } else {
                     sendCleanupDone = false;
                     log.info("Failed to update original sendTarget "
                              + "authentication properties");
                  }
               }

               // put back staticTarget options
               if (orgStaticTargets != null) {
                  orgtargetSet = new HostInternetScsiHbaTargetSet();
                  staticTargetsArray[0] = orgStaticTargets[0];
                  orgtargetSet.getStaticTargets().clear();
                  orgtargetSet.getStaticTargets().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(staticTargetsArray));
                  // orgtargetSet.setStaticTargets(0, orgStaticTargets[0]);
                  if (iscsi.updateInternetScsiAuthenticationProperties(
                           storageSystemMor, iscsiHbaId, orgtargetSet,
                           orgStaticAuthProperties)) {
                     log.info("Successfully updated original staticTarget authentication "
                              + "properties");
                  } else {
                     staticCleanupDone = false;
                     log.info("Failed to update original authentication properties");
                  }
               }

               // put back Hba Advanced Options
               if (iscsi.updateInternetScsiAuthenticationProperties(
                        storageSystemMor, iscsiHbaId, null,
                        orgHbaAuthProperties)) {
                  log.info("Successfully updated original hba authentication properties");
               } else {
                  hbaCleanupDone = false;
                  log.info("Failed to update original auth properties");
               }
               if (sendCleanupDone && staticCleanupDone && hbaCleanupDone) {
                  status = true;
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
