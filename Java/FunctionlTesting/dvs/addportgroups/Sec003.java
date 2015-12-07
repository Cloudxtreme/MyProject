/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.util.Assert.assertNotEmpty;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.DC_MOR_GET_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.DC_MOR_GET_PASS;
import static com.vmware.vcqa.vim.MessageConstants.DVS_CREATE_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.DVS_CREATE_PASS;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVPORTGROUP_DELETE;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectNotFound;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;


/**
 * DESCRIPTION:<br>
 * Destroy a DVPortGroup by user having 'DVPortgroup.Delete' privilege on it and
 * it's parent folder.<br>
 * SETUP:<br>
 * 1. Create a DVSwitch, and get the uplink DVPortGroup.<br>
 * 2. Set 'DVPortgroup.Delete' privilege on dvPortgroup and it's parent folder.<br>
 * 3. Logout Administrator and login as test user.<br>
 * TEST:<br>
 * 4. Destroy DVPortGroup operation should be successful.<br>
 * CLEANUP:<br>
 * 5. Logout test user and login as Administrator.<br>
 * 6. Destroy the DVS.<br>
 */
public class Sec003 extends TestBase
{
   private ManagedObjectReference dvsMor;
   private ManagedObjectReference dvPgMor;
   private DistributedVirtualSwitch iDVSwitch;
   private AuthorizationHelper authHelper;
   private final String testUser = GENERIC_USER;
   private final String privilege = DVPORTGROUP_DELETE;
   private ManagedObjectReference dcMor = null;

   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      final Folder iFolder = new Folder(connectAnchor);
      dcMor = iFolder.getDataCenter();
      assertNotNull(dcMor, DC_MOR_GET_PASS, DC_MOR_GET_FAIL);
      final ManagedObjectReference nwFolderMor = iFolder.getNetworkFolder(dcMor);
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      final DVSConfigSpec dvsCfg = new DVSConfigSpec();
      dvsCfg.setConfigVersion("");
      dvsCfg.setName(getTestId());
      log.info("Creating vDS: " + dvsCfg.getName());
      dvsMor = iFolder.createDistributedVirtualSwitch(nwFolderMor, dvsCfg);
      assertNotNull(dvsMor, DVS_CREATE_PASS, DVS_CREATE_FAIL);
      log.info("Getting the uplink DVPortGroup...");
      final List<ManagedObjectReference> dvPgMors = iDVSwitch.getUplinkPortgroups(dvsMor);
      assertNotEmpty(dvPgMors, "Failed to get uplink DVPortGroup");
      dvPgMor = dvPgMors.get(0);
      return true;
   }

   @Override
   @Test(description = "Destroy a DVPortGroup by a user having "
               + "'DVPortgroup.Delete' privilege on it and it's parent folder.")
   public void test()
      throws Exception
   {
      boolean status = false;
      authHelper =
               new AuthorizationHelper(connectAnchor, getTestId(), data
                        .getString(TestConstants.TESTINPUT_USERNAME), data
                        .getString(TestConstants.TESTINPUT_PASSWORD));
      // Setting permission on dcMor (can't set on N/W folder) & DVPG.
      authHelper.setPermissions(
               new ManagedObjectReference[] { dcMor, dvPgMor }, privilege,
               testUser, false);
      if (authHelper.performSecurityTestsSetup(testUser)
               && this.iDVSwitch.asyncDestroy(this.dvPgMor) != null
               && authHelper != null) {
         /*
          * Catching ManagedObjectNotFound exception as dvPgMor might be deleted before invoking   retrieveEntityPermissions api
          */
         try {
            status = authHelper.performSecurityTestsCleanup();
         } catch(Exception eExcep) {
            ManagedObjectNotFound e = (ManagedObjectNotFound)com.vmware.vcqa.util.TestUtil.getFault(eExcep);
            log.warn("Got ManagedObjectNotFound exception as dvPgMor was deleted before invoking retrieveEntityPermissions api");
         }

         status = !this.iDVSwitch.isExists(dvPgMor);
      }
      assertTrue(status, "Successfully destroyed uplinkPG",
               "Failed to destroy uplinkPG");
   }

   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean cleanedUp = true;
      if (dvsMor != null) {
         cleanedUp &= iDVSwitch.destroy(dvsMor);
      }
      return cleanedUp;
   }
}
