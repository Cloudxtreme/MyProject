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

import dvs.VNicBase;

/**
 * Update a existing service console vnic to connect to an standalone port on an
 * existing DVSwitch. The distributedVirtualPort is of type DVSPortConnection.
 */
public class Pos001 extends VNicBase
{
   private String dvSwitchUuid = null;
   private HostVirtualNicSpec origconsoleVnicSpec = null;
   private String consoleVnicdevice = null;
   boolean updated = false;
   private String portKey = null;

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
      final List<ManagedObjectReference> hostMors = ihs.getAllHost();
      for (final ManagedObjectReference aHostMor : hostMors) {
         if (!ihs.isEesxHost(aHostMor)) {
            hostMor = aHostMor;
            break;
         }
      }
      assertNotNull(hostMor, HOST_GET_PASS, HOST_GET_FAIL);
      log.info("Host Name: " + ihs.getHostName(hostMor));
      /*
       * Check for free Pnics
       */
      final String[] freePnics = ins.getPNicIds(hostMor);
      assertNotEmpty(freePnics, "No free pnics on host!");
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
      assertTrue(ins.refresh(nwSystemMor), "Failed to refresh network");
      /*
       * Get existing consoleVnics
       */
      final HostNetworkConfig nwCfg = ins.getNetworkConfig(nwSystemMor);
      assertNotEmpty(com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class), "Failed to get ConsoleVnic");
      final HostVirtualNicConfig consoleVnicConfig = com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0];
      origconsoleVnicSpec = consoleVnicConfig.getSpec();
      consoleVnicdevice = consoleVnicConfig.getDevice();
      log.info("Got ConsoleVnicDevice: " + consoleVnicdevice);
      portCriteria = iDVSwitch.getPortCriteria(false, null, null, null, null,
               false);
      portCriteria.setUplinkPort(false);
      portKeys = iDVSwitch.fetchPortKeys(dvsMor, portCriteria);
      assertNotEmpty(portKeys, "Failed to get DVPorts.");
      portKey = portKeys.get(0);
      return true;
   }

   @Override
   @Test(description = "Update a existing service console vnic to connect"
            + " to an  standalone port on an existing DVSwitch. "
            + "The distributedVirtualPort is of type DVSPortConnection.")
   public void test()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchPortConnection portConnection = null;
      HostVirtualNicSpec updatedconsoleVnicSpec = null;
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
         updated = status = rebootAndVerifyNetworkConnectivity(hostMor);
      } else {
         log.info("Unable to update serviceconsole VirtualNic: "
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
      if (origconsoleVnicSpec != null) {
         if (ins.updateServiceConsoleVirtualNic(nwSystemMor, consoleVnicdevice,
                  origconsoleVnicSpec)) {
            log.info("Successfully restored original console  VirtualNic "
                     + "config: " + consoleVnicdevice);
         } else {
            log.info("Unable to restore console VirtualNic "
                     + consoleVnicdevice);
            status = false;
         }
      }
      status &= super.testCleanUp();
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
