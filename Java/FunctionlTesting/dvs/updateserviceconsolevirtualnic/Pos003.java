/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.updateserviceconsolevirtualnic;

import static com.vmware.vcqa.util.Assert.*;
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

import dvs.VNicBase;

/**
 * Update an existing service console vnic to connect to an existing DVPort on
 * an early binding DVportgroup on an existing DVSwitch. The
 * distributedVirtualPort is of type DVSPortgroupConnection.
 */
public class Pos003 extends VNicBase
{
   private String dvSwitchUuid = null;
   private HostVirtualNicSpec origconsoleVnicSpec = null;
   private String consoleVnicdevice = null;
   boolean updated = false;
   private String portgroupKey = null;
   private String aPortKey = null;

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Update an existing  service console  vnic to"
               + " connect to an existing DVPort on an early binding DVportgroup "
               + " on an existing DVSwitch. The distributedVirtualPort"
               + " is of type DVSPortgroupConnection.");
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
      List<String> portKeys = null;
      log.info("test setup Begin:");
      if (super.testSetUp()) {
         final List<ManagedObjectReference> hostMors = ihs.getAllHost();
         for (final ManagedObjectReference aHostMor : hostMors) {
            if (!ihs.isEesxHost(aHostMor)) {
               hostMor = aHostMor;
               break;
            }
         }
         if (hostMor != null) {
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
                           && iDVSwitch.validateDVSConfigSpec(dvsMor,
                                    dvsConfigSpec, null)) {
                     log.info("Successfully created the distributed "
                              + "virtual switch");
                     portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                              DVPORTGROUP_TYPE_EARLY_BINDING, 1, getTestId()
                                       + "-pg1");
                     if (portgroupKey != null) {
                        // Get the existing DVPortkey on earlyBinding
                        // DVPortgroup.
                        portKeys = fetchPortKeys(dvsMor, portgroupKey);
                        aPortKey = portKeys.get(0);
                        final DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
                        dvSwitchUuid = info.getUuid();
                        final HostNetworkConfig nwCfg = ins.getNetworkConfig(nwSystemMor);
                        if ((nwCfg != null) && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class) != null)
                                 && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class).length > 0)) {
                           final HostVirtualNicConfig consoleVnicConfig = com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0];
                           origconsoleVnicSpec = consoleVnicConfig.getSpec();
                           consoleVnicdevice = consoleVnicConfig.getDevice();
                           log.info("consoleVnicDevice : " + consoleVnicdevice);
                           status = true;
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
   @Test(description = "Update an existing  service console  vnic to"
            + " connect to an existing DVPort on an early binding DVportgroup "
            + " on an existing DVSwitch. The distributedVirtualPort"
            + " is of type DVSPortgroupConnection.")
   public void test()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchPortConnection portConnection = null;
      HostVirtualNicSpec updatedconsoleVnicSpec = null;
      log.info("test  Begin:");
      final DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
      dvSwitchUuid = info.getUuid();
      // create the DistributedVirtualSwitchPortConnection object.
      portConnection = buildDistributedVirtualSwitchPortConnection(
               dvSwitchUuid, aPortKey, portgroupKey);
      if (portConnection != null) {
         updatedconsoleVnicSpec = (HostVirtualNicSpec) TestUtil.deepCopyObject(origconsoleVnicSpec);
         updatedconsoleVnicSpec.setDistributedVirtualPort(portConnection);
         updatedconsoleVnicSpec.setPortgroup(null);
         if (ins.updateServiceConsoleVirtualNic(nwSystemMor, consoleVnicdevice,
                  updatedconsoleVnicSpec)) {
            log.info("Successfully updated serviceconsole VirtualNic "
                     + consoleVnicdevice);
            updated = status = rebootAndVerifyNetworkConnectivity(hostMor);
         } else {
            log.info("Unable to update serviceconsole VirtualNic "
                     + consoleVnicdevice);
            status = false;
         }
      } else {
         status = false;
         log.error("can not get a free port on the dvswitch");
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
      boolean status = true;
      try {
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
