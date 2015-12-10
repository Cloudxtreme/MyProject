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
 * Move n DVPorts in late binding DVPortGroup to another late binding
 * DVPortGroup.
 */
public class Pos017 extends MovePortBase
{
   /* Number of ports to be moved. */
   private int totalNumPorts = 10;

   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move n DVPorts in late binding DVPortGroup to "
               + "another late binding DVPortGroup.");
   }

   /**
    * Test setup. 1. Create DVS. 2. Create late binding DVPortGroup with n
    * ports. 3. Use n DVPorts in late binding DVPortgroup as ports to be moved.
    * 4. Create another late binding DVPortGroup and use it's key as
    * destination.
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
      DVPortgroupConfigSpec aPortgroupCfg = null;
     
         if (super.testSetUp()) {
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName);
            if (dvsMor != null) {
               aPortgroupCfg = buildDVPortgroupCfg(
                        DVPORTGROUP_TYPE_LATE_BINDING, totalNumPorts, null,
                        null);
               portgroupKeys = addPortgroups(dvsMor, aPortgroupCfg);
               if ((portgroupKeys != null) && !portgroupKeys.isEmpty()) {
                  Iterator<String> iterator = portgroupKeys.iterator();
                  portKeys = fetchPortKeys(dvsMor, iterator.next());
                  aPortgroupCfg = buildDVPortgroupCfg(
                           DVPORTGROUP_TYPE_LATE_BINDING, 1, null, null);
                  portgroupKeys = addPortgroups(dvsMor, aPortgroupCfg);
                  if ((portgroupKeys != null) && (portgroupKeys.size() >= 1)) {
                     iterator = portgroupKeys.iterator();
                     // set the late bind DVPortgroup key as destination.
                     portgroupKey = iterator.next();
                     status = true;
                  } else {
                     log.error("Failed to create another late bind DVPortgroup.");
                  }
               } else {
                  log.error("Failed to create late bind DVPortgroup.");
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
   @Test(description = "Move n DVPorts in late binding DVPortGroup to "
               + "another late binding DVPortGroup.")
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
