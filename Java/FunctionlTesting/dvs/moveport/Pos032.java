/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.moveport;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING;

import java.util.Map;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Move a standalone DVPort in DVS to an late binding DVPortgroup. Setup: 1.
 * Create a DVS. 2. Create a standalone DVPort and use it as port to be moved.
 * 3. Create late binding DVPortgroup and use it's key as destination. Test: 4.
 * Move the standalone DVPort to late binding DVPortgroup. Cleanup: 5. Remove
 * the DVS.
 */
public class Pos032 extends MovePortBase
{
   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription(" Move a standalone DVPort in DVS to an "
               + "late binding DVPortGroup.");
   }

   /**
    * Test setup.
    * 
    * @param connectAnchor ConnectAnchor.
    * @return boolean true, if test setup was successful. false, otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
     
         if (super.testSetUp()) {
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName);
            if (dvsMor != null) {
               log.info("DVS created: " + iDVSwitch.getName(dvsMor));
               portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, 1);
               if ((portKeys != null) && (portKeys.size() > 0)) {
                  log.info("Successfully created a standalone DVPort.");
                  portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                           DVPORTGROUP_TYPE_LATE_BINDING, 1, prefix + "PG");
                  if (portgroupKey != null) {
                     log.info("Successfully created late binding DVPortgroup.");
                     status = true;
                  } else {
                     log.error("Failed to create late binding DVPortgroup.");
                  }
               } else {
                  log.error("Failed to create the standalone DVPort.");
               }
            }
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = " Move a standalone DVPort in DVS to an "
               + "late binding DVPortGroup.")
   public void test()
      throws Exception
   {
      boolean status = false;
     
         Map<String, DistributedVirtualPort> connectedEntitiespMap = DVSUtil.getConnecteeInfo(
                  connectAnchor, dvsMor, portKeys);
         status = movePort(dvsMor, portKeys, portgroupKey);
         status &= DVSUtil.verifyConnecteeInfoAfterMovePort(connectAnchor,
                  connectedEntitiespMap, dvsMor, portKeys, portgroupKey);
     
      assertTrue(status, "Test Failed");
   }
}
