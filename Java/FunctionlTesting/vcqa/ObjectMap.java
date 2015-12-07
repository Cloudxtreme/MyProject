/**
 * 
 */
package com.vmware.vcqa;

import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import com.vmware.vcqa.TestConstants.objectType;

/**
 * @author anoopjain
 * 
 */
public class ObjectMap
{
   // Repository for objects to be cleaned
   // Key of HashMap : Type of object
   // Value of HashMap : List of objects of given type.
   private Map<objectType, List<Object>> objectMap = new LinkedHashMap<objectType, List<Object>>();
   
   /**
    * Returns the object types
    * 
    * @return
    */

   public Set<objectType> getKeys()
   {
      return objectMap.keySet();
   }
   
   /**
    * Returns the objects of given object types
    * 
    * @return
    */

   public List<Object> get(objectType type)
   {
      return objectMap.get(type);
   }

   /**
    * Adds the objects to map
    * 
    * @param objecType Type of objects
    * @param object Listof objects or Single object
    * @return
    */

   public void add(objectType type,
                   Object object)
   {
      List<Object> objectList = new ArrayList<Object>();

      // If the list is given then add all the elements from given list
      // else add single object.
      if (object instanceof List)
         objectList.addAll((Collection<? extends Object>) object);
      else
         objectList.add(object);

      // If hashmap already contains the similar objects then add then to
      // existing list
      // otherwise create a new list.
      if (objectMap.containsKey(type)) {
         objectMap.get(type).addAll(objectList);
      } else {
         objectMap.put(type, objectList);
      }
   }

   /**
    * Removes the key from map
    * 
    * @param objecType Type of objects
    * @return
    */

   public void delete(objectType type)
   {
      objectMap.remove(type);
   }

   /**
    * Removes the objects from map
    * 
    * @param objecType Type of objects
    * @return
    */

   public void delete(objectType type,
                      Object object)
   {
      List<Object> objectList = new ArrayList<Object>();

      // If the list is given then add all the elements from given list
      // else add single object.
      if (object instanceof List)
         objectList.addAll((Collection<? extends Object>) object);
      else
         objectList.add(object);

      objectMap.get(type).removeAll(objectList);

      if (objectMap.get(type).size() == 0)
         delete(type);
   }
}
