/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import ch.ethz.ssh2.Connection;

import com.vmware.vc.HostConnectSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.util.SSHUtil;
import com.vmware.vcqa.util.TestUtil;

/**
 * Disconnect the host from the VC inventory after this host has been previously
 * added to a DVSwitch without removing the host from the DVSwitch. Remove the
 * DVSwitch from the VC inventory after removing all the connected entities.
 * Connect the host back to the VC.
 */
public class Pos009 extends FunctionalTestBase
{

   private String dvsName = null;
   private Connection conn = null;
   private HostConnectSpec hostConnectSpec = null;
   private ManagedObjectReference hostFolder = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Disconnect the host from the VC inventory after "
               + "this host has been previously added to a DVSwitch"
               + " without removing the host from the DVSwitch. "
               + "Remove the DVSwitch from the VC inventory after "
               + "removing all the connected entities. Connect the "
               + "host back to the VC.");
   }

   /**
    * Method to setup the environment for the test.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean setUpDone = false;
     
         setUpDone = super.testSetUp();
         if (setUpDone) {
            this.hostConnectSpec = this.ihs.getHostConnectSpec(this.hostMor);
            this.dvsName = this.iDVS.getConfig(this.dvsMor).getName();
            this.hostFolder = this.ihs.getHostFolder(this.hostMor);
         }
     
      assertTrue(setUpDone, "Setup failed");
      return setUpDone;
   }

   /**
    * Method that performs the test.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Disconnect the host from the VC inventory after "
               + "this host has been previously added to a DVSwitch"
               + " without removing the host from the DVSwitch. "
               + "Remove the DVSwitch from the VC inventory after "
               + "removing all the connected entities. Connect the "
               + "host back to the VC.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean testDone = false;
      String esxHostName = null;
      int totalTimeout = 6 * 60 * 1000;
     
         esxHostName = this.ihs.getHostName(this.hostMor);
         if (esxHostName != null) {
            testDone = this.ihs.destroy(this.hostMor);
            if (testDone) {
               log.info("Removed the hsot from the VC inventory");
               testDone = this.iDVS.destroy(this.dvsMor);
               if (testDone) {
                  this.hostMor = this.ihs.addStandaloneHost(this.hostFolder,
                           this.hostConnectSpec, null, true);
                  if (this.hostMor != null) {
                     this.nwSystemMor = this.ins.getNetworkSystem(this.hostMor);
                     log.info("Sleeping for 6 minutes for the DVS sync to "
                              + "happen to remove the proxy dvs from the host");
                     for (int i = 0; i < totalTimeout / (30 * 1000); i++) {
                        Thread.sleep(30 * 1000);
                        if (this.ins.refresh(this.nwSystemMor)) {
                           if (this.ins.getHostProxyVswitchConfig(
                                    this.nwSystemMor, this.dvSwitchUUID) == null) {
                              log.info("Successfully destroyed the proxy "
                                       + "vswitch on the host ");
                              testDone = true;
                              break;
                           } else {
                              testDone = false;
                              log.error("The proxy vswitch on the host is "
                                       + "not destroyed");
                           }
                        } else {
                           testDone = false;
                           log.error("Can not refresh the network info "
                                    + "on the host ");
                        }
                     }

                  } else {
                     testDone = false;
                     log.error("Can nto add the host back to the VC");
                  }
               } else {
                  log.error("Can not detroy the DVS " + this.dvsName);
               }
            } else {
               log.error("Can not destroy the DVS" + esxHostName);
            }
         } else {
            log.error("The host name is null");
         }
     

      assertTrue(testDone, "Test Failed");
   }

   /**
    * Restores the state prior to running the test.
    * 
    * @param connectAnchor ConnectAnchor Object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean cleanUpDone = true;
      ManagedObjectReference tempDVSMor = null;
      try {
         tempDVSMor = this.iFolder.getDistributedVirtualSwitch(
                  this.iFolder.getNetworkFolder(this.dcMor), this.dvsName);
         if (tempDVSMor != null) {
            cleanUpDone &= this.iDVS.destroy(tempDVSMor);
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
         cleanUpDone = false;
      } finally {
         if (this.conn != null) {
            try {
               cleanUpDone &= SSHUtil.closeSSHConnection(this.conn);
            } catch (Exception ex) {
               TestUtil.handleException(ex);
               cleanUpDone = false;
            }
         }
      }
      assertTrue(cleanUpDone, "Cleanup failed");
      return cleanUpDone;
   }
}