/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addvirtualnic;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.util.TestUtil;

import dvs.VNicBase;

/**
 * Add a vnic to connect to an existing DVPort on an lateBinding DVPortgroup on
 * an existing DVSwitch. The distributedVirtualPort is of type DVSPortgroup
 * Connection. Build DVPortConnection with valid DVPortKey on a lateBinding
 * portgroup and invalid DVPortgroup Key.
 */
public class Neg005 extends VNicBase
{
   private DistributedVirtualSwitchPortConnection dvsPortConnection = null;
   private HostVirtualNicSpec hostVNicSpec = null;
   private String dvSwitchUuid = null;
   private String vNicId = null;

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a vnic to connect to an "
               + "existing DVPort on an lateBinding DVPortgroup on an existing  "
               + "DVSwitch. The distributedVirtualPort is of type DVSPort "
               + "Connection. Build DVPortConnection with valid DVPortKey on "
               + "a lateBinding portgroup and invalid DVPortgroupKey.");
   }

   /**
    * Method to setup the environment for the test. 1. Create the DVSwitch. 2.
    * Get the lateBinding DVPortKey. 3. Build the DVPortConnection. 4. Create
    * HostVirtualNicSpec Object and set the values.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if setup is successful.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      String portgroupKey = null;
      List<String> portKeys = null;
      String aPortKey = null;
      log.info("test setup Begin:");
      if (super.testSetUp()) {
        
            hostMor = ihs.getStandaloneHost();
            log.info("Host MOR: " + hostMor);
            log.info("Host Name: " + ihs.getHostName(hostMor));
            // create the DVS by using standalone host.
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
            // Get the earlyBinding DVPortgroup Key.
            portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                     DVPORTGROUP_TYPE_LATE_BINDING, 1, getTestId() + "-PG.");
            if (portgroupKey != null) {
               // Get the DVSUuid.
               DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
               dvSwitchUuid = info.getUuid();
               // Get the DVPort key
               portKeys = fetchPortKeys(dvsMor, portgroupKey);
               aPortKey = portKeys.get(0);
               // create the DistributedVirtualSwitchPortConnection object.
               dvsPortConnection = buildDistributedVirtualSwitchPortConnection(
                        dvSwitchUuid, aPortKey, "xyz");
               // Create the hostVNicSpec object.
               hostVNicSpec = ins.createVNicSpecification();
               hostVNicSpec.setDistributedVirtualPort(dvsPortConnection);
               status = true;
            } else {
               log.error("Failed to add the portgroup to DVS. ");
            }
        
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test. 1. Add the VirtualNic.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Add a vnic to connect to an "
               + "existing DVPort on an lateBinding DVPortgroup on an existing  "
               + "DVSwitch. The distributedVirtualPort is of type DVSPort "
               + "Connection. Build DVPortConnection with valid DVPortKey on "
               + "a lateBinding portgroup and invalid DVPortgroupKey.")
   public void test()
      throws Exception
   {
      boolean status = false;
      MethodFault expectedFault = new InvalidArgument();
      try {
         nwSystemMor = ins.getNetworkSystem(hostMor);
         vNicId = ins.addVirtualNic(nwSystemMor, "", hostVNicSpec);
         if (vNicId != null) {
            log.error("Successfully add the Virtual NIC."
                     + "API didn't throw any exception.");
         }
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         status = TestUtil.checkMethodFault(actualMethodFault, expectedFault);
      }
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if successful.
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         if (vNicId != null) {
            if (ins.removeVirtualNic(nwSystemMor, vNicId)) {
               log.info("Successfully removed the Virtual NIC "
                        + this.vNicId);
            } else {
               log.error("Unable to remove the Virtual NIC "
                        + this.vNicId);
               status = false;
            }
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      } finally {
         status &= super.testCleanUp();
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
