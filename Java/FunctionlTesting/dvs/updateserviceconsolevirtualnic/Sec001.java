/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.updateserviceconsolevirtualnic;

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
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostVirtualNicConfig;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

import dvs.VNicBase;

/**
 * Update a existing service console vnic to connect to an standalone port on an
 * existing DVSwitch by an user having network.assign privilege.
 */
public class Sec001 extends VNicBase
{
   private String dvSwitchUuid = null;
   private HostVirtualNicSpec origconsoleVnicSpec = null;
   private String consoleVnicdevice = null;
   private String portKey = null;

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
      assertNotEmpty(freePnics, "Failed to grt free pNics");
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
      assertNotNull(dvsMor, DVS_CREATE_PASS, DVS_CREATE_FAIL);
      ins.refresh(nwSystemMor);
      /*
       * Get existing consoleVnics
       */
      final HostNetworkConfig nwCfg = ins.getNetworkConfig(nwSystemMor);
      if ((nwCfg != null) && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class) != null)
               && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class).length > 0)) {
         final HostVirtualNicConfig consoleVnicConfig = com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0];
         origconsoleVnicSpec = consoleVnicConfig.getSpec();
         consoleVnicdevice = consoleVnicConfig.getDevice();
         log.info("consoleVnicDevice : " + consoleVnicdevice);
         portCriteria = iDVSwitch.getPortCriteria(false, null, null, null,
                  null, false);
         portCriteria.setUplinkPort(false);
         portKeys = iDVSwitch.fetchPortKeys(dvsMor, portCriteria);
         if ((portKeys != null) && (portKeys.size() > 0)) {
            portKey = portKeys.get(0);
            permissionSpecMap.put(
                     DVSTestConstants.PRIVILEGE_HOST_CONFIG_NETWORK,
                     ihs.getParentNode(hostMor));
            permissionSpecMap.put(DVSTestConstants.PRIVILEGE_NETWORK_ASSIGN,
                     dvsMor);
            if (addRolesAndSetPermissions(permissionSpecMap)
                     && performSecurityTestsSetup(connectAnchor)) {
               status = true;
            }
         }
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   @Override
   @Test(description = "Update a existing service console vnic to connect"
            + " to an  standalone port on an existing DVSwitch "
            + "by  an user having  network.assign privilege.")
   public void test()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchPortConnection portConnection = null;
      HostVirtualNicSpec updatedconsoleVnicSpec = null;
      log.info("test  Begin:");
      final DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
      dvSwitchUuid = info.getUuid();
      portConnection = new DistributedVirtualSwitchPortConnection();
      portConnection.setSwitchUuid(dvSwitchUuid);
      portConnection.setPortKey(portKey);
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

   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
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
