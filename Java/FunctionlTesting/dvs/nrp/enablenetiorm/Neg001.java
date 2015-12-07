package dvs.nrp.enablenetiorm;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NotSupported;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

/**
 * Enable network resource management on a dvs version 4.0
 */
public class Neg001 extends TestBase
{
   DistributedVirtualSwitch idvs;
   Folder ifolder;
   HostSystem ihs;
   ManagedObjectReference hostMor;
   ManagedObjectReference dvsMor;

   /**
    * Test method Enable Netiorm on the dvs
    */
   @Override
   @Test(description = "Enable network resource management on a dvs version 4.0")
   public void test()
      throws Exception
   {
      try {
         // enable netiorm. This call will throw Not Supported exception.
         idvs.enableNetworkResourceManagement(dvsMor, true);
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
      Assert.assertTrue(idvs.destroy(dvsMor), "DVS destroyed",
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
      ihs = new HostSystem(connectAnchor);
      // get a standalone hostmor
      hostMor = ihs.getStandaloneHost();
      // create the dvs
      dvsMor = ifolder.createDistributedVirtualSwitch("dvs",
               DVSTestConstants.VDS_VERSION_40, hostMor);
      Assert.assertNotNull(dvsMor, "DVS created", "DVS not created");
      return true;
   }

   /**
    * Test Description
    */
   public void setTestDescription()
   {
      setTestDescription("Enable network resource management on a dvs version 4.0");
   }

   @Override
   /**
    * Return the expected fault
    */
   public MethodFault getExpectedMethodFault()
   {
      return new NotSupported();
   }
}
