/* ************************************************************************
*
* Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
*
* ************************************************************************
*/
package com.vmware.vcqa.vim.dvs.testframework;

import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.BeansException;
import org.springframework.beans.factory.xml.XmlBeanFactory;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;

/**
 * This class is a wrapper over the spring framework to get the objects
 * from their ids as defined in the bean definition file.
 *
 * @author sabesanp
 *
 */
public class DataFactory {

   private XmlBeanFactory factory = null;

   /**
    * Constructor
    *
    * @param xmlFile
    *
    * @throws BeansException
    */
   public DataFactory(String xmlFile)
      throws BeansException
   {
      Resource res = new ClassPathResource(xmlFile);
      factory = new XmlBeanFactory(res);
   }

   /**
    * This method fetches the data objects passing the object ids
    *
    * @param objIdList
    *
    * @return List<Object>
    *
    * @throws BeansException
    */
   public List<Object> getData(List<String> objIdList)
      throws BeansException
   {
      List<Object> obj = new ArrayList<Object>();
      for(String id: objIdList){
         obj.add(factory.getBean(id));
      }
      return obj;
   }

   /**
    * This method fetches the data object when given the object id
    *
    * @param objId
    *
    * @return Object
    *
    * @throws BeansException
    */
   public Object getData(String objId)
      throws BeansException
   {
      return factory.getBean(objId);
   }
}
