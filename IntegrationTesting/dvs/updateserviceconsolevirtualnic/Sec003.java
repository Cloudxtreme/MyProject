/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.updateserviceconsolevirtualnic;

import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.*;

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
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostVirtualNicConfig;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

import dvs.VNicBase;

/**
 * Update an existing service console vnic to connect to an earlyBinding
 * DVPortgroup on an existing DVSwitch by an user having network.assign
 * privilege
 */
public class Sec003 extends VNicBase
{
   private String dvSwitchUuid = null;
   private HostVirtualNicSpec origconsoleVnicSpec = null;
   private String consoleVnicdevice = null;
   private String portgroupKey = null;

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Update an existing  service console vnic to "
               + "connect to an  early binding DVportgroup on an existing"
               + " DVSwitch by  an user having  network.assign privilege");
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
      DistributedVirtualSwitchHostMemberConfigSpec hostMember = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
      ManagedObjectReference pgMor = null;
      log.info("test setup Begin:");
      assertTrue(super.testSetUp(), TB_SETUP_PASS, TB_SETUP_FAIL);
      final List<ManagedObjectReference> hostMors = ihs.getAllHost();
      for (final ManagedObjectReference aHostMor : hostMors) {
         if (!ihs.isEesxHost(aHostMor)) {
            hostMor = aHostMor;
            break;
         }
      }
      assertNotNull(hostMor, HOST_GET_PASS, HOST_GET_FAIL);
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
            dvsConfigSpec.getHost().clear();
            dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMember }));
            dvsMor = iFolder.createDistributedVirtualSwitch(
                     iFolder.getNetworkFolder(iFolder.getDataCenter()),
                     dvsConfigSpec);
            if ((dvsMor != null)
                     && ins.refresh(nwSystemMor)
                     && iDVSwitch.validateDVSConfigSpec(dvsMor, dvsConfigSpec,
                              null)) {
               log.info("Successfully created the distributed "
                        + "virtual switch");
               portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                        DVPORTGROUP_TYPE_EARLY_BINDING, 1, getTestId() + "-pg1");
               if (portgroupKey != null) {
                  final DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
                  dvSwitchUuid = info.getUuid();
                  final List<ManagedObjectReference> dvPortgroupMorList = iDVSwitch.getPortgroup(dvsMor);
                  if ((dvPortgroupMorList != null)
                           && (dvPortgroupMorList.size() > 0)) {
                     for (int i = 0; i < dvPortgroupMorList.size(); i++) {
                        pgMor = dvPortgroupMorList.get(i);
                        final String key = iDVPortGroup.getKey(pgMor);
                        if ((key != null) && key.equalsIgnoreCase(portgroupKey)) {
                           break;
                        }
                     }
                  }
                  final HostNetworkConfig nwCfg = ins.getNetworkConfig(nwSystemMor);
                  if ((nwCfg != null) && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class) != null)
                           && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class).length > 0)) {
                     final HostVirtualNicConfig consoleVnicConfig = com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0];
                     origconsoleVnicSpec = consoleVnicConfig.getSpec();
                     consoleVnicdevice = consoleVnicConfig.getDevice();
                     log.info("consoleVnicDevice : " + consoleVnicdevice);
                     permissionSpecMap.put(
                              DVSTestConstants.PRIVILEGE_HOST_CONFIG_NETWORK,
                              ihs.getParentNode(hostMor));
                     permissionSpecMap.put(
                              DVSTestConstants.PRIVILEGE_NETWORK_ASSIGN, pgMor);
                     if (addRolesAndSetPermissions(permissionSpecMap)
                              && performSecurityTestsSetup(connectAnchor)) {
                        status = true;
                     }
                  }
               } else {
                  log.error("Failed the add the portgroups to DVS.");
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
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test.
    *
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Update an existing  service console vnic to "
            + "connect to an  early binding DVportgroup on an existing"
            + " DVSwitch by  an user having  network.assign privilege")
   public void test()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchPortConnection portConnection = null;
      HostVirtualNicSpec updatedconsoleVnicSpec = null;
      log.info("test  Begin:");
      portConnection = new DistributedVirtualSwitchPortConnection();
      portConnection.setSwitchUuid(dvSwitchUuid);
      portConnection.setPortgroupKey(portgroupKey);
      updatedconsoleVnicSpec = (HostVirtualNicSpec) TestUtil.deepCopyObject(origconsoleVnicSpec);
      updatedconsoleVnicSpec.setDistributedVirtualPort(portConnection);
      updatedconsoleVnicSpec.setPortgroup(null);
      if (ins.updateServiceConsoleVirtualNic(nwSystemMor, consoleVnicdevice,
               updatedconsoleVnicSpec)) {
         log.info("Successfully updated serviceconsole VirtualNic "
                  + consoleVnicdevice);
         status = true;
      } else {
         log.info("Unable to update serviceconsole VirtualNic "
                  + consoleVnicdevice);
         status = false;
      }
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    *
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if successful.
    */
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;
      try {
         status = performSecurityTestsCleanup(connectAnchor,
                  data.getString(TestConstants.TESTINPUT_USERNAME),
                  data.getString(TestConstants.TESTINPUT_PASSWORD));
         if (origconsoleVnicSpec != null) {
            if (ins.updateServiceConsoleVirtualNic(nwSystemMor,
                     consoleVnicdevice, origconsoleVnicSpec)) {
               log.info("Successfully restored original console  VirtualNic "
                        + "config: " + consoleVnicdevice);
            } else {
               log.info("Unable to restore console VirtualNic "
                        + consoleVnicdevice);
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
