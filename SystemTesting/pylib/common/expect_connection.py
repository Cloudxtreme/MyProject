import pexpect
import vmware.common.logger as logger
from vmware.common.global_config import pylogger
import subprocess
import tempfile
import os

class ExpectConnection:
    """ Class to create expect connection and request and get response
    for queries
    """
    NEXT_PAGE_PROMPT = 0
    EXPECT_PROMPT    = 1

    def __init__(self, ip, username, password):
        self.ip = ip
        self.username = username
        self.password = password
        self.pexpectconn = pexpect.spawn("ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no "+ self.username +"@"+ self.ip)
        pexpect_status = self.pexpectconn.expect([pexpect.TIMEOUT, 'password:'])
        if pexpect_status == 0:  #Timeout
            pylogger.error('ERROR! could not login with SSH using pexpect :')
            pylogger.error(self.pexpectconn.before, self.pexpectconn.after)
            pylogger.error(str(self.pexpectconn))
            return None

        if pexpect_status == 1:
            self.pexpectconn.sendline(self.password)
            """ Check for prompt > """
            self.pexpectconn.expect('.>')

    def request(self, method="", endpoint="", expect="", headers=""):
        """ Execute the command using the expect connection,

        @param Comply with parent method signature by returning response object as
        parent query() read() etc will use this request method
        @return cli response object which is stdout object obtained from expect() command
        """
        pylogger.info("executing command %s " % endpoint)
        pylogger.info("expecting prompt %s " % expect)
        return getattr(self, method)(expect,endpoint)


    def default_prompt(self, endpoint="", expect="",):
        self.pexpectconn.sendline(endpoint)
        self.pexpectconn.expect(expect)
        return self.pexpectconn.before


    def read_until_prompt(self, expect="", endpoint=""):
        """
        This function is use to read all the commandline output until the
        byte prompt(i.e byte *) is displayed, and will exit the prompt after
        the vshield edge prompt (i.e >) is displayed. The output is generated in
        a text file which is processed so as to removed the Enter/Space/ControlM
        characters from the output.

        @param expect="" expected prompt
        @param endpoint="" command to be executed

        @return returns the cli output
        """
        pexpect_outfile = tempfile.NamedTemporaryFile(suffix="_edge_cli_output", delete=False)
        pexpect_outfilename = pexpect_outfile.name
        pylogger.info("Pexpect Output Temporary File Name = %s" % pexpect_outfilename)

        processed_outfile = tempfile.NamedTemporaryFile(suffix="_processed_cli_output",delete=False)
        processed_outfilename = processed_outfile.name
        pylogger.info("Processed outfile Temporary File Name = %s" % processed_outfilename)

        self.pexpectconn.sendline(endpoint)
        expect_condition = self.pexpectconn.expect(expect)
        pylogger.info("Expect_Condition value = %d" %expect_condition)

        while expect_condition == self.NEXT_PAGE_PROMPT:
            pexpect_outfile.writelines(self.pexpectconn.before)
            self.pexpectconn.sendline('')
            expect_condition = self.pexpectconn.expect(expect)

        if expect_condition == self.EXPECT_PROMPT:
            pexpect_outfile.writelines(self.pexpectconn.before)

        pexpect_outfile.close()

        #sed file operation
        exit_code = subprocess.call(
            'cat -vT %s | sed "s/\^M//g"  | sed "s/\(^\^\[.*\[\[K\)\(.*\)/\\2/g" | sed "s/\(^\^.*[=]\)\(.*\)/\\2/g" | sed "s/^\^.*//g" | sed "s/\s\^H//g"> %s' % (
                pexpect_outfilename, processed_outfilename), shell=True)
        pylogger.info("Removing the pexpect_out file %s" % pexpect_outfilename)
        os.remove(pexpect_outfilename)

        if exit_code == 0:
          #read the file
          readfile_handle = open(processed_outfilename,"r")
          lines = readfile_handle.readlines()
          readfile_handle.close()
          lines = ''.join(lines)
          pylogger.info("File Contents = %s" % lines)
          pylogger.info("Removing the processed file %s" % processed_outfilename)
          os.remove(processed_outfilename)
          return lines
        else:
            return "FAILURE"


if __name__ == '__main__':
    e = ExpectConnection("10.112.243.47","admin","default")

    output = e.read_until_prompt(['bytes*', '>'], "show system network-stats")
    print "Myoutput = %s" % output