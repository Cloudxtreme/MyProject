package dvs.functional.opaquenetwork.privateapi;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Vector;

import com.vmware.vc.ArrayOfKeyValue;
import com.vmware.vc.ArrayOfString;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.DynamicProperty;
import com.vmware.vc.HostDVSConfigSpec;
import com.vmware.vc.HostDVSCreateSpec;
import com.vmware.vc.HostDVSPortData;
import com.vmware.vc.HostNetworkInfo;
import com.vmware.vc.HostOpaqueNetworkData;
import com.vmware.vc.HostOpaqueNetworkInfo;
import com.vmware.vc.HostOpaqueSwitch;
import com.vmware.vc.HostOpaqueSwitchPhysicalNicZone;
import com.vmware.vc.HostProxySwitch;
import com.vmware.vc.KeyValue;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.internal.vim.InternalServiceInstance;
import com.vmware.vcqa.internal.vim.dvs.InternalHostDistributedVirtualSwitchManager;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.host.NetworkSystem;

public abstract class PrivateApiBase extends TestBase
{
   public static final String NAMELS1 = "apiTestLogicalSwitch1";
   public static final String NAMELS2 = "apiTestLogicalSwitch2";
   public static final String UUIDTZ1
    = "b7 93 12 50 38 2c 99 5d-2a e4 56 c5 c6 fb e6 03";
   public static final String UUIDTZ2
    = "b8 93 12 50 38 2c 99 5d-2a e4 56 c5 c6 fb e6 03";
   public static final String UUIDLS1
    = "b9 93 12 50 38 2c 99 5d-2a e4 56 c5 c6 fb e6 04";
   public static final String UUIDLS2
    = "ba 93 12 50 38 2c 99 5d-2a e4 56 c5 c6 fb e6 05";
   public static final String UUIDHS1
    = "bb 93 12 50 38 2c 99 5d-2a e4 56 c5 c6 fb e6 05";
   public static final String NAMEHS1 = "XYZ";

   public InternalHostDistributedVirtualSwitchManager hdvsManager = null;
   public InternalServiceInstance msi = null;
   public ManagedObjectReference hostDVSMgrMor = null;
   public NetworkSystem ns = null;
   public HostSystem hs = null;
   public ManagedObjectReference nsMor = null;
   public ManagedObjectReference hostMor = null;
   public ManagedObjectReference vmMor = null;
   public Folder folder = null;
   public VirtualMachine vm = null;

   boolean result = false;

   public void initialize()
      throws Exception
   {
      ns = new NetworkSystem(connectAnchor);
      hs = new HostSystem(connectAnchor);
      Vector<ManagedObjectReference> allHosts = hs.getAllHost();
      assertTrue((allHosts != null && allHosts.size() > 0), "No host was found");
      hostMor = allHosts.get(0);
      nsMor = ns.getNetworkSystem(hostMor);
      hdvsManager = new InternalHostDistributedVirtualSwitchManager(
               connectAnchor);
      msi = new InternalServiceInstance(connectAnchor);
      hostDVSMgrMor =
      msi.getInternalServiceInstanceContent().getHostDistributedVirtualSwitchManager();
      vm = new VirtualMachine(connectAnchor);
      folder  = new Folder(connectAnchor);
      hs = new HostSystem(connectAnchor);
   }

   public List<HostProxySwitch> GetHostProxySwitches() throws Exception {

       NetworkSystem networkSystem = new NetworkSystem(connectAnchor);
       HostNetworkInfo hostNetworkInfo = networkSystem.getNetworkInfo(nsMor);
       List<HostProxySwitch> hostProxySwitchList = hostNetworkInfo.getProxySwitch();
       return hostProxySwitchList;
   }

   public List<HostOpaqueSwitch> GetOpaqueSwitches()
              throws Exception
   {
       NetworkSystem networkSystem = new NetworkSystem(connectAnchor);
       HostNetworkInfo hostNetworkInfo = networkSystem.getNetworkInfo(nsMor);
       return hostNetworkInfo.getOpaqueSwitch();
   }

   public boolean CreateDefaultOpaqueDvs(Vector<String> pnics)
      throws Exception
   {
      HostDVSCreateSpec dvsCreateSpec = makeDvsCreateSpec(pnics);
      List<KeyValue> extraConfigList = new ArrayList<KeyValue>();
      KeyValue keyValue = new KeyValue();
      keyValue.setKey("com.vmware.extraconfig.opaqueDvs.status");
      keyValue.setValue("up");
      extraConfigList.add(keyValue);
      keyValue.setKey("com.vmware.extraconfig.opaqueDvs.pnicZone");
      keyValue.setValue(UUIDTZ1
               + "," + UUIDTZ2);
      dvsCreateSpec.setIsOpaque(true);
      dvsCreateSpec.setExtraConfig(extraConfigList);

      result = hdvsManager.createDistributedVirtualSwitch(hostDVSMgrMor,
               dvsCreateSpec);
      return result;
   }

   public boolean CreateOpaqueDvs(Vector<String> pnics,
                                  HashMap<String, String> extraConfigHash,
                                  String opaqueVal)
      throws Exception
   {
      HostDVSCreateSpec dvsCreateSpec = makeDvsCreateSpec(pnics);
      Vector<DynamicProperty> dynamicPropertyList = makeDvsDynamicProperty(
               extraConfigHash, opaqueVal);
      if (dynamicPropertyList != null) {
         //dvsCreateSpec.setDynamicProperty(dynamicPropertyList);
      }
      result = hdvsManager.createDistributedVirtualSwitch(hostDVSMgrMor,
               dvsCreateSpec);
      return result;
   }

   public boolean CreateOpaqueDvs(Vector<String> pnics,
                                  List<KeyValue> extraConfigList,
                                  boolean opaqueVal)
      throws Exception
   {
      HostDVSCreateSpec dvsCreateSpec = makeDvsCreateSpec(pnics);
      dvsCreateSpec.setIsOpaque(opaqueVal);
      dvsCreateSpec.setExtraConfig(extraConfigList);
      result = hdvsManager.createDistributedVirtualSwitch(hostDVSMgrMor,
               dvsCreateSpec);
      if (result) {
          log.info("DVS Created");
      }
      return result;
   }

   public boolean UpdateOpaqueDvs(HostOpaqueSwitch hostOpaqueSwitch)
      throws Exception
   {
       HostDVSConfigSpec reconfigSpec  = makeDvsReconfigureSpec();
       reconfigSpec.setUuid(UUIDHS1);
       List<KeyValue> extraConfig = new ArrayList<KeyValue>();
       KeyValue keyValue = new KeyValue();
       keyValue.setKey("com.vmware.extraconfig.opaqueDvs.pnicZone");
       String pnicZone = "";
       for (HostOpaqueSwitchPhysicalNicZone pnicZoneObject :
                                hostOpaqueSwitch.getPnicZone()) {
           if (pnicZone == "") {
               pnicZone = pnicZoneObject.getKey();
           } else {
               pnicZone = pnicZone + "," + pnicZoneObject.getKey();
           }
       }
       keyValue.setValue(pnicZone);
       extraConfig.add(keyValue);
       reconfigSpec.setExtraConfig(extraConfig);
       result = hdvsManager.reconfigureDistributedVirtualSwitch(
                                        hostDVSMgrMor, reconfigSpec);
       if (result) {
          log.info("DVS Updated");
       }
       return result;
   }

   public HostDVSConfigSpec makeDvsReconfigureSpec() {

       HostDVSConfigSpec reconfigSpec = new HostDVSConfigSpec();

    return reconfigSpec;

   }

   public HostDVSCreateSpec makeDvsCreateSpec(Vector<String> pnics)
   {
      DistributedVirtualSwitchProductSpec productSpec
                = new DistributedVirtualSwitchProductSpec();
      productSpec.setVendor("VMware");
      productSpec.setVersion("NSX 1.0");

      // use to uplink ports
      HostDVSPortData uplinkPort1 = new HostDVSPortData();
      uplinkPort1.setPortKey("uplink1");
      uplinkPort1.setConnectionCookie(0);
      HostDVSPortData uplinkPort2 = new HostDVSPortData();
      uplinkPort2.setPortKey("uplink2");
      uplinkPort2.setConnectionCookie(0);

      // Prepare pnicBacking
      DistributedVirtualSwitchHostMemberPnicBacking backing
                = new DistributedVirtualSwitchHostMemberPnicBacking();
      if (pnics != null) {
         if (pnics.size() > 16) {
            log.warn("number of pnic exceeds max:16");
         }
         Vector<DistributedVirtualSwitchHostMemberPnicSpec> pnicSpecList
                = new Vector<DistributedVirtualSwitchHostMemberPnicSpec>();
         int i = 1;
         for (String pnic : pnics) {
            DistributedVirtualSwitchHostMemberPnicSpec pnicSpec
                    = new DistributedVirtualSwitchHostMemberPnicSpec();
            pnicSpec.setPnicDevice(pnic);
            pnicSpec.setUplinkPortKey("uplink" + Integer.toString(i));
            pnicSpec.setConnectionCookie(0);
            pnicSpecList.add(pnicSpec);
            i++;
            if (i > 2) {
               // 2 uplink ports are set before, so here we only accept 2 pnics
               // for the time being.
               break;
            }
         }
         backing.setPnicSpec(pnicSpecList);
      }

      // create the dvs spec
      HostDVSCreateSpec dvsCreateSpec = new HostDVSCreateSpec();
      dvsCreateSpec.setUuid(UUIDHS1);
      dvsCreateSpec.setName(NAMEHS1);
      dvsCreateSpec.setBacking(backing);
      dvsCreateSpec.setProductSpec(productSpec);
      dvsCreateSpec.setMaxProxySwitchPorts(64);
      dvsCreateSpec.setModifyVendorSpecificDvsConfig(true);
      dvsCreateSpec.setModifyVendorSpecificHostMemberConfig(true);

      Vector<HostDVSPortData> dvsPortDataList = new Vector<HostDVSPortData>();
      dvsPortDataList.add(uplinkPort1);
      dvsPortDataList.add(uplinkPort2);
      dvsCreateSpec.setPort(dvsPortDataList);

      Vector<String> uplinkPortKeyList = new Vector<String>();
      uplinkPortKeyList.add("uplink1");
      uplinkPortKeyList.add("uplink2");
      dvsCreateSpec.setUplinkPortKey(uplinkPortKeyList);

      return dvsCreateSpec;
   }

   public Vector<DynamicProperty> makeDvsDynamicProperty(
                            HashMap<String, String> extraConfigHash,
                            String opaqueVal)
   {
      // dynamic property setting -- work for esx "5.5.0"
      Vector<DynamicProperty> dynamicPropertyList = null;
      if (extraConfigHash != null) {
         if (dynamicPropertyList == null) {
            dynamicPropertyList = new Vector<DynamicProperty>();
         }
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

         ArrayOfKeyValue extraConfigs = new ArrayOfKeyValue();
         extraConfigs.setKeyValue(keyValueVector);

         DynamicProperty extraConfig = new DynamicProperty();
         extraConfig.setName("__extraConfig__");
         extraConfig.setVal(extraConfigs);
         dynamicPropertyList.add(extraConfig);
      }

      if (opaqueVal != null) {
         if (dynamicPropertyList == null) {
            dynamicPropertyList = new Vector<DynamicProperty>();
         }
         DynamicProperty isOpaqueProp = new DynamicProperty();
         isOpaqueProp.setName("__isOpaque__");
         isOpaqueProp.setVal(opaqueVal);

         dynamicPropertyList.add(isOpaqueProp);
      }

      return dynamicPropertyList;
   }

   public boolean DeleteOpaqueDvs()
      throws Exception
   {
      result = hdvsManager.removeDistributedVirtualSwitch(hostDVSMgrMor,
               UUIDHS1);
      return result;
   }

   public boolean DeleteDvs()
      throws Exception
   {
      result = hdvsManager.removeDistributedVirtualSwitch(hostDVSMgrMor,
               UUIDHS1);
      return result;
   }

   public void CreateOpaqueNetwork(String uuidLs,
                                   String nameLs,
                                   String uuidTz)
      throws Exception
   {
      OpaqueNetworkOp("add", uuidLs, nameLs, uuidTz);
   }

   public void DeleteOpaqueNetwork(String uuidLs,
                                   String nameLs,
                                   String uuidTz)
      throws Exception
   {
      OpaqueNetworkOp("remove", uuidLs, nameLs, uuidTz);

   }

   public List<HostOpaqueNetworkData> GetOpaqueNetwork()
      throws Exception
   {
      return OpaqueNetworkOp("get", UUIDLS1, NAMELS1, UUIDTZ1
              + "," + UUIDTZ2);

   }

   public List<HostOpaqueNetworkData> GetOpaqueNetwork(String uuidLs,
                                                       String nameLs,
                                                       String uuidTz)
      throws Exception
   {
      return OpaqueNetworkOp("get", uuidLs, nameLs, uuidTz);

   }

   public void SetOpaqueNetwork(String uuidLs,
                                String nameLs,
                                String uuidTz)
      throws Exception
   {
      OpaqueNetworkOp("set", uuidLs, nameLs, uuidTz);

   }

   public List<HostOpaqueNetworkData> OpaqueNetworkOp(String operation,
                                                      String uuidLs,
                                                      String nameLs,
                                                      String uuidTz)
      throws Exception
   {
      HostOpaqueNetworkData hostOpaqueNetworkData = new HostOpaqueNetworkData();
      hostOpaqueNetworkData.setType("nsx.LogicalSwitch");
      hostOpaqueNetworkData.setPortAttachMode("auto");
      if (uuidLs != null) {
         hostOpaqueNetworkData.setId(uuidLs);
      } else {
         log.warn("Input uuidLs is null");
      }
      if (nameLs != null) {
         hostOpaqueNetworkData.setName(nameLs);
      }
      if (uuidTz != null) {
         Vector<String> vals
            = com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] { uuidTz });
         //hostOpaqueNetworkData.setDynamicProperty(makeDynamicProps(vals,
         //         "__pnicZone__"));
         hostOpaqueNetworkData.setPnicZone(vals);
      }
      ArrayList<HostOpaqueNetworkData> dataList
                = new ArrayList<HostOpaqueNetworkData>();
      dataList.add(hostOpaqueNetworkData);
      List<HostOpaqueNetworkData> returnedData
                = ns.performHostOpaqueNetworkDataOperation(
               nsMor, operation, dataList);

      return returnedData;
   }

   public ArrayList<DynamicProperty> makeDynamicProps(Vector<String> vals,
                                                      String name)
   {
      Vector<String> valStr = new Vector<String>();
      for (String val : vals) {
         valStr.add(val);
      }
      ArrayOfString arrayOfString = new ArrayOfString();
      arrayOfString.setString(valStr);
      DynamicProperty dynamicProperty = new DynamicProperty();
      dynamicProperty.setName(name);
      dynamicProperty.setVal(arrayOfString);
      ArrayList<DynamicProperty> dynamicPropertyList = new ArrayList<DynamicProperty>();
      dynamicPropertyList.add(dynamicProperty);
      return dynamicPropertyList;
   }

   public boolean compareOpaqueDataAndInfo(String namels,
                                           String uuidtz,
                                           HostOpaqueNetworkData data,
                                           HostOpaqueNetworkInfo info)
      throws Exception
   {
      boolean validate = true;
      // compare id
      if (!data.getId().equals(info.getOpaqueNetworkId())) {
         log.error("OpaqueNetworkId is not equal.");
         validate = false;
      } else {
         log.info("Get the same OpaqueNetworkId: " + data.getId());
      }
      // compare name
      if (!data.getName().equals(namels)) {
         log.error("OpaqueNetworkName is not equal to input argument " + namels);
         return false;
      }
      if (!data.getName().equals(info.getOpaqueNetworkName())) {
         log.error("OpaqueNetworkName is not equal");
         validate = false;
      } else {
         log.info("Get the same OpaqueNetworkName: " + data.getName());
      }
      // compare type
      if (!data.getType().equals(info.getOpaqueNetworkType())) {
         log.error("OpaqueNetworkType is not equal");
         validate = false;
      } else {
         log.info("Get the same OpaqueNetworkType: " + data.getType());
      }
      // compare pnicZone

      List<String> dataPnicZoneList = data.getPnicZone();
      List<String> infoPnicZoneList = info.getPnicZone();
      int index = 0;
      for (String dataPnicZone : dataPnicZoneList){
          if (!dataPnicZone.equals(infoPnicZoneList.get(index))) {

                 log.error("pnic zone is not equal");
                 validate = false;
          }
          index++;
      }

      return validate;
   }
}
