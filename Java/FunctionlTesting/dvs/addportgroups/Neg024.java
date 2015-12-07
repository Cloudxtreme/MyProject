/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

import static com.vmware.vcqa.util.Assert.*;

import java.util.HashMap;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NumericRange;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VmwareDistributedVirtualSwitchTrunkVlanSpec;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Add a portgroup with an invalid vlanid range
 */
public class Neg024 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private ManagedObjectReference dcMor = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a portgroup with an invalid vlanid range");
   }

   /**
    * Method to setup the environment for the test. This method creates a
    * distributed virtual switch.
    *
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      VMwareDVSPortSetting portSetting = null;
      VmwareDistributedVirtualSwitchTrunkVlanSpec trunkvlanspec = null;
      NumericRange range = null;
      Map<String, Object> settingsMap = null;
      log.info("Test setup Begin:");
      iFolder = new Folder(connectAnchor);
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      iManagedEntity = new ManagedEntity(connectAnchor);
      dcMor = iFolder.getDataCenter();
      if (dcMor != null) {
         log.info("Successfully found the datacenter");
         dvsConfigSpec = new DVSConfigSpec();
         dvsConfigSpec.setName(this.getClass().getName());
         dvsMor = iFolder.createDistributedVirtualSwitch(
                  iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
         if (dvsMor != null) {
            log.info("Successfully created the distributed " + "virtual switch");
            dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
            dvPortgroupConfigSpec.setName(getTestId());
            dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
            dvPortgroupConfigSpec.setNumPorts(2);
            dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
            trunkvlanspec = new VmwareDistributedVirtualSwitchTrunkVlanSpec();
            range = new NumericRange();
            range.setStart(-15);
            trunkvlanspec.getVlanId().clear();
            trunkvlanspec.getVlanId().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new NumericRange[] { range }));
            settingsMap = new HashMap<String, Object>();
            settingsMap.put(DVSTestConstants.VLAN_KEY, trunkvlanspec);
            portSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
            dvPortgroupConfigSpec.setDefaultPortConfig(portSetting);
            status = true;
         } else {
            log.error("Failed to create the distributed " + "virtual switch");
         }
      } else {
         log.error("Failed to find a folder");
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that adds a portgroup with an invalid vlanid range
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "Add a portgroup with an invalid vlanid range")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      try {
         dvPortgroupConfigSpecArray = new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec };
         iDVSwitch.addPortGroups(dvsMor,
                  dvPortgroupConfigSpecArray);
         log.error("API did not throw an exception");
      } catch (final Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         final InvalidArgument expectedMethodFault = new InvalidArgument();
         status = TestUtil.checkMethodFault(actualMethodFault,
                  expectedMethodFault);
      }
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started. Destroy
    * the portgroup, followed by the distributed virtual switch
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;
      /*
       * if(this.dvPortgroupMorList != null){ for(ManagedObjectReference mor:
       * dvPortgroupMorList){ status = this.iManagedEntity.destroy(mor); } }
       */
      status = iManagedEntity.destroy(dvsMor);
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
