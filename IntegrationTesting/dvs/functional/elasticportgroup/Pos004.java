/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional.elasticportgroup;

import static com.vmware.vc.HostSystemConnectionState.CONNECTED;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_DEL_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_DEL_PASS;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;
import com.vmware.vcqa.vim.host.HostSystemInformation;

/**
 * DESCRIPTION:<BR>
 * (Increasing the Proxy Port limit number) <BR>
 * TARGET: VC <BR>
 * <BR>
 * SETUP:<BR>
 * 1. Set MAX PORTS to 256 while creating vDs <BR>
 * 2. Reset the number of ports of the vDS to 512<BR>
 * 3. Create 51 vms with 10 nic cards and one vm with 1 nic card <BR>
 * 4. Reboot the host <BR>
 * TEST:<BR>
 * 3. Add 51 static DVPGs by setting   autoexpand  as true and 0 ports<BR>
 * 4. reconfigure Vms to connect to static DVPGs <BR>
 * CLEANUP:<BR>
 * 5. Delete VMs<BR>
 * 6. Destroy vDs<BR>
 */
public class Pos004 extends TestBase
{
   private ManagedObjectReference dvsMor = null;
   private String dvSwitchUuid = null;
   private String early = DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;
   private ManagedObjectReference hostMor = null;
   private DistributedVirtualSwitch iDVS = null;
   private HostSystem ihs = null;
   private VirtualMachine ivm = null;
   private Vector<ManagedObjectReference> vmMors = null;
   private final int MAX_PORTS = 512;
   private final int VM_COUNT = 51;
   private DVSConfigSpec deltaConfigSpec = null;
   private DistributedVirtualPortgroup dvPortGroup;

   @Override
   public void setTestDescription()
   {
      super
      .setTestDescription(" Test case to address PR#511841 "
               + "(Increasing the Proxy Port limit number) \n"
               + " 1. Set MAX PORTS to 258 while creating vDs   . \n"
               + " 2.Reset the number of ports of the vDS to 512 \n"
               + " 3.Create 51 vms with 10 nic cards and one vm with 1 nic card \n"
               + " 4.Reboot the host \n"
               + " 5.Add 51 static DVPGs by setting   autoexpand  as true and 0 ports\n"
               + " 6. Reconfigure Vms to connect to static DVPG \n"
               + " Reconfigure should succeed on all VMS. \n");
   }

   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {

      HashMap<ManagedObjectReference, HostSystemInformation> hostsMap = null;
      List<ManagedObjectReference> hostList =
               new ArrayList<ManagedObjectReference>(1);
      this.dvPortGroup = new DistributedVirtualPortgroup(connectAnchor);
      this.ivm = new VirtualMachine(connectAnchor);
      this.iDVS = new DistributedVirtualSwitchHelper(connectAnchor);
      this.ihs = new HostSystem(connectAnchor);
      hostsMap = this.ihs.getAllHosts(VersionConstants.ESX4x, CONNECTED);
      assertNotNull(hostsMap, "The host map is null");
      this.hostMor = hostsMap.keySet().iterator().next();
      assertNotNull(this.hostMor, HOST_GET_FAIL);
      hostList.add(hostMor);
      dvsMor =
               DVSUtil
                        .createDVSWithMAXPorts(connectAnchor, hostList, 256,
                                 null);
      DVSConfigInfo configInfo = this.iDVS.getConfig(this.dvsMor);
      this.dvSwitchUuid = configInfo.getUuid();
      this.deltaConfigSpec = new DVSConfigSpec();

      DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
      String validConfigVersion =
               this.iDVS.getConfig(dvsMor).getConfigVersion();
      this.deltaConfigSpec.setConfigVersion(validConfigVersion);

      hostConfigSpecElement =
               new DistributedVirtualSwitchHostMemberConfigSpec();
      hostConfigSpecElement.setHost(this.hostMor);
      log.info(ihs.getHostName(hostMor));
      hostConfigSpecElement.setMaxProxySwitchPorts(MAX_PORTS);
      hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_EDIT);
      this.deltaConfigSpec.getHost().clear();
      this.deltaConfigSpec.getHost()
               .addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
      assertTrue(this.iDVS.reconfigure(this.dvsMor, this.deltaConfigSpec),
               "Failed reconfigure VDS");
      this.vmMors = DVSUtil.createVms(connectAnchor, hostMor, VM_COUNT, 9);
      this.vmMors.addAll((DVSUtil.createVms(connectAnchor, hostMor, 1, 0)));
      assertNotNull(vmMors, " Failed to create required number of vms");
      this.ihs.rebootHost(hostMor, data.getInt(TestConstants.TESTINPUT_PORT),
               true, data.getString(TestConstants.TESTINPUT_USERNAME), data
                        .getString(TestConstants.TESTINPUT_PASSWORD));
      log.info("Rebooted the host:" + this.ihs.getHostName(hostMor));
      Thread.sleep(30000);
      return true;
   }

   @Test
   public void test()
      throws Exception
   {
      DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
      DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
      List<ManagedObjectReference> dvPortgroupMorList = null;

      for (ManagedObjectReference vmMor : this.vmMors) {
         Vector<DistributedVirtualSwitchPortConnection> portConns =
                  new Vector<DistributedVirtualSwitchPortConnection>(51);
         /*
          * create 10 DVport PortConnections on each VM
          */
         int noOfEthernetCards =
                  DVSUtil
                           .getAllVirtualEthernetCardDevices(vmMor,
                                    connectAnchor).size();
         dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
         dvPortgroupConfigSpec.setConfigVersion("");
         dvPortgroupConfigSpec.setName(TestUtil.getShortTime() + "_DVPG");
         dvPortgroupConfigSpec.setType(early);
         dvPortgroupConfigSpec.setNumPorts(0);
         dvPortgroupConfigSpec.setAutoExpand(true);
         assertNotNull(dvPortgroupConfigSpec, "DVPortgroupConfigSpec is null");
         dvPortgroupConfigSpecArray =
                  new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec };
         dvPortgroupMorList =
                  this.iDVS.addPortGroups(dvsMor, dvPortgroupConfigSpecArray);
         assertTrue(
                  (dvPortgroupMorList != null && dvPortgroupMorList.size() == dvPortgroupConfigSpecArray.length),
                  "Successfully added all the portgroups",
                  "Failed to  add all the portgroups");
         String pgKey = this.dvPortGroup.getKey(dvPortgroupMorList.get(0));


         /*
          * Build the port connections for all the ethernet cards
          */
         for (int i = 0; i < noOfEthernetCards; i++) {
            portConns.add(DVSUtil.buildDistributedVirtualSwitchPortConnection(
                     dvSwitchUuid, null, pgKey));
         }
         /*
          * Reconfig VM here to connect to
          * DistributedVirtualSwitchPortConnection
          */

         VirtualMachineConfigSpec[] vmConfigSpec = null;
         vmConfigSpec =
                  DVSUtil.getVMConfigSpecForDVSPort(vmMor, connectAnchor,
                           TestUtil.vectorToArray(portConns));
         assertTrue((vmConfigSpec != null && vmConfigSpec.length == 2
                  && vmConfigSpec[0] != null && vmConfigSpec[1] != null),
                  "Successfully obtained the original and the updated virtual"
                           + " machine config spec",
                  "Can not reconfigure the virtual machine to use the "
                           + "DV port");
         Thread.sleep(35000);
         assertTrue(this.ivm.reconfigVM(vmMor, vmConfigSpec[0]),
                  "Successfully reconfigured the virtual machine to use "
                           + "the DV port",
                  "Failed to  reconfigured the virtual machine to use "
                           + "the DV port");

      }
   }

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      if (vmMors != null && vmMors.size() > 0) {
         assertTrue(this.ivm.destroy(vmMors), VM_DEL_PASS, VM_DEL_FAIL);

      }
      if (this.dvsMor != null) {
         assertTrue(this.iDVS.destroy(this.dvsMor), " Failed to destroy vDs");
      }

      return true;
   }

}