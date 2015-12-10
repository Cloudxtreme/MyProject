/*
 * ************************************************************************
 *
 * Copyright 2008-2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVPORTGROUP_CREATE;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_PORTNAMEFORMAT_PORTINDEX;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NoPermission;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.PrivilegeConstants;

/**
 * Add a DVPortGroup to an existing distributed virtual switch as a user not
 * having "DVPortgroup.Create" privilege
 *
 * @see PrivilegeConstants#DVPORTGROUP_CREATE
 */
public class Sec002 extends TestBase
{
   private final String testUser = GENERIC_USER;
   private boolean loggedIn;
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDvs = null;
   private ManagedObjectReference dvPortgroupMor = null;
   private DVPortgroupConfigSpec dvPgCfg = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private int roleId = 0;
   private ManagedObjectReference dcMor = null;
   private AuthorizationHelper authHelper;
   private AuthorizationManager authentication = null;

   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a portgroup to an existing"
               + "distributed virtual switch as a user not having "
               + "DVPortgroup.Create privilege");
   }

   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      iFolder = new Folder(connectAnchor);
      iDvs = new DistributedVirtualSwitch(connectAnchor);
      iManagedEntity = new ManagedEntity(connectAnchor);
      rootFolderMor = iFolder.getRootFolder();
      authentication = new AuthorizationManager(connectAnchor);
      dcMor = iFolder.getDataCenter();
      assertNotNull(dcMor, "Failed to find a datacenter");
      dvsConfigSpec = new DVSConfigSpec();
      dvsConfigSpec.setConfigVersion("");
      dvsConfigSpec.setName(getTestId());
      dvsMor = iFolder.createDistributedVirtualSwitch(
               iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
      assertNotNull(dvsMor, "Failed to create the DVS");
      log.info("Successfully created the DVS");
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), true,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      authHelper.setPermissions(dvsMor, DVPORTGROUP_CREATE, testUser, false);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   @Override
   @Test(description = "Add a portgroup to an existing"
               + "distributed virtual switch as a user not having "
               + "DVPortgroup.Create privilege")
   public void test()
      throws Exception
   {
      try {
         dvPgCfg = new DVPortgroupConfigSpec();
         dvPgCfg.setConfigVersion("");
         dvPgCfg.setName(getTestId() + "-pg");
         dvPgCfg.setDescription(DVPORTGROUP_VALID_DESCRIPTION);
         dvPgCfg.setType(DVPORTGROUP_TYPE_EARLY_BINDING);
         dvPgCfg.setNumPorts(1);
         dvPgCfg.setPortNameFormat(DVPORTGROUP_PORTNAMEFORMAT_PORTINDEX);
         iDvs.addPortGroups(dvsMor, new DVPortgroupConfigSpec[] { dvPgCfg });
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = 
        		 com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new NoPermission();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                  actualMethodFault, getExpectedMethodFault()),
                  "MethodFault mismatch!");
      }
   }

   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      if (authHelper != null) {
         status &= authHelper.performSecurityTestsCleanup();
      }
      if (dvsMor != null) {
         status &= iManagedEntity.destroy(dvsMor);
      }
      Assert.assertTrue(status, "Cleanup failed");
      return status;
   }

   @Override
   public MethodFault getExpectedMethodFault()
   {
      NoPermission expectedFault = new NoPermission();
      expectedFault.setObject(dvsMor);
      expectedFault.setPrivilegeId(DVPORTGROUP_CREATE);
      return expectedFault;
   }
}
