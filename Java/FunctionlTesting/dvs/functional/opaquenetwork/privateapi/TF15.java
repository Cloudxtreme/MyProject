package dvs.functional.opaquenetwork.privateapi;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.HostOpaqueNetworkData;
import com.vmware.vc.HostOpaqueNetworkInfo;
import com.vmware.vc.HostOpaqueSwitch;
import com.vmware.vc.KeyValue;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualDevice;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualEthernetCard;
import com.vmware.vc.VirtualEthernetCardOpaqueNetworkBackingInfo;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.NetworkUtil;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

public class TF15 extends PrivateApiBase
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
      VirtualMachineConfigSpec vmConfigSpec = DVSUtil.
                buildDefaultSpec(connectAnchor,
                        hs.getResourcePool(hostMor).get(0),
                        TestConstants.VM_VIRTUALDEVICE_ETHERNET_VMXNET3,
                        "Sample-vm-T1", 1);
        /*
         * Create the vm in this step
         */
         vmMor = folder.createVM(vm.getVMFolder(),
                 vmConfigSpec, hs.getResourcePool(hostMor).get(0),
                 hostMor);

         List<VirtualDeviceConfigSpec> ethernetCardDevices = DVSUtil.
                  getAllVirtualEthernetCardDevices(vmMor, connectAnchor);

         VirtualEthernetCard vEthernetDevice
            = (VirtualEthernetCard) ethernetCardDevices.get(0).getDevice();

         assertTrue(vEthernetDevice.getExternalId() == null, 
                    "vm created with no external id",
                    "vm external id creation error "
                    + vEthernetDevice.getExternalId());

      return true;
   }

   @Test
   public void test()
      throws Exception
   {

        VirtualMachineConfigSpec vmConfigSpec = vm.getVMConfigSpec(vmMor);

         List<VirtualDeviceConfigSpec> ethernetCardDevices = DVSUtil.
                  getAllVirtualEthernetCardDevices(vmMor, connectAnchor);


         VirtualEthernetCard vEthernetDevice
            = (VirtualEthernetCard) ethernetCardDevices.get(0).getDevice();


        List<VirtualDeviceConfigSpec> deviceSpecList =
                new ArrayList<VirtualDeviceConfigSpec>();
        VirtualDeviceConfigSpec virtualDeviceConfigSpec = new VirtualDeviceConfigSpec();
        vEthernetDevice.setExternalId("vm-external-id-set");
        virtualDeviceConfigSpec.setDevice(vEthernetDevice);
        deviceSpecList.add(virtualDeviceConfigSpec);
        vmConfigSpec.setDeviceChange(deviceSpecList);
        vm.reconfigVM(vmMor, vmConfigSpec);

         vEthernetDevice = (VirtualEthernetCard) ethernetCardDevices.get(0).getDevice();
         ethernetCardDevices = DVSUtil.
                  getAllVirtualEthernetCardDevices(vmMor, connectAnchor);


         assertTrue(vEthernetDevice.getExternalId().equals("vm-external-id-set"),
                                                           "vm external id changed",
                                                   "vm external id updation error "
                                                + vEthernetDevice.getExternalId());
   }
   @AfterMethod
   public boolean testCleanUp()
      throws Exception
   {
        if(vmMor != null){
            /*
             * Destroy the vm
             */
            vm.destroy(vmMor);
        }
      return true;
   }

}
