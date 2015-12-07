/* ************************************************************************
*
* Copyright 2013 VMware, Inc.  All rights reserved. -- VMware Confidential
*
* ************************************************************************
*/
package com.vmware.vcqa;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Set;
import java.util.TimeZone;
import java.util.concurrent.TimeUnit;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBElement;
import javax.xml.bind.JAXBException;
import javax.xml.namespace.QName;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.soap.SOAPException;
import javax.xml.soap.SOAPHeader;
import javax.xml.ws.handler.MessageContext;
import javax.xml.ws.handler.soap.SOAPHandler;
import javax.xml.ws.handler.soap.SOAPMessageContext;

import org.oasis_open.docs.wss._2004._01.oasis_200401_wss_wssecurity_secext_1_0.ObjectFactory;
import org.oasis_open.docs.wss._2004._01.oasis_200401_wss_wssecurity_secext_1_0.SecurityHeaderType;
import org.oasis_open.docs.wss._2004._01.oasis_200401_wss_wssecurity_utility_1_0.AttributedDateTime;
import org.oasis_open.docs.wss._2004._01.oasis_200401_wss_wssecurity_utility_1_0.TimestampType;
import org.w3c.dom.DOMException;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/**
 * Handler class to add the TimeStamp element to the security header
 */
public class TimeStampHandler implements SOAPHandler<SOAPMessageContext>
{
   public static final String SECURITY_ELEMENT_NAME = "Security";
   public static final String WS_1_3_TRUST_JAXB_PACKAGE = "org.oasis_open.docs.ws_sx.ws_trust._200512";
   public static final String WSS_NS = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd";
   public static final String ERR_INSERTING_SECURITY_HEADER = "Error inserting Security header into the SOAP message. Too many Security found.";
   public static final String WSSE_JAXB_PACKAGE = "org.oasis_open.docs.wss._2004._01.oasis_200401_wss_wssecurity_secext_1_0";
   public static final String WSSU_JAXB_PACKAGE = "org.oasis_open.docs.wss._2004._01.oasis_200401_wss_wssecurity_utility_1_0";
   public static final String MARSHALL_EXCEPTION_ERR_MSG = "Error marshalling JAXB document";
   public static final String PARSING_XML_ERROR_MSG = "Error while parsing the SOAP request (signature creation)";

   private static final String GMT = "GMT";
   public static final String XML_DATE_FORMAT = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
   public static final int REQUEST_VALIDITY_IN_MINUTES = 10;

   /**
    * Creates a datetime formatter needed for populating objects containing XML
    * requests/responses.
    */
   public static DateFormat createDateFormatter()
   {
      DateFormat dateFormat = new SimpleDateFormat(XML_DATE_FORMAT);
      dateFormat.setTimeZone(TimeZone.getTimeZone(TimeStampHandler.GMT));
      return dateFormat;
   }

   /**
    * Creates a timestamp WS-Security element. It is needed for the STS to tell
    * if the request is invalid due to slow delivery
    * 
    * @return timestamp element issued with start date = NOW and expiration date
    *         = NOW + REQUEST_VALIDITY_IN_MINUTES
    */
   private JAXBElement<TimestampType> createTimestamp()
   {
      org.oasis_open.docs.wss._2004._01.oasis_200401_wss_wssecurity_utility_1_0.ObjectFactory wssuObjFactory = new org.oasis_open.docs.wss._2004._01.oasis_200401_wss_wssecurity_utility_1_0.ObjectFactory();

      TimestampType timestamp = wssuObjFactory.createTimestampType();

      final long now = System.currentTimeMillis();
      Date createDate = new Date(now);
      Date expirationDate = new Date(now
               + TimeUnit.MINUTES.toMillis(REQUEST_VALIDITY_IN_MINUTES));

      DateFormat wssDateFormat = createDateFormatter();
      AttributedDateTime createTime = wssuObjFactory.createAttributedDateTime();
      createTime.setValue(wssDateFormat.format(createDate));

      AttributedDateTime expirationTime = wssuObjFactory.createAttributedDateTime();
      expirationTime.setValue(wssDateFormat.format(expirationDate));

      timestamp.setCreated(createTime);
      timestamp.setExpires(expirationTime);
      return wssuObjFactory.createTimestamp(timestamp);
   }

   @Override
   public boolean handleMessage(SOAPMessageContext smc)
   {
      boolean isOutBound = (Boolean) smc.get(MessageContext.MESSAGE_OUTBOUND_PROPERTY);
      if (isOutBound) {
         try {
            SOAPHeader soapHeader = smc.getMessage().getSOAPPart().getEnvelope().getHeader() == null ? smc.getMessage().getSOAPPart().getEnvelope().addHeader()
                     : smc.getMessage().getSOAPPart().getEnvelope().getHeader();
            Node securityNode = getSecurityElement(soapHeader);
            Node timeStampNode = marshallJaxbElement(createTimestamp()).getDocumentElement();
            securityNode.appendChild(securityNode.getOwnerDocument().importNode(
                     timeStampNode, true));
         } catch (DOMException e) {
            throw new RuntimeException(e);
         } catch (SOAPException e) {
            throw new RuntimeException(e);
         }
      }
      return true;
   }

   /**
    * Finds the Security element from the header. If not found then creates one
    * and returns the same
    * 
    * @param header
    * @return
    */
   public static Node getSecurityElement(SOAPHeader header)
   {
      final ObjectFactory wsseObjFactory = new ObjectFactory();
      NodeList targetElement = header.getElementsByTagNameNS(WSS_NS,
               SECURITY_ELEMENT_NAME);
      if (targetElement == null || targetElement.getLength() == 0) {
         JAXBElement<SecurityHeaderType> value = wsseObjFactory.createSecurity(wsseObjFactory.createSecurityHeaderType());
         Node headerNode = marshallJaxbElement(value).getDocumentElement();
         return header.appendChild(header.getOwnerDocument().importNode(
                  headerNode, true));
      } else if (targetElement.getLength() > 1) {
         throw new RuntimeException(ERR_INSERTING_SECURITY_HEADER);
      }
      return targetElement.item(0);
   }

   /**
    * Marshall a jaxbElement into a Document
    * 
    * @param jaxbElement
    * @return Document
    * @throws Exception
    */
   public static final <T> Document marshallJaxbElement(JAXBElement<T> jaxbElement)
   {
      DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
      dbf.setNamespaceAware(true);
      Document result = null;
      try {
         JAXBContext jaxbContext = JAXBContext.newInstance(WS_1_3_TRUST_JAXB_PACKAGE
                  + ":" + WSSE_JAXB_PACKAGE + ":" + WSSU_JAXB_PACKAGE);
         result = dbf.newDocumentBuilder().newDocument();
         jaxbContext.createMarshaller().marshal(jaxbElement, result);
      } catch (JAXBException jaxbException) {
         throw new RuntimeException(MARSHALL_EXCEPTION_ERR_MSG, jaxbException);
      } catch (ParserConfigurationException pce) {
         throw new RuntimeException(MARSHALL_EXCEPTION_ERR_MSG, pce);
      }

      return result;
   }

   @Override
   public Set<QName> getHeaders()
   {
      // TODO Auto-generated method stub
      return null;
   }

   @Override
   public void close(MessageContext arg0)
   {
      // TODO Auto-generated method stub

   }

   @Override
   public boolean handleFault(SOAPMessageContext arg0)
   {
      // TODO Auto-generated method stub
      return false;
   }
}