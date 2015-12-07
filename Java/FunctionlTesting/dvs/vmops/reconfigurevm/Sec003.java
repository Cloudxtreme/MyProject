/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.vmops.reconfigurevm;

import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.PrivilegeConstants;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.vmops.VMopsBase;

/**
 * Reconfigure a VM on a standalone host to connect to an existing earlyBinding
 * DVPortgroup by an user having network.assign privilege
 */
public class Sec003 extends VMopsBase
{

   /*
    * Private data variables
    */
   private VirtualMachineConfigSpec vmConfigSpec = null;
   private DistributedVirtualSwitchPortConnection dvsPortConnection = null;
   private String dvSwitchUuid = null;
   private ManagedObjectReference vmMor = null;
   List<ManagedObjectReference> vmMors = null;

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription(" Reconfigure a VM on a standalone host to connect"
               + " to an existing earlyBinding DVPortgroup "
               + "by an user having network.assign privilege");
   }

   /**
    * Method to setup the environment for the test. 1. Create the DVSwitch. 2.
    * Create the lateBinding DVPortgroup. 3. Create the VMConfigSpec.
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
      String portgroupKey = null;
      vmMors = new ArrayList<ManagedObjectReference>();
      log.info("test setup Begin:");
      if (super.testSetUp()) {
        
            hostMor = ihs.getStandaloneHost();
            log.info("Host MOR: " + hostMor);
            log.info("Host Name: " + ihs.getHostName(hostMor));
            // create the DVS by using standalone host.
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
            Thread.sleep(10000);// Sleep for 10 Sec
            nwSystemMor = ins.getNetworkSystem(hostMor);
            if (ins.refresh(nwSystemMor)) {
               log.info("refreshed");
            }
            // add the pnics to DVS
            hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(
                     dvsMor, hostMor);
            if (hostNetworkConfig != null && hostNetworkConfig.length == 2) {
               log.info("Found the network config.");
               // update the network to use the DVS.
               networkUpdated = ins.updateNetworkConfig(nwSystemMor,
                        hostNetworkConfig[0], TestConstants.CHANGEMODE_MODIFY);
               if (networkUpdated) {
                  portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                           DVPORTGROUP_TYPE_EARLY_BINDING, 4, getTestId()
                                    + "-PG.");
                  if (portgroupKey != null) {
                     // Get DVSUuid.
                     DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
                     dvSwitchUuid = info.getUuid();
                     // create the DistributedVirtualSwitchPortConnection
                     // object.
                     dvsPortConnection = buildDistributedVirtualSwitchPortConnection(
                              dvSwitchUuid, null, portgroupKey);
                     // Create the VM.
                     vmConfigSpec = buildDefaultSpec(hostMor,
                              VM_VIRTUALDEVICE_ETHERNET_PCNET32);
                     vmConfigSpec.setName(getTestId());
                     vmMor = new Folder(super.getConnectAnchor()).createVM(
                              ivm.getVMFolder(), vmConfigSpec,
                              ihs.getPoolMor(hostMor), hostMor);
                     if (vmMor != null) {
                        log.info("Successfully crated a VM.");
                        vmMors.add(vmMor);

                        permissionSpecMap.put(
                                 DVSTestConstants.PRIVILEGE_HOST_CONFIG_NETWORK,
                                 ihs.getParentNode(hostMor));
                        permissionSpecMap.put(
                                 DVSTestConstants.PRIVILEGE_NETWORK_ASSIGN,
                                 dvsMor);
                        permissionSpecMap.put(
                                 PrivilegeConstants.RESOURCE_ASSIGNVMTOPOOL,
                                 iFolder.getDataCenter());
                        permissionSpecMap.put(
                                 PrivilegeConstants.VIRTUALMACHINE_INVENTORY_CREATE,
                                 iFolder.getDataCenter());
                        permissionSpecMap.put(
                                 PrivilegeConstants.VIRTUALMACHINE_CONFIG_ADDNEWDISK,
                                 iFolder.getDataCenter());
                        permissionSpecMap.put(
                                 PrivilegeConstants.DATASTORE_ALLOCATESPACE,
                                 iFolder.getDataCenter());
                        permissionSpecMap.put(
                                 PrivilegeConstants.VIRTUALMACHINE_INTERACT_POWERON,
                                 iFolder.getDataCenter());
                        permissionSpecMap.put(
                                 PrivilegeConstants.VIRTUALMACHINE_INTERACT_POWEROFF,
                                 iFolder.getDataCenter());
                        permissionSpecMap.put(
                                 PrivilegeConstants.VIRTUALMACHINE_INTERACT_POWEROFF,
                                 iFolder.getDataCenter());
                        permissionSpecMap.put(
                                 PrivilegeConstants.VIRTUALMACHINE_CONFIG_EDITDEVICE,
                                 iFolder.getDataCenter());
                        permissionSpecMap.put(
                                 PrivilegeConstants.VIRTUALMACHINE_INTERACT_DEVICECONNECTION,
                                 iFolder.getDataCenter());
                        permissionSpecMap.put(
                                 PrivilegeConstants.VIRTUALMACHINE_INTERACT_SUSPEND,
                                 iFolder.getDataCenter());                     

                        if (addRolesAndSetPermissions(permissionSpecMap)
                                 && performSecurityTestsSetup(connectAnchor)) {
                           status = true;
                        }
                     } else {
                        log.error("Unable to create a VM.");
                     }
                  } else {
                     log.error("Failed the add the portgroups to DVS.");
                  }
               } else {
                  log.error("Failed to find network config.");
               }
            }
        
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test. 1. Create the DeltaConfigSpec. 2. Reconfigure the VirtualMachine
    * Configuration. 3. Varify the VMConfigSpecs and Power-ops operations.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Test(description = " Reconfigure a VM on a standalone host to connect"
               + " to an existing earlyBinding DVPortgroup "
               + "by an user having network.assign privilege")
   public void test()
      throws Exception
   {
      boolean status = true;
     
         VirtualMachineConfigSpec deltaConfigSpec = null;
         Iterator vmIterator = vmMors.iterator();
         while (vmIterator.hasNext()) {
            vmMor = (ManagedObjectReference) vmIterator.next();
            if (vmMor != null) {
               deltaConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                        vmMor,
                        connectAnchor,
                        new DistributedVirtualSwitchPortConnection[] { dvsPortConnection })[0];
               if (ivm.reconfigVM(vmMor, deltaConfigSpec)) {
                  log.info("Successfully recongigure the VM.");
                  status &= verify(vmMor, deltaConfigSpec, vmConfigSpec);
               } else {
                  log.error("Failed to reconfigure the VM.");
                  status = false;
               }
               vmMor = null;
            }
         }
     
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if successful.
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         status &= performSecurityTestsCleanup(connectAnchor,
                  data.getString(TestConstants.TESTINPUT_USERNAME),
                  data.getString(TestConstants.TESTINPUT_PASSWORD));
         Iterator vmIterator = vmMors.iterator();
         while (vmIterator.hasNext()) {
            vmMor = (ManagedObjectReference) vmIterator.next();
            if (vmMor != null && ivm.setVMState(vmMor, POWERED_OFF, false)) {
               status &= destroy(vmMor);// destroy the VM.
            } else {
               log.warn("VM not found");
            }
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      try {
         if (networkUpdated) {
            // restore the network to use the DVS.
            status &= ins.updateNetworkConfig(nwSystemMor,
                     hostNetworkConfig[1], TestConstants.CHANGEMODE_MODIFY);
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      } finally {
         status &= super.testCleanUp();
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
