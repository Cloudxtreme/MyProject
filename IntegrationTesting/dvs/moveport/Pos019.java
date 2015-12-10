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

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Move n DVPorts (not bound to any VM if in early bound Port group) where some
 * are from a early binding and some are from late binding DVPortGroup to a late
 * bind DVPortGroup. Move DVPorts in (early & late -> late) bind DVPortgroup.
 */
public class Pos019 extends MovePortBase
{
   /* Number of ports to be moved. */
   private int totalNumPorts = 10;

   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move n DVPorts (not bound to any VM if in early "
               + "bound Port group) where some are from a early binding and "
               + "some are from late binding DVPortGroup "
               + "to a late bind DVPortGroup.");
   }

   /**
    * Test setup. 1. Create DVS. 2. Create early binding DVPortGroup with n/2
    * ports. 3. Create late binding DVPortGroup with n/2 ports. 4. Use DVPorts
    * in early and late binding DVPortgroups as ports to move. 5. Create late
    * binding DVPortGroup and use its key as destination.
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
      int numPorts = totalNumPorts / 2;
     
         if (super.testSetUp()) {
            // 1. Create DVS.
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName);
            portKeys = new ArrayList<String>(totalNumPorts);
            // 2. Create early binding DVPortGroup with n/2 ports.
            aPortgroupCfg = buildDVPortgroupCfg(DVPORTGROUP_TYPE_EARLY_BINDING,
                     numPorts, null, null);
            portgroupKeys = addPortgroups(dvsMor, aPortgroupCfg);
            if ((portgroupKeys != null) && !portgroupKeys.isEmpty()) {
               portKeys.addAll(fetchPortKeys(dvsMor, portgroupKeys.get(0)));
               // 3. Create late binding DVPortGroup with n/2 ports.
               aPortgroupCfg = buildDVPortgroupCfg(
                        DVPORTGROUP_TYPE_LATE_BINDING, numPorts, null, null);
               portgroupKeys = addPortgroups(dvsMor, aPortgroupCfg);
               if ((portgroupKeys != null) && (portgroupKeys.size() >= 1)) {
                  portKeys.addAll(fetchPortKeys(dvsMor, portgroupKeys.get(0)));
                  log.info("Keys of DVPorts to be moved: " + portKeys);
                  // 5. Create late binding DVPortGroup and use its key.
                  aPortgroupCfg = buildDVPortgroupCfg(
                           DVPORTGROUP_TYPE_LATE_BINDING, 1, null, null);
                  portgroupKeys = addPortgroups(dvsMor, aPortgroupCfg);
                  if ((portgroupKeys != null) && (portgroupKeys.size() >= 1)) {
                     portgroupKey = portgroupKeys.get(0);
                     if (portKeys.size() >= totalNumPorts) {
                        status = true;
                     } else {
                        log.error("Failed to get required number of DVPorts.");
                     }
                  } else {
                     log.error("Failed to create destination DVPortGroup.");
                  }
               } else {
                  log.error("Failed to create early bind DVPortGroup.");
               }
            } else {
               log.error("Failed to create early bind DVPortGroup.");
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
   @Test(description = "Move n DVPorts (not bound to any VM if in early "
               + "bound Port group) where some are from a early binding and "
               + "some are from late binding DVPortGroup "
               + "to a late bind DVPortGroup.")
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
