/*
 * ************************************************************************
 *
 * Copyright 2011 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvport;

import static com.vmware.vcqa.TestConstants.CONFIG_SPEC_EDIT;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupPolicy;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * DESCRIPTION:SDK client must not allow ReconfigurePort to change "blocked"
 * when portgroup.policy.blockOverrideAllowed is set to false( PR#610729)<BR>
 * TARGET:VC<BR>
 * SETUP:<BR>
 * 1.Create a VDS<BR>
 * 2.Create a static DVPG with one port by setting blockOverrideAllowed to
 * false.<BR>
 * 3.Get free port from above DVPG.<BR>
 * TEST:<BR>
 * 4.Invoke reconfigurePort on above port by setting blocked as true.<BR>
 * CLEANUP:<BR>
 * 5.Destroy VDS<BR>
 */
public class Neg032 extends TestBase
{
   private String dvPortKey = null;
   private DistributedVirtualSwitch dvs;
   private DistributedVirtualPortgroup iDVPortGroup;
   private Folder folder;
   private ManagedObjectReference vDsMor;
   private String vDsName = TestUtil.getShortTime() + "_VDS";

   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      DVPortgroupPolicy policy = null;
      DVPortgroupConfigSpec dvpgCfg = null;
      List<ManagedObjectReference> portgroupMors = null;
      List<DistributedVirtualPort> dvports = null;

      folder = new Folder(connectAnchor);
      dvs = new DistributedVirtualSwitch(connectAnchor);
      iDVPortGroup = new DistributedVirtualPortgroup(connectAnchor);
      vDsMor = folder.createDistributedVirtualSwitch(vDsName);
      assertNotNull(vDsMor, "Successfully created VDS: " + vDsName,
               "Failed to create VDS: " + vDsName);
      log.info("Adding a early binding DVPortgroup with "
               + "setBlockOverrideAllowed to false in DefaultPortConfig...");
      policy = new DVPortgroupPolicy();
      policy.setBlockOverrideAllowed(false);
      dvpgCfg = new DVPortgroupConfigSpec();
      dvpgCfg.setName(vDsName + DVPORTGROUP_TYPE_EARLY_BINDING);
      dvpgCfg.setType(DVPORTGROUP_TYPE_EARLY_BINDING);
      dvpgCfg.setNumPorts(1);
      dvpgCfg.setPolicy(policy);
      /* Add early binding port group. */
      portgroupMors = dvs.addPortGroups(vDsMor,
               new DVPortgroupConfigSpec[] { dvpgCfg });
      assertTrue(((portgroupMors != null) && (portgroupMors.size() > 0)),
               "Succssfully added " + portgroupMors.size() + " portgroups.",
               "Failed to add port group(s).");
      dvports = this.iDVPortGroup.getPorts(portgroupMors.get(0));
      assertTrue(((dvports != null) && (dvports.size() == 1)),
               "Failed to get free port from DVPG");
      dvPortKey = dvports.get(0).getKey();
      assertNotNull(dvPortKey, "Failed to get key for DistributedVirtualPort");
      return true;
   }

   @Override
   @Test(description = "SDK client must not allow ReconfigurePort api to change the blocked property  when portgroup.policy.blockOverrideAllowed is set to false. (PR#610729)")
   public void test()
      throws Exception
   {
      try {
         DVPortSetting setting = null;
         DVPortConfigSpec portCfg = null;
         setting = new DVPortSetting();
         setting.setBlocked(DVSUtil.getBoolPolicy(false, true));
         portCfg = new DVPortConfigSpec();
         portCfg.setKey(dvPortKey);
         portCfg.setSetting(setting);
         portCfg.setOperation(CONFIG_SPEC_EDIT);
         dvs.reconfigurePort(vDsMor, new DVPortConfigSpec[] { portCfg });
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new InvalidArgument();
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
      // delete the VDS
      Assert.assertTrue(dvs.destroy(vDsMor), "VDS destroyed : " + vDsName,
               "Unable to destroy VDS :" + vDsName);
      return true;
   }
}
