/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.vmops.createvm;

import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NoPermission;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.PrivilegeConstants;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

import dvs.vmops.VMopsBase;

/**
 * Create a VM on a standalone host to connect to an existing standalone DV port
 * by an user not having network.assign privilege
 */
public class Sec002 extends VMopsBase
{
   /*
    * Private data variables
    */
   private VirtualMachineConfigSpec vmConfigSpec = null;
   private DistributedVirtualSwitchPortConnection dvsPortConnection = null;
   private String dvSwitchUuid = null;
   private String portKey = null;
   private ManagedObjectReference vmMor = null;

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Create a VM on a standalone host to connect to an "
               + "existing standalone  DV port by an user not  having network.assign "
               + "privilege");
   }

   /**
    * Method to setup the environment for the test. 1. Create the DVSwitch. 2.
    * Create the Standalone DVPort. 3. Create the VM ConfigSpec.
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
      List<String> portKeys = null;
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
                  portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, 1);
                  if (portKeys != null) {
                     log.info("Successfully get the standalone DVPortkeys");
                     portKey = portKeys.get(0);
                     DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
                     dvSwitchUuid = info.getUuid();
                     // create the DistributedVirtualSwitchPortConnection
                     // object.
                     dvsPortConnection = buildDistributedVirtualSwitchPortConnection(
                              dvSwitchUuid, portKey, null);
                     vmConfigSpec = buildCreateVMCfg(dvsPortConnection,
                              VM_VIRTUALDEVICE_ETHERNET_PCNET32, hostMor);
                     log.info("Successfully created VMConfig spec.");
                     permissionSpecMap.put(
                              DVSTestConstants.PRIVILEGE_HOST_CONFIG_NETWORK,
                              ihs.getParentNode(hostMor));
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

                     if (addRolesAndSetPermissions(permissionSpecMap)
                              && performSecurityTestsSetup(connectAnchor)) {
                        status = true;
                     }
                  } else {
                     log.error("Failed to get the standalone DVPortkeys ");
                  }
               }
            } else {
               log.error("Failed to find network config.");
            }
        
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test. 1. Create the VM. 2. Varify the ConfigSpecs and Power-ops
    * operations.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Create a VM on a standalone host to connect to an "
               + "existing standalone  DV port by an user not  having network.assign "
               + "privilege")
   public void test()
      throws Exception
   {
      boolean status = false;
      try {
         vmMor = new Folder(super.getConnectAnchor()).createVM(
                  ivm.getVMFolder(), vmConfigSpec, ihs.getPoolMor(hostMor),
                  hostMor);
         if (vmMor != null) {
            log.error("Successfully created VM.");
         }
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         NoPermission expectedMethodFault = new NoPermission();
         expectedMethodFault.setObject(dvsMor);
         expectedMethodFault.setPrivilegeId(PrivilegeConstants.NETWORK_ASSIGN);
         status = TestUtil.checkMethodFault(actualMethodFault,
                  expectedMethodFault);
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
         status = performSecurityTestsCleanup(connectAnchor,
                  data.getString(TestConstants.TESTINPUT_USERNAME),
                  data.getString(TestConstants.TESTINPUT_PASSWORD));
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
