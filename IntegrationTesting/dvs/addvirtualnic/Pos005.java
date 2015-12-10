/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addvirtualnic;

import static com.vmware.vc.HostSystemConnectionState.CONNECTED;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;

import dvs.VNicBase;

/**
 * Add a VNIC to connect to a standalone port on a DVSwitch. The
 * distributedVirtualPort is of type DistributedVirtualSwitchPortConnection.
 * Setup: 1. Create a DVS with a host in it. 2. Add standalone DVPort to the
 * DVS. 3. Update the host network configuration to use the DVS. Test: 3.
 */
public class Pos005 extends VNicBase
{
   private HostNetworkConfig origHostNetworkConfig = null;
   private List<String> portKeys = null;
   private String vNic = null;
   private String dvsUuid = null;

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a vmkernel vnic to connect to an "
               + "existing standalone port on an existing DVSwitch. "
               + "The distributedVirtualPort is of type DistributedVirtualSwitchPortConnection."
               + "Select this vnic to be the Vmkernel nic to be used in vMotion.");
   }

   /**
    * Method to setup the environment for the test.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return true if setup is successful.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      HashMap allHosts = null;
      log.info("Test setup begin... ");
      if (super.testSetUp()) {
        
            allHosts = ihs.getAllHosts(VersionConstants.ESX4x, CONNECTED);
            if ((allHosts != null) && !allHosts.isEmpty()) {
               hostMor = (ManagedObjectReference) allHosts.keySet().iterator().next();
               if (hostMor != null) {
                  log.info("Got the host: " + ihs.getName(hostMor));
                  nwSystemMor = ins.getNetworkSystem(hostMor);
               } else {
                  log.error("Unable to find the host.");
               }
            }
            if (nwSystemMor != null) {
               dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
               if (dvsMor != null) {
                  dvsUuid = iDVSwitch.getConfig(dvsMor).getUuid();
                  log.info("Add a standalone DVPort to connect the VNIC...");
                  portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, 1);
               } else {
                  log.error("Failed to create DVS.");
               }
               if ((portKeys != null) && !portKeys.isEmpty()) {
                  log.info("got portkeys: " + portKeys);
                  hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(
                           dvsMor, hostMor);
                  if (hostNetworkConfig != null) {
                     origHostNetworkConfig = hostNetworkConfig[1];
                     log.info("updating the host to use the DVS...");
                     if (ins.updateNetworkConfig(nwSystemMor,
                              hostNetworkConfig[0],
                              TestConstants.CHANGEMODE_MODIFY)) {
                        log.info("Successfully updated the host network.");
                        status = true;
                     } else {
                        log.error("Failed to update network.");
                     }
                  } else {
                     log.error("Failed to get the Network config to "
                              + "migrate to DVS.");
                  }
               } else {
                  log.error("Failed to get the standalone DVPort.");
               }
            } else {
               log.error("The network system Mor is null");
            }
        
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test. 1. Create the hostVirtualNic and add the VirtualNic to the
    * NetworkSystem. 2. Get the HostVNic Id and select the VNic for VMotion 3.
    * Migrate the VM.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Add a vmkernel vnic to connect to an "
               + "existing standalone port on an existing DVSwitch. "
               + "The distributedVirtualPort is of type DistributedVirtualSwitchPortConnection."
               + "Select this vnic to be the Vmkernel nic to be used in vMotion.")
   public void test()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchPortConnection portConnection = null;
      log.info("test Begin...");
     
         portConnection = buildDistributedVirtualSwitchPortConnection(dvsUuid,
                  portKeys.get(0), null);
         vNic = addVnic(hostMor, portConnection);
         if (vNic != null) {
            log.info("Successfully added the VNIC.");
            status = true;
         } else {
            log.error("Failed to add the virtual nic");
         }
     
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started. 1.
    * Migrate the VM back to Source host. 3. Remove the vNic and DVSMor.
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
         if (vNic != null) {
            status &= ins.removeVirtualNic(nwSystemMor, vNic);
            if (status) {
               log.info("Successfully remove the add vNic.");
            } else {
               log.error("Failed to remove the added vNic");
            }
         }
         if ((this.portKeys != null) && (this.portKeys.size() > 0)
                  && (this.portKeys.get(0) != null)) {
            log.info("Sleeping for 4 seconds");
            Thread.sleep(4000);
            if (this.iDVSwitch.refreshPortState(this.dvsMor,
                     new String[] { portKeys.get(0) })) {
               log.info("Successfully refreshed the port state");
            } else {
               log.error("Can not refresh the port state");
            }
         }
         if (origHostNetworkConfig != null) {
            status &= ins.updateNetworkConfig(nwSystemMor,
                     origHostNetworkConfig, TestConstants.CHANGEMODE_MODIFY);
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
