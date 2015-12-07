package dvs.nrp.enablenetiorm;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;

/**
 * Enable network resource management on a dvs
 */
public class Pos001 extends TestBase
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
   @Test(description = "Enable network resource management on a dvs")
   public void test()
      throws Exception
   {
      // enable netiorm
      Assert.assertTrue(idvs.enableNetworkResourceManagement(dvsMor, true),
               "Netiorm not enabled");

      Assert.assertTrue(NetworkResourcePoolHelper.isNrpEnabled(connectAnchor,
               dvsMor), "NRP enabled on the dvs",
               "NRP is not enabled on the dvs");
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
      Assert.assertNotNull(hostMor, "DVS Mor null");
      // create the dvs
      dvsMor = ifolder.createDistributedVirtualSwitch("dvs",
               DVSTestConstants.VDS_VERSION_41, hostMor);
      Assert.assertNotNull(dvsMor, "DVS Mor null");
      return true;
   }

   /**
    * Test Description
    */
   public void setTestDescription()
   {
      setTestDescription("Enable network resource management on a dvs");
   }

}
