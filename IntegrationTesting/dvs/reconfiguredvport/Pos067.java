/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvport;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ConfigSpecOperation;
import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupPolicy;
import com.vmware.vc.DVSNetworkResourcePool;
import com.vmware.vc.DVSNetworkResourcePoolConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.DVPortSetting;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;

/**
 * DESCRIPTION:<BR>
 * 1)reconfigure a dvPortgroup to have an nrp associated to it.<BR>
 * 2)Set the nrpOverrideAllowed flag to true.<BR>
 * 3)Reconfigure a dvPort to associate a different nrp.<BR>
 * TARGET: VC <BR>
 *
 */
public class Pos067 extends TestBase
{
   private DistributedVirtualSwitch dvs;
   private DistributedVirtualPortgroup dvpg;
   private ManagedObjectReference dvsMor;
   private DVSNetworkResourcePool[] nrp;
   private DVSNetworkResourcePoolConfigSpec[] nrpConfigSpec;
   private DVPortgroupConfigSpec dvpgSpec;
   private List<ManagedObjectReference> pgMors;
   private static int nrpCount = 2;
   private DVPortConfigSpec[] dvPortSpec;

   /**
    * Setup method Setup the dvs and attach a host to it.
    */
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      Folder ifolder = new Folder(connectAnchor);
      dvs = new DistributedVirtualSwitch(connectAnchor);
      dvpg = new DistributedVirtualPortgroup(connectAnchor);
      // add a portgroups
      dvpgSpec = new DVPortgroupConfigSpec();
      nrpConfigSpec = new DVSNetworkResourcePoolConfigSpec[nrpCount];
      nrp = new DVSNetworkResourcePool[nrpCount];

      // create the dvs
      dvsMor = ifolder.createDistributedVirtualSwitch(
               DVSTestConstants.DVS_CREATE_NAME_PREFIX + getTestId(),
               DVSUtil.getvDsVersion());
      Assert.assertNotNull(dvsMor, "DVS created", "DVS not created");

      // enable netiorm
      Assert.assertTrue(dvs.enableNetworkResourceManagement(dvsMor, true),
               "Netiorm not enabled");

      Assert.assertTrue(NetworkResourcePoolHelper.isNrpEnabled(connectAnchor,
               dvsMor), "NRP enabled on the dvs",
               "NRP is not enabled on the dvs");

      // Get a default nrp spec
      for (int i = 0; i < nrpCount; i++) {
         nrpConfigSpec[i] = NetworkResourcePoolHelper.createDefaultNrpSpec(getTestId()
                  + i);
      }

      // Add the network resource pool to the dvs
      dvs.addNetworkResourcePool(dvsMor, nrpConfigSpec);

      Assert.assertTrue(NetworkResourcePoolHelper.verifyFromDvs(connectAnchor,
               dvsMor, nrpConfigSpec), "NRP verified from dvs",
               "NRP not matching with DVS nrp");

      for (int i = 0; i < nrpCount; i++) {
         nrp[i] = NetworkResourcePoolHelper.extractNRPByName(connectAnchor,
                  dvsMor, nrpConfigSpec[i].getName());

      }

      dvpgSpec = NetworkResourcePoolHelper.createDvpgSpec(connectAnchor, getTestId(), dvsMor);
      DVPortgroupPolicy dvportgroupPolicy = new DVPortgroupPolicy();
      dvportgroupPolicy.setNetworkResourcePoolOverrideAllowed(true);
      dvpgSpec.setPolicy(dvportgroupPolicy);
      NetworkResourcePoolHelper.associateNrpToDvpgSpec(dvpgSpec, nrp[0]);

      pgMors = dvs.addPortGroups(dvsMor,
               new DVPortgroupConfigSpec[] { dvpgSpec });
      Assert.assertNotEmpty(pgMors, "Portgroups added successfully",
               "Portgroups could not be added");

      Assert.assertTrue(NetworkResourcePoolHelper.isNrpAssociatedToDvpg(
               connectAnchor, pgMors, nrp[0].getKey()),
               "Verfied nrp is attached to dvpg:" + nrp[0].getName(),
               "Unable to verify nrp attached to dvpg");

      // fetch all the dvports of a portgroup
      List<String> dvports = dvpg.getPortKeys(pgMors.get(0));
      Assert.assertNotEmpty(dvports, "Ports added successfully",
               "Ports could not be added");
      dvPortSpec = dvs.getPortConfigSpec(dvsMor, (String[]) dvports.toArray(new String[dvports.size()]));
      for (int i = 0; i < dvPortSpec.length; i++) {
         DVPortSetting dvPortSetting = dvPortSpec[i].getSetting();
         if (dvPortSetting instanceof VMwareDVSPortSetting) {
            VMwareDVSPortSetting VMwareDVSPort =
               (VMwareDVSPortSetting) dvPortSetting;
            VMwareDVSPort.setLacpPolicy(null);
            dvPortSpec[i].setSetting(VMwareDVSPort);
         }
         dvPortSpec[i].setOperation(ConfigSpecOperation.EDIT.value());
      }

      return true;
   }

   /**
    * Test method
    */
   @Test(description = "Reconfigure dvPorts to have a different nrp associated to it(nrpOverrideAllowed=true)")
   public void test()
      throws Exception
   {
      NetworkResourcePoolHelper.associateNrpToDvportSpec(dvPortSpec, nrp[1]);

      Assert.assertTrue(dvs.reconfigurePort(dvsMor, dvPortSpec),
               "Successfully reconfigured dvports with a different nrp attached",
               "Unable to reconfigure dvports with a different nrp attached");

      Assert.assertTrue(NetworkResourcePoolHelper.isNrpAssociatedToDvport(
               connectAnchor, dvpg.getPorts(pgMors.get(0)), nrp[1].getKey()),
               "Verfied nrp is attached to all the dvports of dvpg" ,
               "Unable to verify nrp attached to all dvports of dvpg");
   }

   /**
    * Cleanup method Destroy the dvs
    */
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      Assert.assertTrue(dvs.destroy(dvsMor), "DVS destroyed",
               "Unable to destroy DVS");

      return true;
   }

   /**
    * Test Description
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Reconfigure dvPorts to have a different nrp associated to it(nrpOverrideAllowed=true)");
   }
}
