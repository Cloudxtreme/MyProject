/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.nrp.updatenetiorm;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.DVSNetworkResourcePool;
import com.vmware.vc.DVSNetworkResourcePoolConfigSpec;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;

/**
 * DESCRIPTION:Update a previously created nrp. Set limit to values 0,-2<BR>
 * TARGET:VC<BR>
 * SETUP:<BR>
 * 1.create the dvs<BR>
 * 2.enable netiorm<BR>
 * 3.Get a default nrp spec<BR>
 * 4.Add the network resource pool to the dvs<BR>
 * 5.Now update the limit in the spec<BR>
 * TEST:<BR>
 * 6.Update the nrp<BR>
 * CLEANUP:<BR>
 * 7.Delete the nrp<BR>
 * 8.Destroy the dvs<BR>
 */
public class Neg011 extends TestBase implements IDataDrivenTest
{
   private DistributedVirtualSwitch idvs;
   private Folder ifolder;
   private ManagedObjectReference dvsMor;
   private DVSNetworkResourcePoolConfigSpec nrpConfigSpec;
   
   @Factory
   @Parameters({"dataFile"})
   public Object[] getTests(@Optional("")String dataFile) throws Exception {
      return TestExecutionUtils.getTests(
                  this.getClass().getName(), dataFile);
   }
   
   public String getTestName() { return getTestId(); }


   /**
    * Setup method Setup the dvs and attach a host to it.
    */
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      ifolder = new Folder(connectAnchor);
      idvs = new DistributedVirtualSwitch(connectAnchor);

      // create the dvs
      dvsMor = ifolder.createDistributedVirtualSwitch(
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
               dvsMor), "NRP enabled on the dvs",
               "NRP is not enabled on the dvs");

      // Get a default nrp spec
      nrpConfigSpec = NetworkResourcePoolHelper.createDefaultNrpSpec();
      

      // Add the network resource pool to the dvs
      idvs.addNetworkResourcePool(dvsMor,
               new DVSNetworkResourcePoolConfigSpec[] { nrpConfigSpec });
      DVSNetworkResourcePool nrp = NetworkResourcePoolHelper.extractNRPByName(connectAnchor, dvsMor,
               nrpConfigSpec.getName());

      // Now update the name in the spec
      nrpConfigSpec.setKey(nrp.getKey());
      
      Long limit = data.getLong("nrpLimit");
      log.info("Limit::"+limit);
      nrpConfigSpec.getAllocationInfo().setLimit(limit);

      return true;
   }

   /**
    * Test method
    */
   @Test(description = "Update a previously created nrp. Set limit to values 0,-2")
   public void test()
      throws Exception
   {
      try {
         // update nrp
         idvs.updateNetworkResourcePool(dvsMor,
                  new DVSNetworkResourcePoolConfigSpec[] { nrpConfigSpec });
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new InvalidArgument();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
   }

   /**
    * Cleanup method Destroy the dvs
    */
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      // Destroy the dvs
      Assert.assertTrue(idvs.destroy(dvsMor), "DVS destroyed",
               "Unable to destroy DVS");

      return true;
   }

   /**
    * Test Description
    */
   public void setTestDescription()
   {
      setTestDescription("Update a previously created nrp. Set limit to values 0,-2");
   }

   @Override
   public MethodFault getExpectedMethodFault()
   {
      return new InvalidArgument();
   }

}
