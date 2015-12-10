package com.vmware.vcqa;

import java.io.File;
import java.io.FileOutputStream;
import java.io.PrintStream;
import java.lang.reflect.Array;
import java.lang.reflect.Method;
import java.net.URL;
import java.text.SimpleDateFormat;
import java.util.Collection;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;

import javax.xml.datatype.XMLGregorianCalendar;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.ITestContext;
import org.testng.ITestNGMethod;
import org.w3c.dom.Element;

import com.vmware.vc.DynamicProperty;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.util.TestUtil;

/**
 * LogUtil manages the logger objects of multiple threads and methods to get and
 * set them.
 */
public class LogUtil {
   private static final Logger log = LoggerFactory.getLogger(LogUtil.class);

   public synchronized static void logToSummary(String testcaseName,
         Date endTime, Date startTime, String outcome) {
      PrintStream printStream = null;
      try {
         log.info("Writing Results to Summary for  TestCase :" + testcaseName);
         String logDirectory = System.getProperty("LOG_DIR");
         if (logDirectory != null) {
            String logFile =
                  new StringBuffer(logDirectory).append(File.separator)
                        .append("summary.log").toString();
            printStream =
                  new PrintStream(
                        new FileOutputStream(new File(logFile), true), true);
            SimpleDateFormat format =
                  new SimpleDateFormat("yyyy-MM-dd-HH-mm-ss");
            printStream.println();
            printStream.println("TestCase           :" + testcaseName);
            printStream.println("Start Time                 :"
                  + format.format(startTime));
            printStream
                  .println("End Time           :" + format.format(endTime));
            printStream.println("Duration           :"
                  + (endTime.getTime() - startTime.getTime())
                  / (1000 * 60 * 60) + " Minutes");
            printStream.println("Test Status                :" + outcome);
            String runlistName = System.getProperty("GROUP_NAME");
            printStream
                  .println(new StringBuffer("RESULT:  0   ")
                        .append(
                              testcaseName.substring(0,
                                    testcaseName.lastIndexOf(".")))
                        .append("::Positive::")
                        .append(
                              testcaseName.substring(
                                    testcaseName.lastIndexOf(".") + 1,
                                    testcaseName.length())).append("     ")
                        .append(outcome).append("     ").append(runlistName)
                        .toString());
            printStream.flush();
         }
      } catch (Exception e) {
         log.error(
               "Unable to write the summary , Emails will not have this data",
               e);
      } finally {
         if (printStream != null) {
            printStream.close();
         }
      }
   }

   /**
    * Overloaded version of printDetailedObject(Object obj, String prefixSpace)
    * with null for the prefixSpace.
    *
    * @throws Exception
    */
   public static void printDetailedObject(Object obj)
                                                             throws Exception
   {
         printDetailedObject(obj, null);
   }

   /**
    * Print all public members with no arguments in detail(deep) for an object.
    * If the data is not printable, then recursivel call is made to print the
    * members of the object in detail. If the data is an array, then it will
    * iterated and printed in detailed. Example output: INFO : Object =
    * com.vmware.vc.VirtualMachineConfigSpec INFO : Name = testvm INFO : GuestId
    * = winxppro INFO : Files : INFO : CfgPathName = [shared] INFO :
    * MigrateLogPathName = null INFO : LogPathName = null INFO : Tools = null
    * INFO : Flags = null INFO : NumCpus = null INFO : MemoryMB = 128 INFO :
    * DeviceChange is array INFO : DeviceChange array index 0 INFO : Operation =
    * null INFO : Device = null
    *
    * @param obj
    *           Object members to be printed
    * @param prefixSpace
    *           Space used for prefix
    * @throws Exception
    */
   public static void printDetailedObject(Object obj,
                                          String prefixSpace)
                                                             throws Exception
   {
      if (prefixSpace == null) {
         prefixSpace = "";
      }
      String format =  prefixSpace.isEmpty() ? "{}{}" : "{} = {}";
      if (obj == null) {
         log.info(format, prefixSpace, obj);
         return;
      }

      if (isPrintable(obj)) {
         /*
          * If data is date/calendar, then print the calendar with
          * date format
          */
         if (obj instanceof GregorianCalendar) {
            obj = TestConstants.DATE_FORMAT
                     .format(((GregorianCalendar) obj).getTime());
         } else if (obj instanceof XMLGregorianCalendar) {
            obj = TestConstants.DATE_FORMAT.format(((XMLGregorianCalendar) obj)
                     .toGregorianCalendar().getTime());
         }
         log.info(format, prefixSpace, obj);
      } else if (obj.getClass().isArray()) {
         for (int j = 0; j < Array.getLength(obj); j++) {
            Object arrayData = Array.get(obj, j);
            printDetailedObject(arrayData, prefixSpace + "[" + j + "]");
         }
      } else if (Collection.class.isInstance(obj)) {
         Collection c = (Collection) obj;
         Iterator it = c.iterator();
         log.info(prefixSpace + " Collection {}  size: {}", c, c.size());
         int j = 0;
         while (it.hasNext()) {
            Object object = it.next();
            printDetailedObject(object, prefixSpace + "(" + j + ")");
            j++;
         }
      } else {
         Class<? extends Object> objClass = obj.getClass();
         Method[] method = objClass.getMethods();
         for (int i = 0; i < method.length; i++) {
            String methodName = method[i].getName();
            Class<? extends Object>[] args = method[i].getParameterTypes();
            /*
             * Check for public get methods with args zero
             */
            if ((methodName.indexOf(TestConstants.MODIFIER_PUBLIC_GET) == 0)
                     && (args.length == 0)) {
               methodName = methodName.substring(
                        TestConstants.MODIFIER_PUBLIC_GET.length(),
                        methodName.length());
               /*
                * Skip the axis autogenerate get methods
                */
               if (!methodName.equalsIgnoreCase("TypeDesc")
                        && !methodName.equalsIgnoreCase("Class")) {
                  /*
                   * Call the get method to get actual data
                   */
                  Object data = method[i].invoke(obj, (Object[]) null);
                  // printDetailedObject recursively.
                  printDetailedObject(data, prefixSpace + " " + methodName);
               }
            } else if ((methodName.indexOf(TestConstants.MODIFIER_PUBLIC_IS) == 0)
                     && (args.length == 0)
                     && method[i].getReturnType().getSimpleName()
                              .equalsIgnoreCase("Boolean")) {
               /*
                * for all the isXXX functions that return boolean values
                */
               Object data = method[i].invoke(obj, (Object[]) null);
               log.info(prefixSpace + " " + methodName + " :" + data);
            }
         }
      }
   }

   /**
    * Check the object for printable or not
    *
    * @param object
    *           Object to be checked
    * @return true, if printable false, if not
    */
   private static boolean isPrintable(Object object) {
      boolean printable = false;
      if ((object != null)
            && (object.getClass().isPrimitive()
                  || (object instanceof GregorianCalendar)
                  || (object instanceof XMLGregorianCalendar)
                  || (object instanceof String) || (object instanceof Element)
                  || (object instanceof URL) || object.getClass().isEnum())) {
         printable = true;
      }
      return printable;
   }

   /**
    * Print all the public members(get methods) with no arguments in an object
    *
    * @param obj
    *           Object public members to be printed
    * @throws Exception
    */
   public static void printObject(Object obj) throws Exception {
      printDetailedObject(obj, null);
   }

   /**
    * Print the final outcome to the Standard Output
    */
   public static void printOutcome(ResultsEnum outcome) {
      log.info("OUTCOME:" + outcome);
   }

   /**
    * Method to print MethodFault.
    *
    * @param fault
    *           MethodFault object to be printed.
    */
   public static void printMethodFault(final MethodFault fault,
         final String info) {
      log.info(info);
      log.info("Class        = " + fault.getClass());
      log.info("FaultCause  = " + fault.getFaultCause());
      log.info("FaultMessage   = "
            + com.vmware.vcqa.util.TestUtil.vectorToArray(
                  fault.getFaultMessage(),
                  com.vmware.vc.LocalizableMessage.class));
      /*
       * TODO: Check if these are needed and if so find appropriate
       * changes as axis2 and vc5x doesnt have these under methodfault
       */
      // log.info("FaultString  = " + fault.getFaultString());
      // log.info("FaultActor   = " + fault.getFaultActor());
      // log.info("FaultCode    = " + fault.getFaultCode());
      /* Retrieve method names for MethodFault class */
      try {
         List<String> methodFaultMethodNames =
               TestUtil.arrayToVector(TestUtil
                     .findMethods(new MethodFault(), true, false, false)
                     .keySet().toArray(new String[0]));
         /* Retrieve methods of given fault */
         HashMap<String, Method> methods =
               TestUtil.findMethods(fault, true, false, false);
         String[] methodNames = methods.keySet().toArray(new String[0]);
         for (int i = 0; i < methodNames.length; i++) {
            /*
             * Invoke and print methods in actualFault not listed in MethodFault
             * Required methodfault methods are printed above
             */
            if (!methodFaultMethodNames.contains(methodNames[i])) {
               String methodName = methodNames[i];
               Method method = methods.get(methodName);
               Object value = method.invoke(fault, (Object[]) null);
               log.info(methodName + "\t = " + value);
            }
         }
         log.info("");
      } catch (Exception e) {
         log.error("Exception occurred in checkMethodFault:" + e.getMessage(),
               e);
      }
   }

   /**
    * Prints information regarding the next test going to be executed. Invoked
    * from within methods annotated with \@BeforeMethod tags
    *
    * @param testContext
    *           - TestNG test context
    * @param m
    *           - test method
    * @throws Exception
    *            -
    */
   public static void printTestInfo(ITestContext testContext, Method m)
         throws Exception {
      for (ITestNGMethod method : testContext.getAllTestMethods()) {
         String methodClass = method.getRealClass().getSimpleName();
         if (methodClass.equals(m.getDeclaringClass().getSimpleName())
               && method.getMethodName().equals(m.getName())) {
            synchronized (LogUtil.class) {
               log.info("<TESTID>" + methodClass + "." + method.getMethodName()
                     + "</TESTID>");
               log.info("<TESTDESCRIPTION>" + method.getDescription()
                     + "</TESTDESCRIPTION>");
            }
            break;
         }
      }
   }
}
