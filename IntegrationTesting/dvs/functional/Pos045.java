/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMember;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;

/**
 * Reconfigure a DVS to add a pnic to same uplink port that it currently binds
 * to .
 */
public class Pos045 extends FunctionalTestBase
{
   // private instance variables go here.
   private List<ManagedObjectReference> dvPortgroupMorList = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Reconfigure a DVS to add a pnic to same uplink port "
               + " that it currently binds to");
   }

   /**
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "Reconfigure a DVS to add a pnic to same uplink port "
               + " that it currently binds to")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean testDone = false;
      List<String> portKeys = null;
      List<String> allPortKeys = null;
      String portgroupKey = null;
      DistributedVirtualSwitchPortCriteria prtCriteria = null;
      String pnicDevice = null;
     
         dvPortgroupMorList = this.iDVS.getUplinkPortgroups(this.dvsMor);
         if (dvPortgroupMorList != null && dvPortgroupMorList.size() == 1) {
            allPortKeys = this.iDVPortgroup.getPortKeys(dvPortgroupMorList.get(0));
            portgroupKey = this.iDVPortgroup.getKey(dvPortgroupMorList.get(0));
            prtCriteria = this.iDVS.getPortCriteria(false, null, hostMor,
                     new String[] { portgroupKey }, null, true);
            prtCriteria.setUplinkPort(true);
            portKeys = this.iDVS.fetchPortKeys(dvsMor, prtCriteria);
            for (String port : allPortKeys) {
               if (!portKeys.contains(port)) {
                  DVSConfigInfo dvsConfigInfo = this.iDVS.getConfig(dvsMor);
                  DistributedVirtualSwitchHostMember[] hosts = com.vmware.vcqa.util.TestUtil.vectorToArray(dvsConfigInfo.getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class);
                  for (DistributedVirtualSwitchHostMember dvsHostMember : hosts) {
                     if (dvsHostMember.getConfig().getHost().equals(
                              this.hostMor)) {
                        DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = (DistributedVirtualSwitchHostMemberPnicBacking) dvsHostMember.getConfig().getBacking();
                        DistributedVirtualSwitchHostMemberPnicSpec[] pnicSpec = com.vmware.vcqa.util.TestUtil.vectorToArray(pnicBacking.getPnicSpec(), com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec.class);
                        com.vmware.vcqa.util.Assert.assertNotNull(pnicSpec,
                                 "pnicSpec is null");
                        pnicDevice = pnicSpec[0].getPnicDevice();
                        testDone = reConfigDVS(pnicDevice, port, portgroupKey);

                     }
                  }
                  break;
               }
            }

         }

     
      assertTrue(testDone, "Test Failed");
   }

   private boolean reConfigDVS(String pnic,
                               String port,
                               String pgKey)
      throws Exception
   {

      DVSConfigSpec deltaConfigSpec = null;

      boolean status = false;
      deltaConfigSpec = new DVSConfigSpec();
      String validConfigVersion = this.iDVS.getConfig(this.dvsMor).getConfigVersion();
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
      hostMember.setOperation(TestConstants.CONFIG_SPEC_EDIT);
      hostMember.setHost(this.hostMor);
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
      pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
      pnicSpec.setPnicDevice(pnic);
      pnicSpec.setUplinkPortgroupKey(pgKey);
      pnicSpec.setUplinkPortKey(port);

      pnicBacking.getPnicSpec().clear();
      pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
      hostMember.setBacking(pnicBacking);
      deltaConfigSpec.getHost().clear();
      deltaConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMember }));
      deltaConfigSpec.setConfigVersion(validConfigVersion);
      status = this.iDVS.reconfigure(this.dvsMor, deltaConfigSpec);
      if (status) {
         log.info("Successfully reconfigured DVS");
      } else {
         log.error("Failed to reconfigure dvs");
      }
      return status;
   }

   /**
    * Restores the state prior to running the test.
    * 
    * @param connectAnchor ConnectAnchor Object
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean cleanUpDone = true;
     
         cleanUpDone = super.testCleanUp();

     
      assertTrue(cleanUpDone, "Cleanup failed");
      return cleanUpDone;
   }
}