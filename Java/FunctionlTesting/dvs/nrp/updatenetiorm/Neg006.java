package dvs.nrp.updatenetiorm;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSNetworkResourcePool;
import com.vmware.vc.DVSNetworkResourcePoolConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NotSupported;
import com.vmware.vc.SharesLevel;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

public class Neg006 extends TestBase
{
   private DistributedVirtualSwitch idvs;
   private Folder ifolder;
   private ManagedObjectReference versionNextDvsMor;
   private ManagedObjectReference versionKlDvsMor;
   private DVSNetworkResourcePool nrp;
   private DVSNetworkResourcePoolConfigSpec nrpConfigSpec;

   /**
    * Test method Enable Netiorm on the dvs
    */
   @Override
   @Test(description = "Create a dvs with version 4.0. Call updateNetworkResourcePool on it.")
   public void test()
      throws Exception
   {
      try {
         // update nrp for the version 4.0
         idvs.updateNetworkResourcePool(versionKlDvsMor,
                  new DVSNetworkResourcePoolConfigSpec[] { nrpConfigSpec });
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new NotSupported();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
   }

   /**
    * Cleanup method Destroy the dvs
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      // delete the dvs
      Assert.assertTrue(idvs.destroy(versionNextDvsMor), "DVS Next destroyed",
               "Unable to destroy DVS");
      Assert.assertTrue(idvs.destroy(versionKlDvsMor), "DVS K/L destroyed",
               "Unable to destroy DVS");
      return true;
   }

   /**
    * Setup method Setup the dvs and attach a host to it.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      ifolder = new Folder(connectAnchor);
      idvs = new DistributedVirtualSwitch(connectAnchor);

      // create the dvs
      versionNextDvsMor = ifolder.createDistributedVirtualSwitch("dvs",
               DVSTestConstants.VDS_VERSION_41);
      Assert.assertNotNull(versionNextDvsMor, "DVS Mor null");
      versionKlDvsMor = ifolder.createDistributedVirtualSwitch("dvs-1",
               DVSTestConstants.VDS_VERSION_40);
      Assert.assertNotNull(versionKlDvsMor, "DVS Mor null");

      // enable netiorm
      Assert.assertTrue(idvs.enableNetworkResourceManagement(versionNextDvsMor,
               true), "Netiorm not enabled");

      // Extract the network resource pool related to the vm from the dvs
      nrp = idvs.extractNetworkResourcePool(versionNextDvsMor,
               DVSTestConstants.NRP_VM);

      // set the values in the config spec
      setNrpConfigSpec();

      return true;
   }

   private void setNrpConfigSpec()
   {
      nrpConfigSpec = new DVSNetworkResourcePoolConfigSpec();
      nrpConfigSpec.setKey(nrp.getKey());
      nrpConfigSpec.setAllocationInfo(nrp.getAllocationInfo());
      nrpConfigSpec.getAllocationInfo().setLimit(new Long(-1));
      nrpConfigSpec.getAllocationInfo().getShares().setLevel(SharesLevel.HIGH);
   }

   /**
    * Test Description
    */
   public void setTestDescription()
   {
      setTestDescription("Create a dvs with version 4.0. Call updateNetworkResourcePool on it.");
   }

   @Override
   public MethodFault getExpectedMethodFault()
   {
      return new NotSupported();
   }

}
