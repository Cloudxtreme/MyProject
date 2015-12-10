/* ************************************************************************
*
* Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
*
* ************************************************************************
*/
package com.vmware.vcqa.vim.dvs.testframework;

import java.util.List;

/**
 * This class is an abstraction of a step. A step is the smallest possible
 * operation unit that can be specified in a data file.
 *
 * @author sabesanp
 *
 */
public class Step
{
   private String name = null;
   private List<String> data = null;
   private String testFrameworkName = null;
   private String groupName = null;
   private boolean executed = false;

   /*
    * Getters and setters for the properties
    */

   /**
    * @param name
    */
   public void setName(String name)
   {
      this.name = name;
   }

   /**
    * @param data
    */
   public void setData(List<String> data)
   {
      this.data = data;
   }

   /**
    * @param testFrameworkName
    */
   public void setTestFramework(String testFrameworkName)
   {
      this.testFrameworkName = testFrameworkName;
   }

   /**
    * @param groupName
    */
   public void setGroupName(String groupName)
   {
      this.groupName = groupName;
   }

   /**
    * @return String
    */
   public String getName()
   {
      return this.name;
   }

   /**
    * @return String
    */
   public String getTestFrameworkName()
   {
      return this.testFrameworkName;
   }

   /**
    * @return List<String>
    */
   public List<String> getData()
   {
      return this.data;
   }

   /**
    * @return String
    */
   public String getGroupName()
   {
      return this.groupName;
   }

   /**
    * @return boolean
    */
   public boolean getExecuted()
   {
      return this.executed;
   }

   /**
    * @param executed
    */
   public void setExecuted(boolean executed)
   {
      this.executed = executed;
   }
}
