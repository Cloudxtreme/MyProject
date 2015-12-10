/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional.elasticportgroup;

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
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.SystemError;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;
import com.vmware.vcqa.vim.host.HostSystemInformation;

/**
 * DESCRIPTION:<br>
 * (Increasing the Proxy Port limit number) <br>
 * TARGET: VC <br>
 * NOTE : PR#511841 <br>
 * <br>
 * SETUP:<br>
 * 1. Create a DVS with maxPorts as 4 (including one uplink port). <BR>
 * 2. Create 4 vms<BR>
 * TEST:<br>
 * 3.Create static type dvpg with numPorts – 3, autoexpand - true<BR>
 * 4.Reconfigure 4 VMS to connect to above dvpg <br>
 * CLEANUP:<br>
 * 5. Delete VMs<br>
 * 6. Destroy vDs<br>
 */
public class Neg002 extends TestBase
{
   private ManagedObjectReference dvsMor = null;
   private String dvSwitchUuid = null;
   private String early = DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;
   private ManagedObjectReference hostMor = null;
   private DistributedVirtualSwitch iDVS = null;
   private HostSystem ihs = null;
   private VirtualMachine ivm = null;
   private Vector<ManagedObjectReference> vmMors = null;
   private final int MAX_PORTS = 4;
   private final int VM_COUNT = 4;
   private DistributedVirtualPortgroup dvPortGroup;

   @Override
   public void setTestDescription()
   {
      super
               .setTestDescription("(Increasing the Proxy Port limit number) \n"
                        + " 1. Create a DVS with maxPorts as 4 (including one uplink port).\n"
                        + " 2.Create 4 vms \n"
                        + " 3.Create static type dvpg with numPorts – 3, autoexpand - true \n"
                        + " 4.Reconfigure 4 VMS to connect to above dvpgt \n");
   }

   @Override
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
      this.hostMor = this.ihs.getConnectedHost(false);
      assertNotNull(this.hostMor, HOST_GET_FAIL);
      hostList.add(hostMor);
      dvsMor =
               DVSUtil.createDVSWithMAXPorts(connectAnchor, hostList,
                        MAX_PORTS, null);
      DVSConfigInfo configInfo = this.iDVS.getConfig(this.dvsMor);
      this.dvSwitchUuid = configInfo.getUuid();
      this.vmMors = DVSUtil.createVms(connectAnchor, hostMor, VM_COUNT, 0);
      assertNotNull(vmMors, " Failed to create required number of vms");
      return true;
   }

   @Override
   @Test(description = "(Increasing the Proxy Port limit number) \n"
                        + " 1. Create a DVS with maxPorts as 4 (including one uplink port).\n"
                        + " 2.Create 4 vms \n"
                        + " 3.Create static type dvpg with numPorts – 3, autoexpand - true \n"
                        + " 4.Reconfigure 4 VMS to connect to above dvpgt \n")
   public void test()
      throws Exception
   {
      try {
         DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
         DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
         List<ManagedObjectReference> dvPortgroupMorList = null;
         dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
         dvPortgroupConfigSpec.setConfigVersion("");
         dvPortgroupConfigSpec.setName(TestUtil.getShortTime() + "_DVPG");
         dvPortgroupConfigSpec.setType(early);
         dvPortgroupConfigSpec.setNumPorts(0);
         //dvPortgroupConfigSpec.setAutoExpand(true);
         dvPortgroupConfigSpec.setAutoExpand(false);
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
         for (ManagedObjectReference vmMor : this.vmMors) {
            /*
             * Reconfig VM here to connect to
             * DistributedVirtualSwitchPortConnection
             */

            VirtualMachineConfigSpec[] vmConfigSpec = null;
            vmConfigSpec =
                     DVSUtil
                              .getVMConfigSpecForDVSPort(
                                       vmMor,
                                       connectAnchor,
                                       new DistributedVirtualSwitchPortConnection[] { DVSUtil
                                                .buildDistributedVirtualSwitchPortConnection(
                                                         dvSwitchUuid, null, pgKey) });
            assertTrue((vmConfigSpec != null && vmConfigSpec.length == 2
                     && vmConfigSpec[0] != null && vmConfigSpec[1] != null),
                     "Successfully obtained the original and the updated virtual"
                              + " machine config spec",
                     "Can not reconfigure the virtual machine to use the "
                              + "DV port");
            assertTrue(this.ivm.reconfigVM(vmMor, vmConfigSpec[0]),
                     "Successfully reconfigured the virtual machine to use "
                              + "the DV port",
                     "Failed to  reconfigured the virtual machine to use "
                              + "the DV port");
         }
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new SystemError();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
   }

   @Override
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