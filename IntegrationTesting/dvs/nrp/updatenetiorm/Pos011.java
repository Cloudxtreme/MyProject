package dvs.nrp.updatenetiorm;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSNetworkResourcePool;
import com.vmware.vc.DVSNetworkResourcePoolConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.SharesLevel;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;

/**
 * Enable network resource management on a dvs with config version as null
 */
public class Pos011 extends TestBase
{
   private DistributedVirtualSwitch idvs;
   private Folder ifolder;
   private ManagedObjectReference dvsMor;
   private DVSNetworkResourcePool nrp;
   private DVSNetworkResourcePoolConfigSpec nrpConfigSpec;

   /**
    * Test method Enable Netiorm on the dvs
    */
   @Override
   @Test(description = "Enable network resource management on a dvs with config version as null")
   public void test()
      throws Exception
   {
      // update nrp
      idvs.updateNetworkResourcePool(dvsMor,
               new DVSNetworkResourcePoolConfigSpec[] { nrpConfigSpec });

      nrp = idvs.extractNetworkResourcePool(dvsMor, DVSTestConstants.NRP_VM);

      Assert.assertNotNull(nrp, "NRP is null");
      Assert.assertNotNull(nrp.getConfigVersion(), "Config version is null");
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
      return idvs.destroy(dvsMor);
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
      dvsMor = ifolder.createDistributedVirtualSwitch("dvs",
               DVSTestConstants.VDS_VERSION_41);

      // enable netiorm
      Assert.assertTrue(idvs.enableNetworkResourceManagement(dvsMor, true),
               "Netiorm not enabled");

      Assert.assertTrue(NetworkResourcePoolHelper.isNrpEnabled(connectAnchor,
               dvsMor), "Nrp is not enabled");

      // Extract the network resource pool related to the vm from the dvs
      nrp = idvs.extractNetworkResourcePool(dvsMor, DVSTestConstants.NRP_VM);

      // set the values in the config spec
      setNrpConfigSpec();

      return true;
   }

   private void setNrpConfigSpec()
   {
      nrpConfigSpec = new DVSNetworkResourcePoolConfigSpec();
      nrpConfigSpec.setKey(nrp.getKey());
      nrpConfigSpec.setConfigVersion(null);
      nrpConfigSpec.setAllocationInfo(nrp.getAllocationInfo());
      nrpConfigSpec.getAllocationInfo().setLimit(new Long(-1));
      nrpConfigSpec.getAllocationInfo().getShares().setLevel(SharesLevel.HIGH);
   }

   /**
    * Test Description
    */
   public void setTestDescription()
   {
      setTestDescription("Enable network resource management on a dvs with config version as null");
   }

}
