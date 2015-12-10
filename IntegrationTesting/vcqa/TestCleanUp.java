/*
 * ************************************************************************
 *
 * Copyright 2013 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 * 
 * This class is used for cleaning up the objects after tests are run.
 * 
 * Usage
 * =====
 * When test cases are creating objects like VMs or VVol DataStore etc.. , 
 * add those objects in HashMap using addObjectsToCleanup method of TestCleanup class. 
 * Hashmap contains repository for objects that are created and need to be deleted at the end of tests.
 * 
 * Once your test run is over call cleanup method to clean the objects. 
 * Objects are cleaned in order they are added in HashMap so please ensure that you care dependency while adding the objects to map.
 * 
 */

package com.vmware.vcqa;

import java.util.ArrayList;
import java.util.List;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestConstants.objectType;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.host.VvolDatastoreUtil;

/**
 * @author anoopjain
 * 
 */
public final class TestCleanUp
{

   // Repository for objects to be cleaned
   // Key of HashMap : Type of object
   // Value of HashMap : List of objects of given type.
   private static ObjectMap     objectsForCleanup = new ObjectMap();
   private static ConnectAnchor connectAnchor;

   /**
    * Adds the objects to be cleaned
    * 
    * @param type Type of objects
    * @param object Listof objects or Single object
    * @return
    */

   public static void addObjectsToCleanup(objectType type,
                                          Object object)
   {
      objectsForCleanup.add(type, object);
   }

   /**
    * Destroy the object maintained in the repository
    * 
    * @param ConnectAnchor Connection object
    * @return result of cleanup
    */

   public static ObjectMap cleanup(ConnectAnchor c)
   {
      ObjectMap resultMap = new ObjectMap();
      connectAnchor = c;
      for (objectType type : objectsForCleanup.getKeys()) {
         try {
            resultMap.add(type, removeObjects(type));
         } catch (Exception e) {
            resultMap.add(type, e);
         }
      }

      return resultMap;
   }

   /**
    * Destroy the object of given type
    * 
    * @param type Object Type
    * @return result of cleanup
    */

   private static List<Object> removeObjects(objectType type)
   {
      List<Object> resultList = new ArrayList<Object>();

      try {
         if (type == TestConstants.objectType.OBJECTTYPE_VM) {
            VirtualMachine vm = new VirtualMachine(connectAnchor);

            List<Object> vmList = objectsForCleanup.get(type);

            for (Object vmMor : vmList) {
               try {
                  ManagedObjectReference testVm = (ManagedObjectReference) vmMor;
                  vm.setVMState(testVm, VirtualMachinePowerState.POWERED_OFF,
                           false);
                  if (vm.destroy(testVm))
                     resultList.add(new Boolean(true));
                  else
                     resultList.add(new Boolean(false));
               } catch (Exception e) {
                  resultList.add(e);
               }
            }
         } else if (type == TestConstants.objectType.OBJECTTYPE_VVOLDS) {
            ManagedObjectReference dsMor = (ManagedObjectReference) objectsForCleanup
                     .get(type).get(0);
            VvolDatastoreUtil vvolHelper = new VvolDatastoreUtil(connectAnchor);
            vvolHelper.removeVvolDatastore((new HostSystem(connectAnchor))
                     .getAllHost().get(0), dsMor);

            resultList.add(new Boolean(true));
         }

         resultList.add(new Boolean(true));
      } catch (Exception e) {
         resultList.add(e);
      }
      return resultList;

   }
}
