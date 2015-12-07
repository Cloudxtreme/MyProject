package dvs.functional.opaquenetwork.privateapi;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.util.Assert.assertNotNull;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Random;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.BoolPolicy;
import com.vmware.vc.HostDVSConfigSpec;
import com.vmware.vc.HostDVSPortData;
import com.vmware.vc.HostIpConfig;
import com.vmware.vc.HostOpaqueNetworkInfo;
import com.vmware.vc.HostVirtualNicOpaqueNetworkSpec;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.KeyValue;
import com.vmware.vc.StringPolicy;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareUplinkLacpPolicy;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

public class TS3 extends PrivateApiBase
{
   boolean isHostDvsCreated = false;
   boolean isOn1Created = false;
   String uuid = null;
   String name = null;
   String uuidtz = null;
   String vnic_id = null;

   String GetRandomHex()
   {
      String buf;
      Random rand = new Random();
      int myRandomNumber = rand.nextInt(256);
      buf = Integer.toHexString(myRandomNumber);
      return buf;
   }

   String GenerateUuid()
   {
      String hex1 = GetRandomHex();
      String hex2 = GetRandomHex();
      String hex3 = GetRandomHex();
      return hex1 + " " + hex2 + " " + hex3
               + " 51 39 2d 90 5d-2a e4 56 c5 c6 fb e6 04";
   }

   @BeforeMethod
   public boolean testSetUp()
      throws Exception
   {
      initialize();
      Vector<String> pnics = new Vector<String>();
      pnics.add("vmnic1");
      /* create opaque switch */
      isHostDvsCreated = CreateDefaultOpaqueDvs(pnics);

      uuid = UUIDLS1;
      name = NAMELS1;
      uuidtz = UUIDTZ1;
      /* create opaque network */
      CreateOpaqueNetwork(uuid, name, uuidtz);
      isOn1Created = true;

      // isHostDvsCreated = true;

      return true;
   }

   @Test
   public void test()
      throws Exception
   {
      List<HostOpaqueNetworkInfo> opaqueNetworkInfo = ns.getNetworkInfo(nsMor).getOpaqueNetwork();
      assertTrue(opaqueNetworkInfo != null && opaqueNetworkInfo.size() > 0,
               "The list of opaque networks is not null",
               "The list of opaque networks is null");

      String portUuid = GenerateUuid();

      BoolPolicy lacpEnable = new BoolPolicy();
      lacpEnable.setInherited(false);
      lacpEnable.setValue(true);
      StringPolicy lacpMode = new StringPolicy();
      lacpMode.setInherited(false);
      lacpMode.setValue("active");
      VMwareUplinkLacpPolicy newLacpPolicy = new VMwareUplinkLacpPolicy();
      newLacpPolicy.setEnable(lacpEnable);
      newLacpPolicy.setMode(lacpMode);

      VMwareDVSPortSetting portSetting = new VMwareDVSPortSetting();
      portSetting.setLacpPolicy(newLacpPolicy);

      HostDVSPortData portData = new HostDVSPortData();
      portData.setPortKey(portUuid);
      portData.setConnectionCookie(10);
      portData.setSetting(portSetting);

      String externalIdKey = "com.vmware.port.extraConfig.vnic.external.id";
      String externalNoopKey = "com.vmware.port.extraConfig.vnic.external.noop";
      String externalId = GenerateUuid();

      KeyValue KVexternalId = new KeyValue();
      KVexternalId.setKey(externalIdKey);
      KVexternalId.setValue(externalId);
      List<KeyValue> extraConfigList = new ArrayList<KeyValue>();
      extraConfigList.add(KVexternalId);
      portData.setExtraConfig(extraConfigList);

      List<HostDVSPortData> portDatas = new ArrayList<HostDVSPortData>();
      portDatas.add(portData);
      hdvsManager.applyDVPort(hostDVSMgrMor, UUIDHS1, portDatas);

      ArrayList<String> DVPorts = (ArrayList<String>) hdvsManager.retrieveDVPort(
               hostDVSMgrMor, UUIDHS1);
      assertTrue(DVPorts != null && DVPorts.size() > 0,
               "retrieveDBPort() returned null or empty!");
      String nonUplinkPortKey = null;
      for (String port : DVPorts) {
         if (port.startsWith("uplink") == false) {
            nonUplinkPortKey = port;
            break;
         }
      }
      assertNotNull(nonUplinkPortKey, "Successed to get a non-uplink dv port",
               "Failed to get a non-uplink dv port");
      String[] portKeys = { nonUplinkPortKey };
      HostDVSPortData[] DVPortDatas = hdvsManager.fetchPortState(hostDVSMgrMor,
               NAMEHS1, portKeys, null);

      /*
       * TODO: revisit this case when PR 1272933 gets fixed.
       * As TS2 case does, change extraConfig on a non-uplink dvport and
       * verify the updating.
       */
      List<KeyValue> extraConfig = null;
      extraConfig = DVPortDatas[0].getExtraConfig();
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
