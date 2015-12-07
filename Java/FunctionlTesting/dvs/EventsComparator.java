/* ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs;

import java.util.Calendar;
import java.util.Comparator;

import com.vmware.vc.Event;

/*
 *  This class  implements the java.util.Comparator interface's compare method
 */
public class EventsComparator implements Comparator
{
   /**
    * This Method compares its two arguments for order
    * 
    * @param ev1 the first object to be compared
    * @param ev2 the second object to be compared.
    * @return int returns zero if ev1 and ev2 are equal, a negative integer if
    *         ev1 before ev2, and a positive integer if ev1 after ev2
    */
   public int compare(Object ev1,
                      Object ev2)
   {
      int result;
      Calendar c1 = (Calendar) ((Event) ev1).getCreatedTime();
      Calendar c2 = (Calendar) ((Event) ev2).getCreatedTime();
      if (c1.before(c2)) {
         result = -1;
      } else if (c1.after(c2)) {
         result = 1;
      } else {
         result = 0;
      }
      return result;
   }
}
