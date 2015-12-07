package dvs.functional.opaquenetwork.privateapi;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.HostOpaqueNetworkData;
import com.vmware.vc.HostOpaqueNetworkInfo;
import com.vmware.vc.HostOpaqueSwitch;
import com.vmware.vc.KeyValue;
import com.vmware.vcqa.vim.host.NetworkSystem;

public class TF6 extends PrivateApiBase
{
   boolean isHostDvsCreated = false;
   boolean isOn1Created = false;
   String uuid = null;
   String name = null;
   String uuidtz = null;

   public boolean verifyOpaqueDataInfo(String uuidls,
                                       String namels,
                                       String uuidtz)
      throws Exception
   {
      /* verify opaque network data and opaque network info */
      List<HostOpaqueNetworkData> hostOpaqueDatas = GetOpaqueNetwork(uuidls,
               namels, uuidtz);
      assertTrue(
               (hostOpaqueDatas != null && hostOpaqueDatas.size() == 1),
               "Size of HostOpaqueNetworkData returned by "
                        + "PerformHostOpaqueNetworkDataOperation is not equal to 1");
      List<HostOpaqueNetworkInfo> opaqueNetworkInfos = null;
      opaqueNetworkInfos = ns.getNetworkInfo(nsMor).getOpaqueNetwork();
      assertTrue(opaqueNetworkInfos != null && opaqueNetworkInfos.size() == 1,
               "Size of HostOpaqueNetworkData returned by "
                        + "vim.Host.OpaqueNetworkInfo is not equal to 1");
      return compareOpaqueDataAndInfo(namels, uuidtz, hostOpaqueDatas.get(0),
               opaqueNetworkInfos.get(0));
   }

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
      Vector<String> pnics = new Vector<String>();
      pnics.add("vmnic1");

      List<KeyValue> extraConfigList = new ArrayList<KeyValue>();
      KeyValue keyValue = new KeyValue();
      keyValue.setKey("com.vmware.extraconfig.opaqueDvs.status");
      keyValue.setValue("down");
      extraConfigList.add(keyValue);

      isHostDvsCreated = CreateOpaqueDvs(pnics, extraConfigList, true);

      assertTrue(GetOpaqueSwitches().size() == 1,
        "Host Opaque Switch created", "Host Opaque Switch creation error " +
                GetOpaqueSwitches().size());

      assertTrue(GetOpaqueSwitches().get(0).getStatus().equals("down"),
              "opaque switch created with status as down",
              "opaque switch creation error, status: "
              + GetOpaqueSwitches().get(0).getStatus());

      DeleteOpaqueDvs();
      isHostDvsCreated = CreateOpaqueDvs(pnics, extraConfigList, false);

      assertTrue(GetHostProxySwitches().size() == 1,
        "VDS created", "VDS creation error" + GetHostProxySwitches().size());

      assertTrue(GetOpaqueSwitches().size() == 0,
        "Host Opaque Switch not created", "Host Opaque Switch creation error "
        + GetOpaqueSwitches().size());

   }
   @AfterMethod
   public boolean testCleanUp()
      throws Exception
   {
      if (isOn1Created) {
         /* clear opaque network */
         DeleteOpaqueNetwork(uuid, name, uuidtz);
      }
      if (isHostDvsCreated) {
         DeleteOpaqueDvs();
      }
      return true;
   }

}
