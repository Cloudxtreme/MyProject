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
import com.vmware.vc.MethodFault;
import com.vmware.vc.SystemError;
import com.vmware.vc.NotFound;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;

import dvs.VNicBase;

/**
 * Update a existing service console vnic to connect to an standalone port on an
 * existing DVSwitch. The distributedVirtualPort is of type DVSPortConnection.
 * Build a DVPortConnection with invalid DVPortKey. The distributedVirtualPort
 * is of type DistributedVirtualSwitchPortConnection.
 */
public class Neg001 extends VNicBase
{
   private String dvSwitchUuid = null;
   private HostVirtualNicSpec origconsoleVnicSpec = null;
   private String consoleVnicdevice = null;
   boolean updated = false;

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
      if (super.testSetUp()) {
         final List<ManagedObjectReference> hostMors = ihs.getAllHost();
         for (final ManagedObjectReference aHostMor : hostMors) {
            if (!ihs.isEesxHost(aHostMor)) {
               hostMor = aHostMor;
               break;
            }
         }
         assertNotNull(hostMor, HOST_GET_PASS, HOST_GET_FAIL);
         log.info("Host Name: " + ihs.getHostName(hostMor));
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
                   * Get existing consoleVnics
                   */
                  final HostNetworkConfig nwCfg = ins.getNetworkConfig(nwSystemMor);
                  if ((nwCfg != null) && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class) != null)
                           && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class).length > 0)) {
                     final HostVirtualNicConfig consoleVnicConfig = com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0];
                     origconsoleVnicSpec = consoleVnicConfig.getSpec();
                     consoleVnicdevice = consoleVnicConfig.getDevice();
                     log.info("consoleVnicDevice : " + consoleVnicdevice);
                     portCriteria = iDVSwitch.getPortCriteria(false, null,
                              null, null, null, false);
                     portCriteria.setUplinkPort(false);
                     portKeys = iDVSwitch.fetchPortKeys(dvsMor, portCriteria);
                     if ((portKeys != null) && (portKeys.size() > 0)) {
                     }
                     status = true;
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
   @Test(description = "Update a existing service console vnic to connect"
            + " to an  standalone port on an existing DVSwitch. "
            + "The distributedVirtualPort is of type DVSPortConnection.\n"
            + "Build a DVPortConnection with invalid DVPortKey.")
   public void test()
      throws Exception
   {
	  boolean status = false;
      DistributedVirtualSwitchPortConnection portConnection = null;
      HostVirtualNicSpec updatedconsoleVnicSpec = null;
	  final MethodFault expectedFault = new NotFound();
      try {
	      final DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
	      dvSwitchUuid = info.getUuid();
	      portConnection = new DistributedVirtualSwitchPortConnection();
	      portConnection.setSwitchUuid(dvSwitchUuid);
	      portConnection.setPortKey("XYZ");
	      updatedconsoleVnicSpec = (HostVirtualNicSpec) TestUtil.deepCopyObject(origconsoleVnicSpec);
	      updatedconsoleVnicSpec.setDistributedVirtualPort(portConnection);
	      updatedconsoleVnicSpec.setPortgroup(null);
	      if (ins.updateServiceConsoleVirtualNic(nwSystemMor, consoleVnicdevice,
	               updatedconsoleVnicSpec)) {
	         log.error("Successfully updated serviceconsole VirtualNic "
	                  + consoleVnicdevice);
	         status = false;
	      } else {
	         log.error("Unable to update serviceconsole VirtualNic "
	                  + consoleVnicdevice);
	         status = false;
	      }
      }
	  catch (Exception actualFaultExcep) {
	    	SystemError actualFault = (SystemError)com.vmware.vcqa.util.TestUtil.getFault(actualFaultExcep);
         status = TestUtil.checkMethodFault(actualFault.getFaultCause().getFault(), expectedFault);
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
         status = super.testCleanUp();
      } catch (final Exception e) {
         status = false;
         TestUtil.handleException(e);
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
