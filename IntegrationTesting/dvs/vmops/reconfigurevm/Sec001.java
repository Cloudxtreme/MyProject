/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.vmops.reconfigurevm;

import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;

import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.PrivilegeConstants;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

/**
 * Reconfigure a VM on a standalone host to connect to an existing standalone DV
 * port by an user having network.assign privilege
 */
public class Sec001 extends ReconfigureVMBase
{
   private int roleId;

   /**
    * Set test description.
    */
   public void setTestDescription()
   {
      setTestDescription(" Reconfigure a VM on a standalone host to connect"
               + " to an existing standalone DV port "
               + "by an user having network.assign privilege");
   }

   /**
    * Method to setup the environment for the test.
    *
    * @param connectAnchor ConnectAnchor object
    * @return boolean true, if setup is successful. false, otherwise.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {

      boolean status = false;
      log.info("test setup Begin:");
      this.deviceType = VM_VIRTUALDEVICE_ETHERNET_PCNET32;
     
         if (super.testSetUp()) {

            permissionSpecMap.put(
                     DVSTestConstants.PRIVILEGE_HOST_CONFIG_NETWORK,
                     this.ihs.getParentNode(this.hostMor));
            permissionSpecMap.put(DVSTestConstants.PRIVILEGE_NETWORK_ASSIGN,
                     this.dvsMor);
            permissionSpecMap.put(PrivilegeConstants.RESOURCE_ASSIGNVMTOPOOL,
                     this.iFolder.getDataCenter());
            permissionSpecMap.put(
                     PrivilegeConstants.VIRTUALMACHINE_INVENTORY_CREATE,
                     this.iFolder.getDataCenter());
            permissionSpecMap.put(
                     PrivilegeConstants.VIRTUALMACHINE_CONFIG_ADDNEWDISK,
                     this.iFolder.getDataCenter());
            permissionSpecMap.put(PrivilegeConstants.DATASTORE_ALLOCATESPACE,
                     this.iFolder.getDataCenter());
            permissionSpecMap.put(
                     PrivilegeConstants.VIRTUALMACHINE_INTERACT_POWERON,
                     this.iFolder.getDataCenter());
            permissionSpecMap.put(
                     PrivilegeConstants.VIRTUALMACHINE_INTERACT_POWEROFF,
                     this.iFolder.getDataCenter());
            permissionSpecMap.put(
                     PrivilegeConstants.VIRTUALMACHINE_INTERACT_POWEROFF,
                     this.iFolder.getDataCenter());
            permissionSpecMap.put(
                     PrivilegeConstants.VIRTUALMACHINE_CONFIG_EDITDEVICE,
                     this.iFolder.getDataCenter());
            permissionSpecMap.put(
                     PrivilegeConstants.VIRTUALMACHINE_INTERACT_DEVICECONNECTION,
                     this.iFolder.getDataCenter());
            permissionSpecMap.put(
                     PrivilegeConstants.VIRTUALMACHINE_CONFIG_ADDREMOVEDEVICE,
                     this.iFolder.getDataCenter());

            if (addRolesAndSetPermissions(permissionSpecMap)
                     && performSecurityTestsSetup(connectAnchor)) {
               status = true;
            }

         }
     
      Assert.assertTrue(status, "Setup failed");
      return status;
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
     
         status = performSecurityTestsCleanup(connectAnchor,
                  data.getString(TestConstants.TESTINPUT_USERNAME),
                  data.getString(TestConstants.TESTINPUT_PASSWORD));
         super.testCleanUp();
     
      Assert.assertTrue(status, "Cleanup failed");
      return status;
   }

}
