/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.updatevirtualnic;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigInfo;
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
import com.vmware.vc.NoPermission;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.PrivilegeConstants;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

import dvs.VNicBase;

/**
 * Update an existing virtual nic to connect to an early binding DVPortgroup on
 * an existing DVSwitch by an user not having network.assign privilege
 */
public class Sec004 extends VNicBase
{
   private String dvSwitchUuid = null;
   private HostVirtualNicSpec origVnicSpec = null;
   private String vNicdevice = null;
   private String portgroupKey = null;
   private ManagedObjectReference dvpgMor = null;
   private String hostName = null;

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Update an existing  virtual nic to connect to an"
               + " early binding DVPortgroup on an existing DVSwitch"
               + " by  an user not having  network.assign privilege.");
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
      DistributedVirtualSwitchHostMemberConfigSpec hostMember = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
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
               /*
                * Check for free Pnics
                */
               hostName = ihs.getHostName(hostMor);
               String[] freePnics = ins.getPNicIds(hostMor);
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
                        portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                                 DVPORTGROUP_TYPE_EARLY_BINDING, 1, getTestId()
                                          + "-pg1");
                        if (portgroupKey != null) {
                           List<ManagedObjectReference> pgs = iDVSwitch.getPortgroup(dvsMor);
                           for (int i = 0; i < pgs.size(); i++) {
                              DVPortgroupConfigInfo cfgInfo = iDVPortGroup.getConfigInfo(pgs.get(i));
                              if (portgroupKey.equals(cfgInfo.getKey())) {
                                 dvpgMor = pgs.get(i);
                                 break;
                              }
                           }
                           DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);

                           dvSwitchUuid = info.getUuid();
                           /*
                            * Get existing vnics
                            */
                           HostNetworkConfig nwCfg = ins.getNetworkConfig(nwSystemMor);
                           if ((nwCfg != null) && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class) != null)
                                    && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class).length > 0)
                                    && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0] != null)) {
                              HostVirtualNicConfig vnicConfig = com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0];
                              origVnicSpec = vnicConfig.getSpec();
                              vNicdevice = vnicConfig.getDevice();
                              log.info("VnicDevice : " + vNicdevice);
                              permissionSpecMap.put(
                                       DVSTestConstants.PRIVILEGE_HOST_CONFIG_NETWORK,
                                       ihs.getParentNode(hostMor));
                              if (addRolesAndSetPermissions(permissionSpecMap)
                                       && performSecurityTestsSetup(connectAnchor)) {
                                 status = true;
                              }
                           } else {
                              log.error("Unable to find valid Vnic");
                           }
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
   @Test(description = "Update an existing  virtual nic to connect to an"
               + " early binding DVPortgroup on an existing DVSwitch"
               + " by  an user not having  network.assign privilege.")
   public void test()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchPortConnection portConnection = null;
      HostVirtualNicSpec updatedVNicSpec = null;
      log.info("test  Begin:");
      try {
    	 hostMor = ihs.getHost(hostName);
    	 nwSystemMor = ins.getNetworkSystem(hostMor);
         portConnection = new DistributedVirtualSwitchPortConnection();
         portConnection.setSwitchUuid(dvSwitchUuid);
         portConnection.setPortgroupKey(portgroupKey);
         if (portConnection != null) {
            updatedVNicSpec = (HostVirtualNicSpec) TestUtil.deepCopyObject(origVnicSpec);
            updatedVNicSpec.setDistributedVirtualPort(portConnection);
            updatedVNicSpec.setPortgroup(null);
            if (ins.updateVirtualNic(nwSystemMor, vNicdevice, updatedVNicSpec)) {
               log.error("Successfully updated VirtualNic " + vNicdevice);
               status = false;
            } else {
               log.error("Unable to update VirtualNic " + vNicdevice);
               status = false;
            }
         } else {
            status = false;
            log.error("can not get a free port on the dvswitch");
         }
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         NoPermission expectedMethodFault = new NoPermission();
         expectedMethodFault.setObject(dvpgMor);
         expectedMethodFault.setPrivilegeId(PrivilegeConstants.NETWORK_ASSIGN);
         status = TestUtil.checkMethodFault(actualMethodFault,
                  expectedMethodFault);
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

         try {
            status = performSecurityTestsCleanup(connectAnchor,
                     data.getString(TestConstants.TESTINPUT_USERNAME),
                     data.getString(TestConstants.TESTINPUT_PASSWORD));
            if (origVnicSpec != null) {
               hostMor = ihs.getHost(hostName);
           	   nwSystemMor = ins.getNetworkSystem(hostMor);
               if (ins.updateVirtualNic(nwSystemMor, vNicdevice, origVnicSpec)) {
                  log.info("Successfully restored original VirtualNic "
                           + "config: " + vNicdevice);
                  status &= true;
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
