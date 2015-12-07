/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.moveport;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Move a DVPort in an early binding DVPortgroup to another early binding
 * DVPortGroup. Move DVPorts in (early -> early) bind DVPortgroup.
 */
public class Pos002 extends MovePortBase
{
   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move a DVPort in an early binding DVPortgroup "
               + "to another early binding DVPortgroup .");
   }

   /**
    * Test setup. 1. Create DVS. 2. Create two early binding DVPortgroups. 3.
    * Use a DVPort from first DVPortgroup as the port to be moved. 4. Use the
    * key of the other DVPortgroup as destination.
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
      List<String> portgroupKeys = null;
      DVPortgroupConfigSpec[] portgroups = new DVPortgroupConfigSpec[2];
      DVPortgroupConfigSpec aDVPortgroupCfg = null;
     
         if (super.testSetUp()) {
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName);
            if (dvsMor != null) {
               for (int i = 0; i < 2; i++) {
                  aDVPortgroupCfg = buildDVPortgroupCfg(
                           DVPORTGROUP_TYPE_EARLY_BINDING, 1, null, null);
                  portgroups[i] = aDVPortgroupCfg;
               }
               portgroupKeys = addPortgroups(dvsMor, portgroups);
               // These must be 2 port groups.
               if ((portgroupKeys != null) && (portgroupKeys.size() > 1)) {
                  log.info("Successfully created early binding DVPortGroups.");
                  Iterator<String> pgKeyIter = portgroupKeys.iterator();
                  // get a port from the first port group.
                  portKeys = fetchPortKeys(dvsMor, pgKeyIter.next());
                  if ((portKeys != null) && !portKeys.isEmpty()) {
                     log.info("Using port key " + portKeys + " to move.");
                     // set the key of the other DVPortgroup as destination.
                     portgroupKey = pgKeyIter.next();
                     status = true;
                  } else {
                     log.error("Failed to get DVPort from DVPortgroup.");
                  }
               } else {
                  log.error("Failed to create early binding DVPortGroups.");
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
   @Test(description = "Move a DVPort in an early binding DVPortgroup "
               + "to another early binding DVPortgroup .")
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
