/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostProxySwitchConfig;
import com.vmware.vc.HostProxySwitchSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.UserSession;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * Deleting a proxySwitch on hostd, ensured it got spec-synced by VC after a
 * while (PR#391823)
 */
public class Pos040 extends FunctionalTestBase
{
   private SessionManager sessionManager = null;
   /*
    * Private data variables
    */
   private ConnectAnchor hostConnectAnchor = null;
   private String hostName = null;
   private String origUUID = null;

   /**
    * Set test description.
    */
   public void setTestDescription()
   {
      setTestDescription("Deleting a proxySwitch on hostd, ensured it got"
               + " spec-synced by VC  after a while");
   }

   /**
    * Method to setup the environment for the test. 1. Create the DVSwitch. 2.
    * Create the Standalone DVPort. 3. Create the VM ConfigSpec.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if setup is successful.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      sessionManager = new SessionManager(connectAnchor);

      boolean status = false;
      log.info("test setup Begin:");
      if (super.testSetUp()) {
        
            this.hostName = this.ihs.getHostName(this.hostMor);
            log.info("hostName :" + hostName);
            origUUID = this.iDVS.getConfig(this.dvsMor).getUuid();
            status = true;
        
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test. 1. Create the VM. 2. Varify the ConfigSpecs and Power-ops
    * operations.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Test(description = "Deleting a proxySwitch on hostd, ensured it got"
               + " spec-synced by VC  after a while")
   public void test()
      throws Exception
   {
      boolean status = false;
      UserSession newLoginSession = null;
      AuthorizationManager newAuthentication = null;
      ManagedObjectReference newAuthenticationMor = null;
      NetworkSystem newIns = null;
      ManagedObjectReference newNwSystemMor = null;
      HostNetworkConfig newNetworkCfg = null;
      HostProxySwitchConfig hvs[] = new HostProxySwitchConfig[1];

      try {
          hostConnectAnchor = new ConnectAnchor(
                  this.ihs.getHostName(hostMor),
                  data.getInt(TestConstants.TESTINPUT_PORT));
         newAuthentication = new AuthorizationManager(hostConnectAnchor);
         sessionManager = new SessionManager(hostConnectAnchor);
         newAuthenticationMor = sessionManager.getSessionManager();
         if (newAuthenticationMor != null) {
            newLoginSession = sessionManager.login(newAuthenticationMor,
                     TestConstants.ESX_USERNAME, TestConstants.ESX_PASSWORD,
                     null);
            if (newLoginSession != null) {
               this.ivm = new VirtualMachine(this.hostConnectAnchor);
               this.ihs = new HostSystem(this.hostConnectAnchor);
               newIns = new NetworkSystem(hostConnectAnchor);
               this.hostMor = this.ihs.getConnectedHost(false);
               newNwSystemMor = newIns.getNetworkSystem(this.hostMor);
               if (this.nwSystemMor != null) {
                  HostProxySwitchConfig hvswitch1[] = com.vmware.vcqa.util.TestUtil.vectorToArray(newIns.getNetworkConfig(
                                    newNwSystemMor).getProxySwitch(), com.vmware.vc.HostProxySwitchConfig.class);
                  if (hvswitch1 != null) {
                     int length = hvswitch1.length;
                     for (int i = 0; i < length; i++) {

                        if (origUUID.equalsIgnoreCase(hvswitch1[i].getUuid())) {
                           log.info("Successfully found the   proxy Switch "
                                    + "with  " + origUUID + " on the host ");
                           /*
                            * Remove proxy switch
                            */
                           newNetworkCfg = new HostNetworkConfig();
                           HostProxySwitchSpec spec = hvswitch1[i].getSpec();

                           hvs[0] = new HostProxySwitchConfig();
                           hvs[0].setChangeOperation(TestConstants.NETWORKCFG_OP_REMOVE);
                           hvs[0].setUuid(hvswitch1[i].getUuid());
                           hvs[0].setSpec(spec);
                           newNetworkCfg.getProxySwitch().clear();
                           newNetworkCfg.getProxySwitch().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(hvs));
                           if (newIns.updateNetworkConfig(newNwSystemMor,
                                    newNetworkCfg,
                                    TestConstants.CHANGEMODE_MODIFY)) {
                              HostProxySwitchConfig proxyVwitch1[] = com.vmware.vcqa.util.TestUtil.vectorToArray(newIns.getNetworkConfig(
                                                newNwSystemMor).getProxySwitch(), com.vmware.vc.HostProxySwitchConfig.class);
                              if (proxyVwitch1 == null
                                       || proxyVwitch1.length == 0) {
                                 log.info("Successfully modified  the "
                                          + "Network Config with deletion of  "
                                          + "proxy Switch");
                                 while (true) {
                                    log.info("Sleeping for one minute");
                                    Thread.sleep(60000);
                                    HostProxySwitchConfig hvswitch3[] = com.vmware.vcqa.util.TestUtil.vectorToArray(newIns.getNetworkConfig(
                                                      newNwSystemMor).getProxySwitch(), com.vmware.vc.HostProxySwitchConfig.class);
                                    if (hvswitch3 != null
                                             && hvswitch3.length > 0) {
                                       length = hvswitch3.length;
                                       for (int j = 0; j < length; j++) {
                                          log.info("Successfully modified  the"
                                                   + " Network Config "
                                                   + "with addition of one Virtual "
                                                   + "Switch"
                                                   + hvswitch3[j].getUuid());
                                          if (origUUID.equalsIgnoreCase(hvswitch3[j].getUuid())) {
                                             log.info("Proxy Switch got "
                                                      + " spec-synced by VC");
                                             status = true;

                                          }
                                       }
                                    } else {
                                       continue;
                                    }
                                    if (status)
                                       break;
                                 }

                              }
                           } else {
                              log.error("Unable to update the Network Config");
                           }
                        } else {
                           log.error("Unable to find the Proxy Switch"
                                    + " with uuid : " + origUUID);
                        }
                     }
                  } else {
                     log.error("Unable to find the Proxy Switch"
                              + " on host with uuid : " + origUUID);
                  }
               }
            } else {
               log.error("Can not login into the host " + this.hostName);
            }
         } else {
            log.error("The session manager object is null");
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
         status &= false;
      } finally {
         try {
            status &= sessionManager.logout(newAuthenticationMor);
         } catch (Exception e) {
            log.error("Can not logut from hostd");
            TestUtil.handleException(e);
            status &= false;
         }
      }
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if successful.
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;
     
         status = super.testCleanUp();

     

      assertTrue(status, "Cleanup failed");
      return status;
   }
}