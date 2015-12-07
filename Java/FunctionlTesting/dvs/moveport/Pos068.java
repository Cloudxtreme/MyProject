package dvs.moveport;

import static com.vmware.vcqa.vim.MessageConstants.VM_POWEROFF_PASS;

import java.util.Arrays;
import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.ConfigSpecOperation;
import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

public class Pos068 extends TestBase implements IDataDrivenTest
{

   protected DistributedVirtualSwitch dvs;
   protected DistributedVirtualPortgroup dvportgroup;
   protected Folder folder;
   protected VirtualMachine ivm;
   private HostSystem hs = null;
   protected ManagedEntity iManagedEntity;
   protected NetworkSystem ins;
   protected ManagedObjectReference dvsMor;
   protected ManagedObjectReference hostMor;
   private ManagedObjectReference rootFolderMor = null;
   private final int DVS_PORT_NUM = 1;
   protected String dvsName;
   private VMwareDVSConfigSpec dvsConfigSpec = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private VMwareDVSConfigSpec configSpec = null;
   private DVPortConfigSpec[] portConfigSpecs = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray;
   private VMwareDVSPortSetting dvPort = null;
   private List<String> portKeyList = null;
   private String portgroupkey = null;
   private String dvSwitchUuid = null;
   private VMwareDVSPortSetting dvPortGroupPortSetting = null;
   private VirtualMachine vm = null;
   private Vector<ManagedObjectReference> vmMors = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;

   /**
    * Test Setup
    *
    * @return
    * @throws Exception
    */
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      boolean setupDone = false;
      this.folder = new Folder(connectAnchor);
      this.dvs = new DistributedVirtualSwitch(connectAnchor);
      this.dvportgroup = new DistributedVirtualPortgroup(connectAnchor);
      this.vm = new VirtualMachine(connectAnchor);
      this.iManagedEntity = new ManagedEntity(connectAnchor);
      this.hs = new HostSystem(connectAnchor);
      this.hostMor = this.hs.getConnectedHost(null);
      this.rootFolderMor = this.folder.getRootFolder();
      Assert.assertNotNull(rootFolderMor, "Root Folder MOR is null");
      this.dvsConfigSpec = new VMwareDVSConfigSpec();
      this.dvsConfigSpec.setConfigVersion("");
      this.dvsConfigSpec.setName(this.getClass().getName());
      this.configSpec = (VMwareDVSConfigSpec) DVSUtil.addHostsToDVSConfigSpec(
               dvsConfigSpec, Arrays.asList(this.hostMor));

      this.dvsMor = this.folder.createDistributedVirtualSwitch(
               this.folder.getNetworkFolder(this.folder.getDataCenter()),
               this.configSpec);
      Assert.assertNotNull(this.dvsMor, "Successfully created dvs",
               "Failed to create DVS");
      DVSConfigInfo configInfo = this.dvs.getConfig(this.dvsMor);
      this.dvSwitchUuid = configInfo.getUuid();
      portKeyList = this.dvs.addStandaloneDVPorts(dvsMor, 1);
      dvPort = new VMwareDVSPortSetting();
      dvPort.setIpfixEnabled(DVSUtil.getBoolPolicy(data.getBoolean(DVSTestConstants.IP_FIX_INHERITED_KEY,
               false), data.getBoolean(DVSTestConstants.IP_FIX_ENABLED_KEY,
                        true)));
      if (portKeyList != null && portKeyList.size() == DVS_PORT_NUM) {
         portConfigSpecs = new DVPortConfigSpec[DVS_PORT_NUM];
         portConfigSpecs[0] = new DVPortConfigSpec();
         portConfigSpecs[0].setKey(portKeyList.get(0));
         portConfigSpecs[0].setOperation(ConfigSpecOperation.EDIT.value());
         portConfigSpecs[0].setSetting(dvPort);
      }

      // Reconfigure DVPort
      Assert.assertTrue(
               this.dvs.reconfigurePort(this.dvsMor, this.portConfigSpecs),
               "Failed to reconfigure port");
      // Create a port group with IpfixEnabled to true/false
      dvPortGroupPortSetting = new VMwareDVSPortSetting();
      dvPortGroupPortSetting.setIpfixEnabled(DVSUtil.getBoolPolicy(data.getBoolean(DVSTestConstants.IP_FIX_INHERITED_KEY,
               false), data.getBoolean(DVSTestConstants.IP_FIX_ENABLED_KEY,
                        true)));
      this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
      this.dvPortgroupConfigSpec.setName(this.getTestId());
      this.dvPortgroupConfigSpec.setDefaultPortConfig(dvPort);
      this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
      this.dvPortgroupConfigSpec.setDefaultPortConfig(dvPortGroupPortSetting);
      dvPortgroupConfigSpecArray = new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec };
      // Create portGroup
      dvPortgroupMorList = dvs.addPortGroups(dvsMor, dvPortgroupConfigSpecArray);
      Assert.assertNotNull(dvPortgroupMorList, "Could not create a port Group.");
      setupDone = true;
      return setupDone;
   }

   /**
    * Test
    *
    * @throws Exception
    */
   @Test(description = "Move a standalone port with IpfixEnabled = true/false "
            + "and inherited = true/false into a DVPortGroup having IpfixEnabled =true/false")
   public void test()
      throws Exception
   {
      boolean testDone = false;
      vmMors = DVSUtil.createVms(connectAnchor, hostMor, 1, 0);
      ManagedObjectReference vmMor = vmMors.get(0);
      DistributedVirtualSwitchPortConnection dvsConn = new DistributedVirtualSwitchPortConnection();
      dvsConn.setPortgroupKey(null);
      dvsConn.setSwitchUuid(this.dvSwitchUuid);
      dvsConn.setPortKey(portKeyList.get(0));
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
               vmMor,
               connectAnchor,
               new DistributedVirtualSwitchPortConnection[] { DVSUtil.buildDistributedVirtualSwitchPortConnection(
                        dvSwitchUuid, portKeyList.get(0), null) });
      Assert.assertTrue((vmConfigSpec != null && vmConfigSpec.length == 2
               && vmConfigSpec[0] != null && vmConfigSpec[1] != null),
               "Successfully obtained the original and the updated virtual"
                        + " machine config spec",
               "Cannot reconfigure the virtual machine to use the " + "DV port");
      Assert.assertTrue(this.vm.reconfigVM(vmMor, vmConfigSpec[0]),
               "Successfully reconfigured the virtual machine to use "
                        + "the DV port",
               "Failed to  reconfigured the virtual machine to use "
                        + "the DV port");
      Assert.assertTrue(DVSUtil.performVDSPortVerifcation(connectAnchor,
               this.hostMor, vmMor, dvsConn, this.dvSwitchUuid),
               " Failed to verify port connection  and/or PortPersistenceLocation for VM : "
                        + vm.getName(vmMor));
      Assert.assertTrue(dvs.movePort(dvsMor,
               (String[]) portKeyList.toArray(new String[0]), portgroupkey),
               "Failed to move standalone port into PortGroup");
      Assert.assertTrue(DVSUtil.verifyIpfixPortSettingFromParent(connectAnchor,
               dvsMor, dvPort, portKeyList),
               "Verification of IpfixPortSetting failed");
      testDone = true;
      Assert.assertTrue(testDone, "Test Failed");
   }

   /**
    * Test Cleanup
    *
    * @return
    * @throws Exception
    */
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      if (this.vmMors != null) {
         Assert.assertTrue(vm.setVMsState(vmMors, VirtualMachinePowerState.POWERED_OFF, false),
                  VM_POWEROFF_PASS, VM_POWEROFF_PASS);
         vm.destroy(vmMors);
      }
      if (this.dvPortgroupMorList != null) {
         for (ManagedObjectReference mor : dvPortgroupMorList) {
            status &= this.dvportgroup.destroy(mor);
         }
      }
      if (this.dvsMor != null) {
         status &= this.dvportgroup.destroy(dvsMor);
      }
      return true;
   }

   /**
    * Factory method to create the data driven tests.
    *
    * @return Object[] TestBase objects.
    * @throws Exception
    */
   @Factory
   @Parameters({ "dataFile" })
   public Object[] getTests(@Optional("") String dataFile)
      throws Exception
   {
      return TestExecutionUtils.getTests(this.getClass().getName(), dataFile);
   }

   public String getTestName()
   {
      return getTestId();
   }
}
