import vsm_client
import vmware.common.logger as logger
from vsm import VSM


class Certificate(vsm_client.VSMClient):
    def __init__(self, vsm=None):
        """ Constructor to create IPSet object

        @param vsm object on which IPSet has to be configured
        """
        super(Certificate, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'certificates_schema.CertificatesSchema'
        self.set_connection(vsm.get_connection())
        conn = self.get_connection()
        conn.set_api_header("api/1.0")
        self.set_read_endpoint(
            "appliance-management/certificatemanager/certificates/nsx")
        self.id = None
        self.update_as_post = False

    def get_thumbprint_sha1(self):
        schema_object = self.read()
        thumbprint = schema_object.list[0].sha1Hash
        return thumbprint

if __name__ == '__main__':
    import base_client
    var = """
    <?xml version="1.0" encoding="UTF-8"?>
    <x509Certificates>
     <x509certificate>
       <subjectCn>vsm_6.2_ashutosh</subjectCn>
       <issuerCn>vsm_6.2_ashutosh</issuerCn>
       <version>3</version>
       <serialNumber>5fa39c40</serialNumber>
       <signatureAlgo>SHA256WITHRSA</signatureAlgo>
       <signature>0a d0 92 c3 a8 96 2c 17 42 ca 83 fc 61 84 1b f0 c2 44 6f d8 ae d8 33 03 bd ab f2 f5 82 30 d3 a9 71 bb 8e 1c 30 9c 55 28 22 64 c0 de aa d1 32 91 22 ff 2c 4e fe f3 ed ab 0e 5e 2c 0a e7 55 4c 7b 23 6c 6c fd c0 58 68 40 ad 13 61 03 b7 ef fc 1a 54 8c ac 1f 0b 4b 40 18 d1 ae 55 25 2c 11 87 51 08 7d fc 82 a1 86 83 fa a0 47 7d ac f0 27 ae 14 3b eb 32 61 78 56 74 b0 8b e0 2e a9 23 97 5e 0d 22 a2 37 89 c5 47 06 b3 b8 0d 1c 3c e0 fd 06 ba 7c dd eb 9a 43 63 f1 af 5a 61 34 df 61 0b 51 62 85 bc e2 bc f6 78 3b 6b ed 24 95 5a 7b e2 1a 3b a6 5c a7 38 8f b5 33 c4 f4 3b d5 ab b2 b4 60 d2 bb 9a 4f 1d 25 95 66 d3 d6 51 1e f0 e7 cf 7a a5 5e 67 60 c5 5d fb f3 cb 5e 1d c8 61 fc b4 29 c4 c9 4e 35 29 7f f7 f5 77 a1 55 22 1e c6 fd 77 d2 1e 8f 26 d5 e0 b7 bb 44 a0 9f 43 b3 ba b0 77 70</signature>
       <notBefore>1421930843000</notBefore>
       <notAfter>1737290843000</notAfter>
       <issuer>CN=vsm_6.2_ashutosh,OU=NSX,O=VMware Inc.,L=Palo Alto,ST=CA,C=US</issuer>
       <subject>CN=vsm_6.2_ashutosh,OU=NSX,O=VMware Inc.,L=Palo Alto,ST=CA,C=US</subject>
       <publicKeyAlgo>RSA</publicKeyAlgo>
       <publicKeyLength>2048</publicKeyLength>
       <rsaPublicKeyModulus>00 98 90 d7 3e 67 04 94 6a b9 0d 1b cc b2 e7 a8 17 e2 b9 5d 6c ed 73 98 9d 42 5f 93 66 d5 c0 7d d8 07 33 0c bb 73 f7 5b 53 a6 b0 ba 47 d1 f9 eb 5a 0d f6 d3 8d 00 59 12 74 89 8e c5 04 d4 25 b3 56 cb 72 49 f5 85 75 37 62 7b 68 6f 41 c7 f6 10 1d 55 04 0f 78 45 c5 cc e8 18 e5 b2 69 10 fa 93 3f 32 d7 e0 19 0f 74 00 83 8d 01 87 3c bb 15 f7 34 06 da a4 0b 06 a1 e2 f9 30 bd 79 ab eb 1e b6 0b e9 d5 d9 5c 76 e5 00 9b 0a b6 84 93 5a e1 75 f6 fd b4 00 91 3a fd bc 06 d6 20 d1 90 08 a9 02 81 77 18 45 b9 be 16 52 6e d3 79 98 f4 a3 6f 62 ab 2f a9 fc 7f 01 d0 1f 83 92 af 3e af a3 a8 80 7b 04 0b 3b 26 68 23 77 fc 17 d4 9c d1 7c cc c3 ec 1e bf aa 47 f3 d9 f2 59 d5 e1 81 67 59 83 69 12 e2 da 38 f4 59 b9 3d cd 78 aa 2d 73 e1 28 b8 82 58 a3 f0 87 52 ec 48 b4 63 f4 ea 85 5d a6 a0 e1</rsaPublicKeyModulus>
       <rsaPublicKeyExponent>10001</rsaPublicKeyExponent>
       <sha1Hash>0f:5e:d7:d4:da:e4:b3:ac:fa:1f:fa:1c:11:cb:fc:49:8e:a5:5f:40</sha1Hash>
       <md5Hash>d4:a9:f4:c1:04:dc:ac:98:34:56:c6:8e:60:7c:81:93</md5Hash>
       <isCa>false</isCa>
       <isValid>true</isValid>
     </x509certificate>
    </x509Certificates>
    """
    log = logger.setup_logging('IPSet-Test')
    vsm_obj = VSM("10.112.11.38", "admin", "default", "")
    certificate_client = Certificate(vsm_obj)
    result_object = certificate_client.read()

    print result_object.list[0].sha1Hash

