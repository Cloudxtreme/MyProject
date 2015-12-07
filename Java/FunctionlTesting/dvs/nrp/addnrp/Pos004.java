/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.nrp.addnrp;

import static com.vmware.vcqa.TestConstants.ESX_PASSWORD;
import static com.vmware.vcqa.TestConstants.ESX_USERNAME;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.vim.MessageConstants.LOGIN_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.LOGIN_PASS;

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
import com.vmware.vc.OptionValue;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.HostSystemInformation;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;
import com.vmware.vcqa.vim.option.OptionManager;
import com.vmware.vcqa.vim.profile.ProfileConstants;

/**
 * DESCRIPTION:Add nrp on the dvs. Opt the pnic using advanced options<BR>
 * TARGET:VC<BR>
 * SETUP:<BR>
 * 1.Get standalone hostmors<BR>
 * 2.Retrieve initial profiles<BR>
 * 3.Create the dvs<BR>
 * 4.Enable netiorm<BR>
 * TEST:<BR>
 * 5.Add the network resource pool to the dvs<BR>
 * 6.Verify the nrp with the dvs<BR>
 * 7.Verify the vsi state<BR>
 * 8.Opt out the pnic using advanced options<BR>
 * CLEANUP:<BR>
 * 9.Remove the nrp<BR>
 * 10.Reapply the profiles<BR>
 * 11.Remove the dvs<BR>
 */
public class Pos004 extends TestBase
{
   private SessionManager sessionManager = null;
   private DistributedVirtualSwitch idvs;
   private ManagedObjectReference dvsMor;
   private ManagedObjectReference hostMor1;
   private HostConfigSpec srcHostProfile1;
   private OptionManager iOptionManager;
   private ManagedObjectReference optionManagerMor;
   private OptionValue opt;
   private ManagedObjectReference authMorHost;
   private HostSystem hostSystem;

   /**
    * Setup method Setup the dvs and attach a host to it.
    */
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      sessionManager = new SessionManager(connectAnchor);
      Folder folder = new Folder(connectAnchor);
      idvs = new DistributedVirtualSwitch(connectAnchor);
      hostSystem = new HostSystem(connectAnchor);

      // get a standalone hostmors
      // We need at at least 2 hostmors
      Map<ManagedObjectReference, HostSystemInformation> hostMors = hostSystem.getAllHosts(
               VersionConstants.ESX4x, HostSystemConnectionState.CONNECTED);

      Assert.assertTrue(hostMors.size() >= 1, "Unable to find a host");

      Set<ManagedObjectReference> hostSet = hostMors.keySet();
      Iterator<ManagedObjectReference> hostIterator = hostSet.iterator();
      if (hostIterator.hasNext()) {
         hostMor1 = hostIterator.next();
         srcHostProfile1 = NetworkResourcePoolHelper.extractHostConfigSpec(
                  connectAnchor, ProfileConstants.SRC_PROFILE + getTestId(),
                  hostMor1);
      }

      // create the dvs
      dvsMor = folder.createDistributedVirtualSwitch(
               DVSTestConstants.DVS_CREATE_NAME_PREFIX + getTestId(),
               DVSUtil.getvDsVersion());
      Assert.assertNotNull(dvsMor, "DVS created", "DVS not created");

      Assert.assertNotNull(idvs.addPortGroup(dvsMor,
               DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING, 4,
               DVSTestConstants.DV_PORTGROUP_CREATE_NAME_PREFIX + getTestId()),
               "Unable to add portgroup");

      // enable netiorm
      Assert.assertTrue(idvs.enableNetworkResourceManagement(dvsMor, true),
               "Netiorm not enabled");

      Assert.assertTrue(NetworkResourcePoolHelper.isNrpEnabled(connectAnchor,
               dvsMor), "NRP is not enabled on the dvs");

      return true;
   }

   /**
    * Test method Enable Netiorm on the dvs
    */
   @Test
   public void test()
      throws Exception
   {
      DVSNetworkResourcePoolConfigSpec nrpConfigSpec = NetworkResourcePoolHelper.createDefaultNrpSpec();
      DVSNetworkResourcePoolConfigSpec[] nrpConfigSpecs = new DVSNetworkResourcePoolConfigSpec[] { nrpConfigSpec };

      // Add the network resource pool to the dvs
      idvs.addNetworkResourcePool(dvsMor, nrpConfigSpecs);

      // Query the nrp by name
      DVSNetworkResourcePool nrp = NetworkResourcePoolHelper.extractNRPByName(
               connectAnchor, dvsMor, nrpConfigSpec.getName());
      DVSNetworkResourcePool[] nrps = new DVSNetworkResourcePool[] { nrp };

      // verify with the dvs
      Assert.assertTrue(NetworkResourcePoolHelper.verifyNrpFromDvs(
               connectAnchor, dvsMor, nrpConfigSpec), "NRP verified from dvs",
               "NRP not matching with DVS nrp");

      NetworkResourcePoolHelper.addHostsToDvs(dvsMor, hostMor1, connectAnchor);

      Assert.assertTrue(NetworkResourcePoolHelper.verifyUplinkPortsWithNetDvs(
               dvsMor, hostMor1, connectAnchor, nrps, nrpConfigSpecs),
               "Uplink ports verified", "Uplink ports not verified");

      String pnic = NetworkResourcePoolHelper.addFreePnicToDvs(connectAnchor,
               dvsMor, hostMor1);

      // verify the vsi state
      Assert.assertTrue(NetworkResourcePoolHelper.verifyVsiState(connectAnchor,
               dvsMor, hostMor1, pnic, nrp, nrpConfigSpec),
               "Vsi state not verified");

      String hostName = this.hostSystem.getHostName(hostMor1);
      ConnectAnchor anchor = new ConnectAnchor(hostName,
               data.getInt(TestConstants.TESTINPUT_PORT));
      assertNotNull(SessionManager.login(anchor, ESX_USERNAME,
               ESX_PASSWORD)!=null, LOGIN_PASS + "to primary host.", LOGIN_FAIL
               + " into primary host");
      iOptionManager = new OptionManager(anchor);
      optionManagerMor = iOptionManager.getOptionManager();

      // Opt out the pnic using advanced options
      opt = new OptionValue();
      opt.setKey(DVSTestConstants.NRP_KEY);
      opt.setValue(pnic);
      iOptionManager.updateOptions(optionManagerMor, new OptionValue[] { opt });
      Thread.sleep(20000);
      boolean result = NetworkResourcePoolHelper.verifyPnicOptedOut(
               connectAnchor, dvsMor, hostMor1, pnic, "advopt");

      opt.setValue("");
      iOptionManager.updateOptions(optionManagerMor, new OptionValue[] { opt });

      Assert.assertTrue(SessionManager.logout(anchor),
               "Logged out from host", "Unable to logout from the host");

      Assert.assertTrue(result, "Pnic opt out verified",
               "Pnic opt out not verified");
   }

   /**
    * Cleanup method Destroy the dvs
    */
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      Assert.assertTrue(NetworkResourcePoolHelper.applyHostConfig(
               connectAnchor, hostMor1, srcHostProfile1),
               "Profile applied on host 1", "Unable to apply profile on host 1");
      Assert.assertTrue(idvs.destroy(dvsMor), "DVS destroyed",
               "Unable to destroy DVS");
      return true;
   }

   /**
    * Test Description
    */
   public void setTestDescription()
   {
      setTestDescription("Add nrp on the dvs. Opt the pnic using advanced options");
   }

}
