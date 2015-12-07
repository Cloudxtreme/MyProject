/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DvsScopeViolated;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * Add an early binding portgroup to an existing distributed virtual switch with
 * scope set to a resource pool MOR and reconfigure a VM to connect its VNIC to
 * this portgroup
 */
public class Neg014 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private VirtualMachine iVirtualMachine = null;
   private HostSystem iHostSystem = null;
   private NetworkSystem iNetworkSystem = null;
   private ManagedObjectReference hostMor = null;
   private ManagedObjectReference vmMor = null;
   private ManagedObjectReference nsMor = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private HostNetworkConfig[] hostNetworkConfig = null;
   private HostNetworkConfig originalNetworkConfig = null;
   private VirtualMachinePowerState vmPowerState = null;
   private DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private DistributedVirtualSwitchPortConnection portConnection = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private String portgroupKey = null;
   private Map<String, List<String>> usedPorts = null;
   private VirtualMachineConfigSpec[] updatedDeltaConfigSpec = null;
   private ManagedObjectReference dcMor = null;
   private ManagedObjectReference resourcePoolMor = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Add an early binding portgroup to an existing "
               + "distributed virtual switch with scope set to "
               + "resource pool MOR and reconfigure"
               + " a VMvnic to connect to this portgroup");
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
      final String dvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
               + getTestId();
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      Vector<ManagedObjectReference> allVMs = null;
      log.info("Test setup Begin:");
      iFolder = new Folder(connectAnchor);
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      iVirtualMachine = new VirtualMachine(connectAnchor);
      iHostSystem = new HostSystem(connectAnchor);
      iManagedEntity = new ManagedEntity(connectAnchor);
      iNetworkSystem = new NetworkSystem(connectAnchor);
      /*
       * Get a standalone host of version 4.0
       */
      final List<ManagedObjectReference> hosts = iHostSystem.getAllHost();
      hostMor = hosts.get(0);
      assertNotNull(hostMor, HOST_GET_PASS, HOST_GET_FAIL);
      assertTrue(iHostSystem.isHostConnected(hostMor),
               "Failed to get connected host");
      assertTrue(iHostSystem.isHostConnected(hosts.get(1)),
               "Failed to get connected host");
      resourcePoolMor = iHostSystem.getPoolMor(hosts.get(1));
      if (hostMor != null && resourcePoolMor != null) {
         dcMor = iFolder.getDataCenter();
         if (dcMor != null) {
            dvsConfigSpec = new DVSConfigSpec();
            dvsConfigSpec.setConfigVersion("");
            dvsConfigSpec.setName(dvsName);
            hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
            hostConfigSpecElement.setHost(hostMor);
            hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
            pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
            pnicBacking.getPnicSpec().clear();
            pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
            hostConfigSpecElement.setBacking(pnicBacking);
            dvsConfigSpec.getHost().clear();
            dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
            dvsMor = iFolder.createDistributedVirtualSwitch(
                     iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
            hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(
                     dvsMor, hostMor);
            nsMor = iNetworkSystem.getNetworkSystem(hostMor);
            if (nsMor != null) {
               iNetworkSystem.refresh(nsMor);
               Thread.sleep(10000);
               iNetworkSystem.updateNetworkConfig(nsMor, hostNetworkConfig[0],
                        TestConstants.CHANGEMODE_MODIFY);
               originalNetworkConfig = hostNetworkConfig[1];
            } else {
               log.error("Network system MOR is null");
            }
            if (dvsMor != null) {
               log.info("Successfully created the distributed "
                        + "virtual switch");
               allVMs = iHostSystem.getVMs(hostMor, null);
               /*
                * Get the first VM in the list of VMs.
                */
               if (allVMs != null) {
                  vmMor = allVMs.get(0);
               }
               if (vmMor != null) {
                  vmPowerState = iVirtualMachine.getVMState(vmMor);
                  if (iVirtualMachine.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false)) {
                     log.info("Successfully powered off the"
                              + " virtual machine");
                     dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
                     dvPortgroupConfigSpec.setConfigVersion("");
                     dvPortgroupConfigSpec.setName(getTestId());
                     dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
                     dvPortgroupConfigSpec.setNumPorts(1);
                     dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
                     dvPortgroupConfigSpec.getScope().clear();
                     dvPortgroupConfigSpec.getScope().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new ManagedObjectReference[] { resourcePoolMor }));
                     status = true;
                  }
               } else {
                  log.error("Failed to find a virtual machine");
               }
            } else {
               log.error("Failed to create the distributed " + "virtual switch");
            }
         } else {
            log.error("Failed to find a datacenter");
         }
      } else {
         log.error("Failed to login");
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that adds an early binding portgroup with scope set to a resource
    * pool MOR and reconfigures a VM-vnic to connect to this portgroup
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "Add an early binding portgroup to an existing "
            + "distributed virtual switch with scope set to "
            + "resource pool MOR and reconfigure"
            + " a VMvnic to connect to this portgroup")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      try {
         if (dvPortgroupConfigSpec != null) {
            dvPortgroupConfigSpecArray = new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec };
            dvPortgroupMorList = iDVSwitch.addPortGroups(dvsMor,
                     dvPortgroupConfigSpecArray);
            if (dvPortgroupMorList != null) {
               if (dvPortgroupMorList.size() == dvPortgroupConfigSpecArray.length) {
                  log.info("Successfully added all the portgroups");
                  portgroupKey = iDVPortgroup.getKey(dvPortgroupMorList.get(0));
                  if (portgroupKey != null) {
                     usedPorts = new HashMap<String, List<String>>();
                     usedPorts.put(portgroupKey, null);
                     portConnection = iDVSwitch.getPortConnection(dvsMor, null,
                              false, usedPorts, new String[] { portgroupKey });
                     updatedDeltaConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                              vmMor,
                              connectAnchor,
                              new DistributedVirtualSwitchPortConnection[] { portConnection });
                     if (updatedDeltaConfigSpec != null) {
                        if (iVirtualMachine.reconfigVM(vmMor,
                                 updatedDeltaConfigSpec[0])) {
                           log.error("Successfully reconfigured the VM"
                                    + " to connect to a free port in the "
                                    + "portgroup but the API did not throw "
                                    + "an exception");
                        } else {
                           log.error("Could not reconfigure the VM"
                                    + " to connect to a free port in the "
                                    + "portgroup and the API did not throw an "
                                    + "exception");
                        }
                     }
                  } else {
                     log.error("Could not get the portgroup key");
                  }
               } else {
                  log.error("Could not add all the portgroups");
               }
            } else {
               log.error("No portgroups were added");
            }
         }
      } catch (final Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         final DvsScopeViolated expectedMethodFault = new DvsScopeViolated();
         status = TestUtil.checkMethodFault(
                  actualMethodFault.getFaultCause().getFault(),
                  expectedMethodFault);
      }
      assertTrue(status, "Test Failed");
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
      try {
         /*
          * Restore the original config spec of the virtual machine
          */
         status &= iVirtualMachine.reconfigVM(vmMor, updatedDeltaConfigSpec[1]);
         /*
          * Restore the power state of the virtual machine
          */
         status &= iVirtualMachine.setVMState(vmMor, vmPowerState, false);
         /*
          * Restore the original network config
          */
         if (originalNetworkConfig != null) {
            status &= iNetworkSystem.updateNetworkConfig(nsMor,
                     originalNetworkConfig, TestConstants.CHANGEMODE_MODIFY);
         }
      } catch (final Exception e) {
         TestUtil.handleException(e);
         status = false;
      } finally {
         try {
            if (dvsMor != null) {
               status &= iManagedEntity.destroy(dvsMor);
            }
         } catch (final Exception ex) {
            TestUtil.handleException(ex);
            status = false;
         }
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
