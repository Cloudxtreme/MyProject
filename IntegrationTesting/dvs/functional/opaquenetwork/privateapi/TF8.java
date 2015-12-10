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
import com.vmware.vc.HostOpaqueSwitchPhysicalNicZone;
import com.vmware.vc.KeyValue;
import com.vmware.vcqa.vim.host.NetworkSystem;

public class TF8 extends PrivateApiBase
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

      Vector<String> pnics = new Vector<String>();
      pnics.add("vmnic1");

      List<KeyValue> extraConfigList = new ArrayList<KeyValue>();

      isHostDvsCreated = CreateOpaqueDvs(pnics, extraConfigList, true);

      assertTrue(GetOpaqueSwitches().size() == 1,
        "Host Opaque Switch created", "Host Opaque Switch creation error " +
                GetOpaqueSwitches().size());

      assertTrue(GetOpaqueSwitches().get(0).getPnicZone().size() == 0,
              "no pnic zones created as part of opaque switch",
              "pnic zone creation error "
              + GetOpaqueSwitches().get(0).getPnicZone().size());
      return true;
   }

   @Test
   public void test()
      throws Exception
   {

      HostOpaqueSwitch hostOpaqueSwitch =  GetOpaqueSwitches().get(0);
      List<HostOpaqueSwitchPhysicalNicZone> pnicZones
            = new ArrayList<HostOpaqueSwitchPhysicalNicZone>();
      HostOpaqueSwitchPhysicalNicZone pnicZone = new HostOpaqueSwitchPhysicalNicZone();
      pnicZone.setKey(UUIDTZ1);
      pnicZones.add(pnicZone);
      hostOpaqueSwitch.setPnicZone(pnicZones);

      UpdateOpaqueDvs(hostOpaqueSwitch);

      assertTrue(GetOpaqueSwitches().get(0).getPnicZone().size() == 1,
              "1 pnic zones successfully removed as part of opaque switch",
              "pnic zone updation error "
              + GetOpaqueSwitches().get(0).getPnicZone().size());


      assertTrue(
            GetOpaqueSwitches().get(0).getPnicZone().get(0).getKey().equals(UUIDTZ1),
            "pnic zone 1 updated as part of opaque switch",
            "pnic zone updation error "
            + GetOpaqueSwitches().get(0).getPnicZone().get(0).getKey());
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
