/* ************************************************************************
*
* Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
*
* ************************************************************************
*/
package com.vmware.vcqa.vim.dvs.testframework;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;

/**
 * This class acts as a map between the user's input and the actual objects
 * that store these. It also captures the user's preferences on how to
 * place the inventory objects related to vds. For example, if we would
 * like any test client to assume portgroup keys out of vds (for negative
 * cases), we can pass this from this file.
 *
 * @author sabesanp
 */
public class CustomMap
{

   private Map<DVSConfigSpec,List<DVPortgroupConfigSpec>> vdsPortgroupMap =
      null;
   private List<List<DVPortgroupConfigSpec>> dvportgroupConfigSpecSelection =
      null;
   private Map<Object,List<Integer>> portSelectionMap = null;
   private List<DVSConfigSpec> hostVdsConfigSpec = null;
   private Boolean portKeysOutVds = null;
   private Boolean portgroupKeysOutVds = null;
   private Boolean hostMemberOutVds = null;
   /*
    * This holds the map between a target object id and a source object
    * id. This map will be useful in cases where we have to manipulate
    * the target object using some property from the source object.
    */
   private Map<String,String> objectIdMap = null;
   /*
    * This property holds the association between the host pnic and
    * vds to which the pnic needs to be migrated to.
    * For example, a list like [[vds_1, vds_2], [vds_2, vds_3]]
    * implies that on the first host, migrate the first free pnic to vds_1
    * and the second free pnic to vds_2. On the second host, migrate the
    * first free pnic to vds_2 and the second free pnic to vds_3
    */
   private List<List<String>> hostPnicVdsList = null;
   /*
    * This property holds the map between a target object and a list of
    * source objects. This can be used in cases where we need to
    * associate all target objects with the source object.For example,
    * we can associate a list of portgroup spec object ids to a
    * vds object id using this data structure.
    */
   private Map<String,List<String>> objectListIdMap = null;
   /*
    * Associate any object @ index i with the corresponding object id
    * in that index. For example, associate the second vnic of a vm
    * to object id "dvspec" => listIdMap[1] = "dvspec"
    */
   private List<String> listIdMap = null;

   /*
    * Getters and setters for the properties
    */

   /**
    * @param vdsPortgroupMap
    */
   public void setVdsPortgroupMap(Map<DVSConfigSpec,
                                  List<DVPortgroupConfigSpec>> vdsPortgroupMap)
   {
      this.vdsPortgroupMap = vdsPortgroupMap;
   }

   /**
    * @param ObjectIdKeyIndexMap
    *
    */
   public void setObjectIdMap(Map<String,String> objectIdMap)
   {
      this.objectIdMap = objectIdMap;
   }

   /**
    * @return Map<String,String>
    */
   public Map<String,String> getObjectIdMap()
   {
      return this.objectIdMap;
   }

   /**
    * @param hostPnicVdsList
    */
   public void setHostPnicVdsList(List<List<String>> hostPnicVdsList)
   {
      this.hostPnicVdsList = hostPnicVdsList;
   }

   /**
    *
    * @return List<List<String>>
    */
   public List<List<String>> getHostPnicVdsList()
   {
      return this.hostPnicVdsList;
   }

   /**
    * @return Map<DVSConfigSpec,List<DVPortgroupConfigSpec>
    */
   public Map<DVSConfigSpec,List<DVPortgroupConfigSpec>> getVdsPortgroupMap()
   {
      return this.vdsPortgroupMap;
   }

   /**
    * @param dvPortgroupConfigSpecSelection
    */
   public void setDvPortgroupConfigSpecSelection(
                                             List<List<DVPortgroupConfigSpec>>
                                             dvPortgroupConfigSpecSelection)
   {
      this.dvportgroupConfigSpecSelection = dvPortgroupConfigSpecSelection;
   }

   /**
    * @return List<List<DVPortgroupConfigSpec>>
    */
   public List<List<DVPortgroupConfigSpec>> getDvPortgroupSelectionSet()
   {
      if(this.dvportgroupConfigSpecSelection == null){
         return new ArrayList<List<DVPortgroupConfigSpec>>();
      }
      return this.dvportgroupConfigSpecSelection;
   }

   /**
    * @param portSelectionMap
    */
   public void setPortSelectionMap(Map<Object,List<Integer>> portSelectionMap)
   {
      this.portSelectionMap = portSelectionMap;
   }

   /**
    * @return Map<Object,List<Integer>>
    */
   public Map<Object,List<Integer>> getPortSelectionMap()
   {
      return this.portSelectionMap;
   }

   /**
    * @param hostVdsConfigSpec
    */
   public void setHostVdsConfigSpec(List<DVSConfigSpec> hostVdsConfigSpec)
   {
      this.hostVdsConfigSpec = hostVdsConfigSpec;
   }

   /**
    * @return List<DVSConfigSpec>
    */
   public List<DVSConfigSpec> getHostVdsConfigSpec()
   {
      return this.hostVdsConfigSpec;
   }

   /**
    * @param portKeysOutVds
    */
   public void setPortKeysOutVds(Boolean portKeysOutVds)
   {
      this.portKeysOutVds = portKeysOutVds;
   }

   /**
    * @return Boolean
    */
   public Boolean getPortKeysOutVds()
   {
      return this.portKeysOutVds;
   }

   /**
    * @param portgroupKeysOutVds
    */
   public void setPortgroupKeysOutVds(Boolean portgroupKeysOutVds)
   {
      this.portgroupKeysOutVds = portgroupKeysOutVds;
   }

   /**
    * @return Boolean
    */
   public Boolean getPortgroupKeysOutVds()
   {
      return this.portgroupKeysOutVds;
   }

   /**
    * @param hostMemberOutVds
    */
   public void setHostMemberOutVds(Boolean hostMemberOutVds)
   {
      this.hostMemberOutVds = hostMemberOutVds;
   }

   /**
    * @return Boolean
    */
   public Boolean getHostMemberOutVds()
   {
      return this.hostMemberOutVds;
   }

   /**
    *
    * @param objectListIdMap
    */
   public void setObjectListIdMap(Map<String,List<String>> objectListIdMap)
   {
      this.objectListIdMap = objectListIdMap;
   }

   /**
    *
    * @return Map<String,List<String>>
    */
   public Map<String,List<String>> getObjectListIdMap()
   {
      return this.objectListIdMap;
   }

   /**
    *
    * @param listIdMap
    */
   public void setListIdMap(List<String> listIdMap)
   {
      this.listIdMap = listIdMap;
   }

   /**
    *
    * @return List<String>
    */
   public List<String> getListIdMap()
   {
      return this.listIdMap;
   }
}
