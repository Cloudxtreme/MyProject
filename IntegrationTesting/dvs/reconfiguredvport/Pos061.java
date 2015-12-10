/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc.  All rights reserved. -- VMware Confidential
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
import com.vmware.vc.DistributedVirtualPort;
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
 * DESCRIPTION:Associate/Disassociate a predefined created nrp with a dvPort<BR>
 * TARGET: VC <BR>
 * SETUP:<BR>
 * 1. Create a vDS<BR>
 * 2. Enable netiorm <BR>
 * 3. Add a nrp to it<BR>
 * 4. Create the dv port<BR>
 * TEST:<BR>
 * 5. Reconfigure a port on the dvs with nrp associated to it<BR>
 * 6. Verify that the port is associated with the nrp<BR>
 * CLEANUP:<BR>
 * 7. Destroy the dvs<BR>
 */
public class Pos061 extends TestBase
{
   private DistributedVirtualSwitch dvs;
   private DistributedVirtualPortgroup dvpg;
   private ManagedObjectReference dvsMor;
   private DVSNetworkResourcePool nrp;
   private DVSNetworkResourcePoolConfigSpec nrpConfigSpec;
   private DVPortgroupConfigSpec[] dvpgSpec;
   private List<ManagedObjectReference> pgMors;
   private DVPortConfigSpec dvPortSpec;

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

      dvpgSpec = new DVPortgroupConfigSpec[1];

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

      nrp = dvs.extractNetworkResourcePool(dvsMor, DVSTestConstants.NRP_VMOTION);

      // create the spec
      dvpgSpec[0] = NetworkResourcePoolHelper.createDvpgSpec(connectAnchor, getTestId(), dvsMor);
      DVPortgroupPolicy dvportgroupPolicy = new DVPortgroupPolicy();
      dvportgroupPolicy.setNetworkResourcePoolOverrideAllowed(true);
      dvpgSpec[0].setPolicy(dvportgroupPolicy);

      // add the portgroup
      pgMors = dvs.addPortGroups(dvsMor, dvpgSpec);
      Assert.assertNotEmpty(pgMors, "Portgroup added successfully",
               "Portgroup could not be added");

      // fetch the dvports
      List<DistributedVirtualPort> dvports = dvpg.getPorts(pgMors.get(0));
      Assert.assertNotEmpty(dvports, "Ports added successfully",
               "Ports could not be added");
      dvPortSpec = dvs.getPortConfigSpec(dvports.get(0));
      DVPortSetting dvPortSetting = dvPortSpec.getSetting();
      if (dvPortSetting instanceof VMwareDVSPortSetting) {
         VMwareDVSPortSetting VMwareDVSPort =
            (VMwareDVSPortSetting) dvPortSetting;
         VMwareDVSPort.setLacpPolicy(null);
         dvPortSpec.setSetting(VMwareDVSPort);
      }
      dvPortSpec.setOperation(ConfigSpecOperation.EDIT.value());
      return true;
   }

   /**
    * Test method
    */
   @Test(description = "Associate/Disassociate a predefined nrp with a dvPortgroup")
   public void test()
      throws Exception
   {

      NetworkResourcePoolHelper.associateNrpToDvportSpec(dvPortSpec, nrp);
      Assert.assertTrue(dvs.reconfigurePort(dvsMor,
               new DVPortConfigSpec[] { dvPortSpec }),
               "Successfully reconfigured dvport with nrp attached",
               "Unable to reconfigure dvport with nrp attached");

      List<DistributedVirtualPort> dvports = dvpg.getPorts(pgMors.get(0));

      Assert.assertNotEmpty(dvports, "Ports not empty", "Ports list empty");
      Assert.assertTrue(NetworkResourcePoolHelper.isNrpAssociatedToDvport(
               connectAnchor, dvports, nrp.getKey()),
               "Verfied nrp is attached to dvport",
               "Unable to verify nrp attached to dvport");
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
      setTestDescription("Associate/Disassociate a predefined nrp with a dvPortgroup");
   }

}
