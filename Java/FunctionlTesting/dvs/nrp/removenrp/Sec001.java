/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.nrp.removenrp;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVSWITCH_RESOURCEMANAGEMENT;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSNetworkResourcePool;
import com.vmware.vc.DVSNetworkResourcePoolConfigSpec;
import com.vmware.vc.HostConfigSpec;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.HostSystemInformation;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;
import com.vmware.vcqa.vim.profile.ProfileConstants;

/**
 * Remove a NRP on a dvs by a user having DVSwitch.ResourceManagement privilege
 */
public class Sec001 extends TestBase
{
   private DistributedVirtualSwitch dvs;
   private ManagedObjectReference dvsMor;
   private DVSNetworkResourcePool nrp;
   private ManagedObjectReference hostMor1;
   private ManagedObjectReference hostMor2;
   private HostConfigSpec srcHostProfile1;
   private HostConfigSpec srcHostProfile2;
   private final String testUser = GENERIC_USER;
   private AuthorizationHelper authHelper;

   /**
    * Setup method Setup the dvs and attach a host to it.
    */
   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      Folder folder = new Folder(connectAnchor);
      dvs = new DistributedVirtualSwitch(connectAnchor);
      HostSystem hs = new HostSystem(connectAnchor);

      // We need at at least 2 hostmors
      Map<ManagedObjectReference, HostSystemInformation> hostMors = hs.getAllHosts(VersionConstants.ALL_ESX, HostSystemConnectionState.CONNECTED);

      Assert.assertTrue(hostMors.size() >= 2, "Unable to find two hosts");

      Set<ManagedObjectReference> hostSet = hostMors.keySet();
      Iterator<ManagedObjectReference> hostIterator = hostSet.iterator();
      if (hostIterator.hasNext()) {
         hostMor1 = hostIterator.next();
         srcHostProfile1 = NetworkResourcePoolHelper.extractHostConfigSpec(
                  connectAnchor, ProfileConstants.SRC_PROFILE + getTestId(),
                  hostMor1);
      }
      if (hostIterator.hasNext()) {
         hostMor2 = hostIterator.next();
         srcHostProfile2 = NetworkResourcePoolHelper.extractHostConfigSpec(
                  connectAnchor, ProfileConstants.SRC_PROFILE + getTestId()
                           + "-1", hostMor2);
      }

      // create the dvs
      dvsMor = folder.createDistributedVirtualSwitch(getTestId(),
               DVSUtil.getvDsVersion());
      Assert.assertNotNull(dvsMor, "DVS created", "DVS not created");

      // enable netiorm
      Assert.assertTrue(dvs.enableNetworkResourceManagement(dvsMor, true),
               "Netiorm not enabled");

      Assert.assertTrue(NetworkResourcePoolHelper.isNrpEnabled(connectAnchor,
               dvsMor), "NRP enabled on the dvs",
               "NRP is not enabled on the dvs");

      // set the values in the config spec
      DVSNetworkResourcePoolConfigSpec nrpConfigSpec = NetworkResourcePoolHelper.createDefaultNrpSpec();

      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), false,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      authHelper.setPermissions(dvsMor, DVSWITCH_RESOURCEMANAGEMENT, testUser,
               false);
      authHelper.performSecurityTestsSetup(testUser);

      // add nrp
      dvs.addNetworkResourcePool(dvsMor,
               new DVSNetworkResourcePoolConfigSpec[] { nrpConfigSpec });

      // verify that the nrp got added to the dvs
      nrp = NetworkResourcePoolHelper.extractNRPByName(connectAnchor, dvsMor,
               nrpConfigSpec.getName());

      Assert.assertNotNull(nrp, "NRP was added successfully",
               "NRP was not added successfully");

      return true;
   }

   /**
    * Test method Enable Netiorm on the dvs
    */
   @Override
   @Test
   public void test()
      throws Exception
   {
      // remove the network resource pool
      dvs.removeNetworkResourcePool(dvsMor, new String[] { nrp.getKey() });
   }

   /**
    * Cleanup method Destroy the dvs
    */
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      Assert.assertTrue(authHelper.performSecurityTestsCleanup(),
               "Authorization helper cleanup not successful");

      // delete the dvs
      Assert.assertTrue(NetworkResourcePoolHelper.applyHostConfig(
               connectAnchor, hostMor1, srcHostProfile1),
               "Profile applied on host 1", "Unable to apply profile on host 1");

      Assert.assertTrue(NetworkResourcePoolHelper.applyHostConfig(
               connectAnchor, hostMor2, srcHostProfile2),
               "Profile applied on host 2", "Unable to apply profile on host 2");

      Assert.assertTrue(dvs.destroy(dvsMor), "DVS destroyed",
               "Unable to destroy DVS");

      return true;
   }

   /**
    * Test Description
    */
   public void setTestDescription()
   {
      setTestDescription("Add a NRP on a dvs by a user "
               + "having DVSwitch.ResourceManagement privilege");
   }
}
