/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.merge;

import static com.vmware.vcqa.util.Assert.*;

import java.util.HashMap;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostProxySwitchConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NotSupported;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vc.VmwareDistributedVirtualSwitchPvlanSpec;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * Merge two DVSes with the source DVS containing a map entry which is used by a
 * port to which a VMvnic is connected
 */
public class Neg013 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitchHelper iDVSwitch = null;
   private VirtualMachine iVirtualMachine = null;
   private HostSystem iHostSystem = null;
   private NetworkSystem iNetworkSystem = null;
   private ManagedObjectReference hostMor = null;
   private ManagedObjectReference vmMor = null;
   private ManagedObjectReference nsMor = null;
   private HostNetworkConfig[] hostNetworkConfig = null;
   private HostNetworkConfig originalNetworkConfig = null;
   private VirtualMachinePowerState vmPowerState = null;
   private VirtualMachineConfigSpec[] vmDeltaConfigSpec = null;
   private String portKey = null;
   private ManagedObjectReference dcMor = null;
   private VMwareDVSPortSetting dvsPortSetting = null;
   private ManagedObjectReference srcDvsMor = null;
   private DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
   private DistributedVirtualSwitchPortConnection portConnection = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Merge two DVSes with the source DVS containing "
               + "a pvlan map entry which is used by a port to which a VMvnic "
               + "is connected to");
   }

   /**
    * Method to setup the environment for the test. This method creates a
    * distributed virtual switch.
    *
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      DVPortConfigSpec portConfigSpec = null;
      VmwareDistributedVirtualSwitchPvlanSpec pvlanspec = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      Vector allVMs = null;
      Map<String, Object> settingsMap = null;
      log.info("Test setup Begin:");
      iFolder = new Folder(connectAnchor);
      iDVSwitch = new DistributedVirtualSwitchHelper(connectAnchor);
      iHostSystem = new HostSystem(connectAnchor);
      iManagedEntity = new ManagedEntity(connectAnchor);
      iNetworkSystem = new NetworkSystem(connectAnchor);
      iVirtualMachine = new VirtualMachine(connectAnchor);
      hostMor = iHostSystem.getAllHost().get(0);
      dcMor = iFolder.getDataCenter();
      if (dcMor != null && hostMor != null) {
         dvsConfigSpec = new DVSConfigSpec();
         dvsConfigSpec.setConfigVersion("");
         dvsConfigSpec.setName(getTestId() + "_DEST");
         dvsMor = iFolder.createDistributedVirtualSwitch(
                  iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
         /*
          * TODO Check whether the pnic devices need to be set in the
          * DistributedVirtualSwitchHostMemberPnicSpec
          */
         dvsConfigSpec.setNumStandalonePorts(9);
         dvsConfigSpec.setName(getTestId() + "_SRC");
         hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
         hostConfigSpecElement.setHost(hostMor);
         hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
         pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
         pnicBacking.getPnicSpec().clear();
         pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
         hostConfigSpecElement.setBacking(pnicBacking);
         dvsConfigSpec.getHost().clear();
         dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
         srcDvsMor = iFolder.createDistributedVirtualSwitch(
                  iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
         if (dvsMor != null && srcDvsMor != null) {
            if (iDVSwitch.addPrimaryPvlan(srcDvsMor, 15)) {
               log.info("Successfully created the distributed "
                        + "virtual switches");
               portKey = iDVSwitch.getFreeStandaloneDVPortKey(srcDvsMor, null);
               pvlanspec = new VmwareDistributedVirtualSwitchPvlanSpec();
               pvlanspec.setPvlanId(15);
               settingsMap = new HashMap<String, Object>();
               settingsMap.put(DVSTestConstants.VLAN_KEY, pvlanspec);
               dvsPortSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
               portConfigSpec = new DVPortConfigSpec();
               portConfigSpec.setOperation(TestConstants.CONFIG_SPEC_EDIT);
               portConfigSpec.setKey(portKey);
               portConfigSpec.setSetting(dvsPortSetting);
               if (iDVSwitch.reconfigurePort(srcDvsMor,
                        new DVPortConfigSpec[] { portConfigSpec })) {
                  log.info("Successfully reconfigured the port");
                  nsMor = iNetworkSystem.getNetworkSystem(hostMor);
                  hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(
                           srcDvsMor, hostMor);
                  if (nsMor != null && hostNetworkConfig != null
                           && hostNetworkConfig[0] != null
                           && hostNetworkConfig[1] != null) {
                     log.info("Successfully obtained the " + "network system");
                     Thread.sleep(10000);
                     iNetworkSystem.updateNetworkConfig(nsMor,
                              hostNetworkConfig[0],
                              TestConstants.CHANGEMODE_MODIFY);
                     originalNetworkConfig = hostNetworkConfig[1];
                     allVMs = iHostSystem.getVMs(hostMor, null);
                     /*
                      * Get the first VM in the list of VMs.
                      */
                     if (allVMs != null) {
                        vmMor = (ManagedObjectReference) allVMs.get(0);
                     }
                     if (vmMor != null) {
                        vmPowerState = iVirtualMachine.getVMState(vmMor);
                        if (iVirtualMachine.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false)) {
                           log.info("Successfully powered off the "
                                    + "virtual machine");
                           portConnection = new DistributedVirtualSwitchPortConnection();
                           portConnection.setPortKey(portKey);
                           portConnection.setSwitchUuid(iDVSwitch.getConfig(
                                    srcDvsMor).getUuid());
                           vmDeltaConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                                    vmMor,
                                    connectAnchor,
                                    new DistributedVirtualSwitchPortConnection[] { portConnection });
                           if (vmDeltaConfigSpec != null
                                    && vmDeltaConfigSpec.length == 2) {
                              if (iVirtualMachine.reconfigVM(vmMor,
                                       vmDeltaConfigSpec[0])) {
                                 log.info("Successfully "
                                          + "reconfigured the VM to connect "
                                          + "to the port");
                                 status = true;
                              } else {
                                 log.error("Failed to"
                                          + " reconfigure the VM to connect "
                                          + "to the port");
                              }
                           }
                        } else {
                           log.error("Failed to power off the "
                                    + "virtual machine");
                        }
                     } else {
                        log.error("Failed to find a virtual " + "machine");
                     }
                  } else {
                     log.error("Failed to obtain the network " + "system");
                  }
               } else {
                  log.error("Failed to reconfigure the port");
               }
            } else {
               log.error("Can not add the primary pvlan id");
            }
         } else {
            log.error("Could not create the distributed " + "virtual switches");
         }
      } else {
         log.error("Failed to find a folder");
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   @Override
   @Test(description = "Merge two DVSes with the source DVS containing "
            + "a pvlan map entry which is used by a port to which a VMvnic "
            + "is connected to")
   public void test()
      throws Exception
   {
      try {
         iDVSwitch.merge(dvsMor, srcDvsMor);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new NotSupported();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
   }

   /**
    * Setting the expected Exception.
    */
   @Override
   public MethodFault getExpectedMethodFault()
   {
      return new NotSupported();
   }

   /**
    * Method to restore the state as it was before the test was started. Restore
    * the original state of the VM.Destroy the portgroup, followed by the
    * distributed virtual switch
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      /*
       * Restore the original config spec of the virtual machine
       */
      status &= iVirtualMachine.reconfigVM(vmMor, vmDeltaConfigSpec[1]);
      /*
       * Restore the power state of the virtual machine
       */
      status &= iVirtualMachine.setVMState(vmMor, vmPowerState, false);
      /*
       * Restore the original network config
       */
      if (originalNetworkConfig != null) {
         final HostProxySwitchConfig config = iDVSwitch.getDVSVswitchProxyOnHost(
                  dvsMor, hostMor);
         if (config != null) {
            config.setSpec(com.vmware.vcqa.util.TestUtil.vectorToArray(originalNetworkConfig.getProxySwitch(), com.vmware.vc.HostProxySwitchConfig.class)[0].getSpec());
            originalNetworkConfig.getProxySwitch().clear();
            originalNetworkConfig.getProxySwitch().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new HostProxySwitchConfig[] { config }));
         }
         status &= iNetworkSystem.updateNetworkConfig(nsMor,
                  originalNetworkConfig, TestConstants.CHANGEMODE_MODIFY);
      }
      if (dvsMor != null && iManagedEntity.isExists(dvsMor)) {
         status &= iManagedEntity.destroy(dvsMor);
      }
      if (srcDvsMor != null && iManagedEntity.isExists(srcDvsMor)) {
         status &= iManagedEntity.destroy(srcDvsMor);
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
