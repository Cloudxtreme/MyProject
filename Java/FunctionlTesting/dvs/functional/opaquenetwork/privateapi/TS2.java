package dvs.functional.opaquenetwork.privateapi;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.HostDVSConfigSpec;
import com.vmware.vc.KeyValue;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

public class TS2 extends PrivateApiBase
{
   boolean isHostDvsCreated = false;
   boolean isOn1Created = false;
   String UUIDTZ3 = "aa aa aa aa aa aa aa aa-bb bb bb bb bb bb bb bb";
   String uuid = null;
   String name = null;
   String uuidtz = null;

   @BeforeMethod
   public boolean testSetUp()
      throws Exception
   {
      initialize();
      Vector<String> pnics = new Vector<String>();
      pnics.add("vmnic1");
      isHostDvsCreated = CreateDefaultOpaqueDvs(pnics);

      return true;
   }

   @Test
   public void test()
      throws Exception
   {
      HostDVSConfigSpec oldConfigSpec = hdvsManager.retrieveDVSConfigSpec(
               hostDVSMgrMor, UUIDHS1);
      HostDVSConfigSpec configSpec = new HostDVSConfigSpec();
      configSpec.setUuid(UUIDHS1);
      // HostDVSConfigSpec configSpec =
      // hdvsManager.retrieveDVSConfigSpec(hostDVSMgrMor, UUIDHS1);
      HashMap<String, String> extraConfigHash = new HashMap<String, String>();
      String key1 = "com.vmware.extraconfig.opaqueDvs.status";
      String val1 = "up";
      String key2 = "com.vmware.extraconfig.opaqueDvs.pnicZone";
      String val2 = UUIDTZ1 + "," + UUIDTZ2 + "," + UUIDTZ3;
      extraConfigHash.put(key1, val1);
      extraConfigHash.put(key2, val2);
      Vector<KeyValue> keyValueVector = new Vector<KeyValue>();
      Iterator<String> iter = extraConfigHash.keySet().iterator();
      while (iter.hasNext()) {
         String key = (String) iter.next();
         String val = (String) extraConfigHash.get(key);
         KeyValue keyValue = new KeyValue();
         keyValue.setKey(key);
         keyValue.setValue(val);
         keyValueVector.add(keyValue);
      }
      configSpec.setExtraConfig(keyValueVector);
      hdvsManager.reconfigureDistributedVirtualSwitch(hostDVSMgrMor, configSpec);
      HostDVSConfigSpec newConfigSpec = hdvsManager.retrieveDVSConfigSpec(
               hostDVSMgrMor, UUIDHS1);
      List<KeyValue> extraConfigList = newConfigSpec.getExtraConfig();
      assertTrue(extraConfigList != null && extraConfigList.size() == 2,
               "returned size of extraConfig list is not equal to 2");
      for (KeyValue kv : extraConfigList) {
         if (kv.getKey().equals(key1)) {
            assertTrue(kv.getValue().equals(val1), "key: " + key1 + " val: "
                     + val1 + " is not matched with " + "key: " + kv.getKey()
                     + " val:" + kv.getValue());
         } else if (kv.getKey().equals(key2)) {
            assertTrue(kv.getValue().equals(val2), "key: " + key2 + " val: "
                     + val2 + " is not matched with " + "key: " + kv.getKey()
                     + " val:" + kv.getValue());
         }
      }
      Vector<String> ignorePropertyList = new Vector<String>();
      ignorePropertyList.add("HostDVSConfigSpec.ExtraConfig");
      ignorePropertyList.add("HostDVSConfigSpec.ModifyVendorSpecificDvsConfig");
      ignorePropertyList.add("HostDVSConfigSpec.ModifyVendorSpecificHostMemberConfig");
      ignorePropertyList.add("HostDVSConfigSpec.VendorSpecificHostMemberConfig");
      boolean validate = TestUtil.compareObject(newConfigSpec, oldConfigSpec, ignorePropertyList);
      assertTrue(validate, "oldConfigSpec and newConfigSpec are the same",
               "oldConfigSpec and newConfigSpec are not the same");
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
