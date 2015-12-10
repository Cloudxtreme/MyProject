package dvs.functional.opaquenetwork.privateapi;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DynamicProperty;
import com.vmware.vc.HostDVSConfigSpec;
import com.vmware.vc.HostOpaqueNetworkData;
import com.vmware.vc.HostOpaqueNetworkInfo;
import com.vmware.vc.KeyValue;
import com.vmware.vcqa.util.TestUtil;

public class TS4 extends PrivateApiBase
{
   boolean isHostDvsCreated = false;
   boolean isOn1Created = false;
   String uuid = null;
   String name = null;
   String uuidtz = null;

   @BeforeMethod
   public boolean testSetUp()
      throws Exception
   {
      initialize();
      return true;
   }

   @Test
   public void test()
      throws Exception
   {
      boolean validate = false;
      Vector<String> pnics = new Vector<String>();
      pnics.add("vmnic1");
      // Create VDS with no DvsCreateSpec.isOpaque flag set
      isHostDvsCreated = CreateOpaqueDvs(pnics, null, null);
      assertTrue(isHostDvsCreated,
               "Succeeded to create opaque switch without opaque flag");
      HostDVSConfigSpec configSpec1 = hdvsManager.retrieveDVSConfigSpec(
               hostDVSMgrMor, UUIDHS1);
      DeleteOpaqueDvs();
      isHostDvsCreated = false;

      // Create VDS with DvsCreateSpec.isOpaque flag set to False.
      isHostDvsCreated = CreateOpaqueDvs(pnics, null, "false");
      assertTrue(isHostDvsCreated,
               "Succeeded to create opaque switch with false opaque flag");
      HostDVSConfigSpec configSpec2 = hdvsManager.retrieveDVSConfigSpec(
               hostDVSMgrMor, UUIDHS1);
      DeleteOpaqueDvs();
      isHostDvsCreated = false;

      Vector<String> ignorePropertyList = new Vector<String>();
      ignorePropertyList.add("HostDVSConfigSpec.ModifyVendorSpecificDvsConfig");
      ignorePropertyList.add("HostDVSConfigSpec.ModifyVendorSpecificHostMemberConfig");
      ignorePropertyList.add("HostDVSConfigSpec.VendorSpecificHostMemberConfig");
      validate = TestUtil.compareObject(configSpec2, configSpec1, ignorePropertyList);
      assertTrue(validate, "configSpec1 and configSpec2 are the same",
               "configSpec1 and configSpec2 are not the same");

      // Create VDS with DvsCreateSpec.isOpaque flag set to True.
      isHostDvsCreated = CreateOpaqueDvs(pnics, null, "true");
      assertTrue(isHostDvsCreated,
               "Succeeded to create opaque switch with false opaque flag");
      HostDVSConfigSpec configSpec3 = hdvsManager.retrieveDVSConfigSpec(
               hostDVSMgrMor, UUIDHS1);
      DeleteOpaqueDvs();
      isHostDvsCreated = false;

      validate = TestUtil.compareObject(configSpec3, configSpec2, ignorePropertyList);
      assertTrue(validate, "configSpec2 and configSpec3 are the same",
               "configSpec2 and configSpec3 are not the same");
   }

   @AfterMethod
   public boolean testCleanUp()
      throws Exception
   {
      if (isHostDvsCreated) {
         DeleteOpaqueDvs();
      }
      return true;
   }

}
