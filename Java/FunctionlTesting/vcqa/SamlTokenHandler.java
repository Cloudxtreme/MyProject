/* ************************************************************************
*
* Copyright 2013 VMware, Inc.  All rights reserved. -- VMware Confidential
*
* ************************************************************************
*/

package com.vmware.vcqa;

import java.util.Set;

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
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.w3c.dom.DOMException;
import org.w3c.dom.Document;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

/**
 * Handler class to add the SAML token to the security header
 */
public class SamlTokenHandler implements SOAPHandler<SOAPMessageContext>
{
   private static Logger log = LoggerFactory.getLogger(SamlTokenHandler.class);
   public static final String SECURITY_ELEMENT_NAME = "Security";
   public static final String WS_1_3_TRUST_JAXB_PACKAGE = "org.oasis_open.docs.ws_sx.ws_trust._200512";
   public static final String WSS_NS = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd";
   public static final String ERR_INSERTING_SECURITY_HEADER = "Error inserting Security header into the SOAP message. Too many Security found.";
   public static final String WSSE_JAXB_PACKAGE = "org.oasis_open.docs.wss._2004._01.oasis_200401_wss_wssecurity_secext_1_0";
   public static final String WSSU_JAXB_PACKAGE = "org.oasis_open.docs.wss._2004._01.oasis_200401_wss_wssecurity_utility_1_0";
   public static final String MARSHALL_EXCEPTION_ERR_MSG = "Error marshalling JAXB document";
   public static final String PARSING_XML_ERROR_MSG = "Error while parsing the SOAP request (signature creation)";

   private static Node token;

   public static Node getToken()
   {
      return token;
   }

   public static void setToken(Node token)
   {
      SamlTokenHandler.token = token;
   }

   public SamlTokenHandler()
   {

   }

   @Override
   public boolean handleMessage(SOAPMessageContext smc)
   {
      boolean isOutBound = (Boolean) smc.get(MessageContext.MESSAGE_OUTBOUND_PROPERTY);
      if (isOutBound) {
         try {
            log.debug("Entered handler class");
            SOAPHeader soapHeader = smc.getMessage().getSOAPPart().getEnvelope().getHeader() == null ? smc.getMessage().getSOAPPart().getEnvelope().addHeader()
                     : smc.getMessage().getSOAPPart().getEnvelope().getHeader();
            Node securityNode = getSecurityElement(soapHeader);
            securityNode.appendChild(securityNode.getOwnerDocument().importNode(
                     token, true));
            log.debug("Exiting handler class");
         } catch (DOMException e) {
            throw new RuntimeException(e);
         } catch (SOAPException e) {
            throw new RuntimeException(e);
         }
      } else {

      }
      // Utils.printMessage(smc);
      return true;

   }

   @Override
   public Set<QName> getHeaders()
   {
      // TODO Auto-generated method stub
      return null;
   }

   @Override
   public void close(MessageContext context)
   {
      // TODO Auto-generated method stub

   }

   @Override
   public boolean handleFault(SOAPMessageContext context)
   {
      // TODO Auto-generated method stub
      return false;
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
}