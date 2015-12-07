/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigureportgroups;

import static com.vmware.vcqa.TestConstants.*;
import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;
import static com.vmware.vcqa.vim.PrivilegeConstants.*;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.*;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NoPermission;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.PrivilegeConstants;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

/**
 * Reconfigure a DVPortgroup in a DVS with a user not having
 * 'DVPortgroup.Modify' privilege<br>
 */
public class Sec002 extends TestBase
{
   private Folder iFolder = null;
   private ManagedObjectReference dvsMor = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private DVPortgroupConfigSpec dvpgCfg = null;
   private ManagedObjectReference dvpgMor = null;
   private ManagedObjectReference dcMor = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private AuthorizationHelper authHelper;
   private final String testUser = GENERIC_USER;

   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      iFolder = new Folder(connectAnchor);
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      dcMor = iFolder.getDataCenter();
      assertNotNull(dcMor, DC_MOR_GET_PASS, DC_MOR_GET_FAIL);
      dvsMor = iFolder.createDistributedVirtualSwitch(getTestId());
      assertNotNull(dvsMor, DVS_CREATE_PASS, DVS_CREATE_FAIL);
      List<ManagedObjectReference> dvpgMors = null;
      dvpgCfg = new DVPortgroupConfigSpec();
      dvpgCfg.setConfigVersion("");
      dvpgCfg.setName(getTestId() + "-portgroup");
      dvpgCfg.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
      dvpgCfg.setType(DVPORTGROUP_TYPE_EARLY_BINDING);
      dvpgCfg.setPortNameFormat(DVSTestConstants.DVPORTGROUP_PORTNAMEFORMAT_PORTINDEX);
      dvpgMors = iDVSwitch.addPortGroups(dvsMor,
               new DVPortgroupConfigSpec[] { dvpgCfg });
      assertNotEmpty(dvpgMors, "Added DVPortgroup", "Failed to add DVPortgroup");
      dvpgMor = dvpgMors.get(0);
      dvpgCfg.setConfigVersion(iDVPortgroup.getConfigInfo(dvpgMor).getConfigVersion());
      dvpgCfg.setName(getTestId() + "-pg1");
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), true,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      authHelper.setPermissions(dvpgMor, DVPORTGROUP_MODIFY, testUser, false);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   @Override
   @Test(description = "Reconfigure a DVPortgroup on an existing"
            + "distributed virtual switch as a user not having "
            + "'DVPortgroup.Modify' privilege")
   public void test()
      throws Exception
   {
      boolean status = false;
      try {
         iDVPortgroup.reconfigure(dvpgMor, dvpgCfg);
      } catch (final Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         final NoPermission expectedMethodFault = new NoPermission();
         expectedMethodFault.setObject(dvpgMor);
         expectedMethodFault.setPrivilegeId(PrivilegeConstants.DVPORTGROUP_MODIFY);
         status = TestUtil.checkMethodFault(actualMethodFault,
                  expectedMethodFault);
      }
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started. Destroy
    * the portgroup, followed by the distributed virtual switch
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      if (authHelper != null) {
         status &= authHelper.performSecurityTestsCleanup();
      }
      if (dvsMor != null) {
         status &= iDVSwitch.destroy(dvsMor);
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
