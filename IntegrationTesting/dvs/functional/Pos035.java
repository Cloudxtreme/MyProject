/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.Iterator;
import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupPolicy;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualPortgroupPortgroupType;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;

/**
 * 1.creates two uplink portgroups 2.Add a host 3.Move ports across two uplink
 * portgroups 4.Remove Host from DVS
 */
public class Pos035 extends FunctionalTestBase
{

   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private String portgroupKey = null;
   private DVSConfigSpec deltaConfigSpec = null;
   ManagedObjectReference sourceDvPortgroupMOR = null;
   ManagedObjectReference destDvPortgroupMOR = null;

   /**
    * Set test description.
    */
   public void setTestDescription()
   {
      setTestDescription("1.creates two uplink portgroups\n" + "2.Add a host"
               + "3.Move ports across two uplink portgroups"
               + "4.Remove Host from DVS ");
   }

   /**
    * Method to setup the environment for the test.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if setup is successful.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      log.info("test setup Begin:");
      if (super.testSetUp()) {
        
            this.deltaConfigSpec = new DVSConfigSpec();
            this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
            this.dvPortgroupConfigSpec.setName(this.getClass().getName()
                     + "-upg");
            this.dvPortgroupConfigSpec.setType(DistributedVirtualPortgroupPortgroupType.EARLY_BINDING.value());
            this.dvPortgroupConfigSpec.setNumPorts(0);
            dvPortgroupMorList = this.iDVS.addPortGroups(this.dvsMor,
                     new DVPortgroupConfigSpec[] { this.dvPortgroupConfigSpec });
            if (dvPortgroupMorList != null && dvPortgroupMorList.get(0) != null) {
               destDvPortgroupMOR = dvPortgroupMorList.get(0);
               log.info("The portgroup was successfully"
                        + " added to the dvswitch");
               status = true;
            } else {
               log.error("Failed to add the portgroup to the"
                        + " dvswitch");
            }

        
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Get NumPorts
    * 
    * @param dvsMor
    * @return int result
    * @throws Exception
    */
   private int getNumberOfPorts(List<ManagedObjectReference> portgroups)
      throws Exception
   {
      int result = 0;
      if (portgroups != null && !portgroups.isEmpty()) {
         for (Iterator iterator = portgroups.iterator(); iterator.hasNext();) {
            ManagedObjectReference dvPortgroupMor = (ManagedObjectReference) iterator.next();
            this.dvPortgroupConfigSpec = this.iDVPortgroup.getConfigSpec(dvPortgroupMor);
            result += this.dvPortgroupConfigSpec.getNumPorts();
            log.info(" Name : " + this.dvPortgroupConfigSpec.getName());
            log.info(" Number  : "
                     + this.dvPortgroupConfigSpec.getNumPorts());
         }
      }
      return result;
   }

   /**
    * Test.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Test(description = "1.creates two uplink portgroups\n" + "2.Add a host"
               + "3.Move ports across two uplink portgroups"
               + "4.Remove Host from DVS ")
   public void test()
      throws Exception
   {
      boolean status = false;
      log.info("test Begin:");
      List portKeys = null;
     
         dvPortgroupMorList = this.iDVS.getUplinkPortgroups(this.dvsMor);
         if (dvPortgroupMorList != null && dvPortgroupMorList.size() > 0) {
            dvPortgroupMorList.add(destDvPortgroupMOR);
            sourceDvPortgroupMOR = (ManagedObjectReference) dvPortgroupMorList.get(0);
            portKeys = this.iDVPortgroup.getPortKeys(sourceDvPortgroupMOR);
            destDvPortgroupMOR = (ManagedObjectReference) dvPortgroupMorList.get(1);
            portgroupKey = this.iDVPortgroup.getKey(destDvPortgroupMOR);
            this.deltaConfigSpec.getUplinkPortgroup().clear();
            this.deltaConfigSpec.getUplinkPortgroup().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector((ManagedObjectReference[]) TestUtil.vectorToArray((Vector) dvPortgroupMorList)));
            this.deltaConfigSpec.setConfigVersion(this.iDVS.getConfig(
                     this.dvsMor).getConfigVersion());
            status = this.iDVS.reconfigure(this.dvsMor, this.deltaConfigSpec);
            if (status) {
               log.info("Successfully reconfigured DVS");
               if (dvPortgroupMorList != null && !dvPortgroupMorList.isEmpty()) {
                  for (int i = 0; i < dvPortgroupMorList.size(); i++) {
                     sourceDvPortgroupMOR = (ManagedObjectReference) dvPortgroupMorList.get(i);
                     DVPortgroupConfigSpec tempDvPortgroupConfigSpec = this.iDVPortgroup.getConfigSpec(sourceDvPortgroupMOR);
                     DVPortgroupPolicy policy = new DVPortgroupPolicy();
                     policy.setLivePortMovingAllowed(true);
                     tempDvPortgroupConfigSpec.setPolicy(policy);
                     if (this.iDVPortgroup.reconfigure(sourceDvPortgroupMOR,
                              tempDvPortgroupConfigSpec)) {
                        log.error("Successfully reconfigured the portgroup");
                        status = true;
                     } else {
                        log.error("Failed to reconfigure the portgroup");
                        status = false;
                     }
                  }
               }

            } else {
               log.error("Failed to reconfigure dvs");
               status = false;
            }
            if (status && movePort(dvsMor, portKeys, portgroupKey)) {
               log.info("Moved");
               /*
                * Remove the host from DVS
                */
               DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
               String validConfigVersion = this.iDVS.getConfig(dvsMor).getConfigVersion();
               this.deltaConfigSpec.setConfigVersion(validConfigVersion);
               hostConfigSpecElement.setHost(this.hostMor);
               hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_REMOVE);
               this.deltaConfigSpec.getHost().clear();
               this.deltaConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
               status = this.iDVS.reconfigure(this.dvsMor, this.deltaConfigSpec);
               if (status) {
                  log.info("Successfully reconfigured DVS");
                  int noPorts = getNumberOfPorts(dvPortgroupMorList);
                  if (noPorts == 0) {
                     log.info("Successfully verified NumPorts :"
                              + noPorts);
                  } else {
                     log.error("NumPorts in dvs is not zero");
                  }
               } else {
                  log.error("Failed to reconfigure dvs");
                  status = false;
               }
            }
         }
     
      assertTrue(status, "Test Failed");
   }

   /**
    * Move the portkeys to portgroup represented by the portgroupkey.
    * 
    * @param dvsMor MOR of the DVS.
    * @param portKeys portkeys of the DVPorts to be moved.
    * @param portgroupKey Key of the destination portgroup.
    * @return boolean true, If moved successfully. false, otherwise.
    * @throws MethodFault On API errors.
    * @throws Exception On other problems.
    */
   private boolean movePort(ManagedObjectReference dvsMor,
                            List<String> portKeys,
                            String portgroupKey)
      throws Exception
   {
      boolean status = false;
      String[] keys = null;
      if (portKeys != null) {
         keys = portKeys.toArray(new String[portKeys.size()]);
      }
      if (portgroupKey != null) {
         log.info("Moving port(s) " + portKeys + " to portgroup: "
                  + portgroupKey);
      } else {
         log.info("Moving port(s) " + portKeys + " to DVS.");
      }
      if (iDVS.movePort(dvsMor, keys, portgroupKey)) {
         log.info("Successfully moved given ports.");
         status = true;
      } else {
         log.error("Failed to move the ports.");
      }
      return status;
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
      boolean status = true;
     
         if (this.dvsMor != null) {
            if (!this.iManagedEntity.destroy(dvsMor)) {
               log.error("Can not destroy the distributed virtual switch "
                        + this.iDVS.getConfig(this.dvsMor).getName());
               status = false;
            }
         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
