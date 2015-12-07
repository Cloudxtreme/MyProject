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
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING;

import java.util.List;
import java.util.Map;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Move a DVPort (not bound to any VM) in an early binding DVPortGroup to a late
 * binding DVPortGroup. This test is a Functional Feature Acceptance Test
 * (FFAT).
 */
public class Pos003 extends MovePortBase
{
   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move a DVPort (not bound to any VM) in an early "
               + "binding DVPortGroup to a late binding DVPortGroup.");
   }

   /**
    * Test setup. 1. Create DVS. 2. Create early binding DVPortGroup. 3. Create
    * late binding DVPortGroup. 3. Use a DVPort from early binding DVPortGroup
    * as the port to be moved. 4. Use the key of the late binding DVPortgroup as
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
      DVPortgroupConfigSpec aPortGroupCfg = null;
     
         if (super.testSetUp()) {
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName);
            if (dvsMor != null) {
               log.info("Adding early bind DVPortgroup...");
               aPortGroupCfg = buildDVPortgroupCfg(
                        DVPORTGROUP_TYPE_EARLY_BINDING, 1, null, null);
               portgroupKeys = addPortgroups(dvsMor, aPortGroupCfg);
               if (portgroupKeys != null) {
                  log.info("Added early binding DVPortgroup: "
                           + portgroupKeys);
                  // fetch the port key of this early bind port group.
                  portKeys = fetchPortKeys(dvsMor, portgroupKeys.get(0));
                  if (portKeys != null) {
                     log.info("Adding late binding DVPortgroup...");
                     aPortGroupCfg = buildDVPortgroupCfg(
                              DVPORTGROUP_TYPE_LATE_BINDING, 1, null, null);
                     portgroupKeys = addPortgroups(dvsMor, aPortGroupCfg);
                     if ((portgroupKeys != null) && (portgroupKeys.size() > 0)) {
                        log.info("Successfully added late bind DVPortgroup.");
                        portgroupKey = portgroupKeys.get(0);
                        status = true;
                     } else {
                        log.error("Failed to add late bind DVPortgroup.");
                     }
                  } else {
                     log.error("Failed to get DVPorts from late binding "
                              + "DVPortgroup.");
                  }
               } else {
                  log.error("Failed to get DVPorts from early binding "
                           + "DVPortgroup.");
               }
            }
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test. Move DVPort from early binding DVPortgroup to late binding
    * DVPortgroup.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Move a DVPort (not bound to any VM) in an early "
               + "binding DVPortGroup to a late binding DVPortGroup.")
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
