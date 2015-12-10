package dvs.functional.opaquenetwork.privateapi;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.HostOpaqueNetworkData;
import com.vmware.vc.HostOpaqueNetworkInfo;

public class TS1 extends PrivateApiBase
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
      isHostDvsCreated = CreateDefaultOpaqueDvs(pnics);

      return true;
   }

   @Test
   public void test()
      throws Exception
   {
      uuid = UUIDLS1;
      name = NAMELS1;
      uuidtz = UUIDTZ1;

      /* create opaque network */
      CreateOpaqueNetwork(uuid, name, uuidtz);
      isOn1Created = true;

      /* verify opaque network data and opaque network info */
      assertTrue(verifyOpaqueDataInfo(uuid, name, uuidtz),
               "HostOpaqueNetworkData and HostOpaqueNetworkInfo are the same",
               "HostOpaqueNetworkData and HostOpaqueNetworkInfo are different");

      /* update opaque network */
      name = NAMELS2;
      uuidtz = UUIDTZ2;
      SetOpaqueNetwork(uuid, name, uuidtz);

      /* verify after setting opaque network data */
      assertTrue(verifyOpaqueDataInfo(uuid, name, uuidtz),
               "HostOpaqueNetworkData and HostOpaqueNetworkInfo are the same",
               "HostOpaqueNetworkData and HostOpaqueNetworkInfo are different");

      /* delete opaque network */
      DeleteOpaqueNetwork(uuid, name, uuidtz);
      isOn1Created = false;
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
