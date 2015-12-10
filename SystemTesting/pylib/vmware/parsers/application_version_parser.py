class ApplicationVersionParser:

    def get_parsed_data(self, command_response, application_name):
        data = []
        data = self.sanity_check(command_response)
        parsing_options = {"autoconf": self.autoconf_parser,
                           "bison": self.bison_parser,
                           "erlang": self.erlang_parser,
                           "gcc": self.gcc_parser,
                           "java": self.java_parser,
                           "perl": self.perl_parser,
                           "python": self.python_parser,
                           "libtool": self.libtool_parser,
                           "kernel": self.kernel_parser,
                           "vim": self.vim_parser,
                           "rsyslogd": self.rsyslogd_parser,
                           "rabbitmq": self.rabbitmq_parser}
        pydict = dict()
        if not data:
            pydict.update({'tag': "Informative Error:"})
            pydict.update({'version': "Command returned either ERROR, "
                                      "NOT FOUND or no output"})
            return pydict

        pydict = parsing_options[application_name](data)
        return pydict

    def sanity_check(self, command_response):
        data = []
        lines = command_response.strip().split("\n")
        if ((len(lines) > 0) and ((lines[0].upper().find("ERROR") > 0) or
                                  (lines[0].upper().find("NOT FOUND") > 0) or
                                  (len(lines) == 1
                                   and lines[0].strip() == ""))):
            return data
        for line in lines:
            if (line.strip() != ""):
                data.append(line.strip())

        return data

    def autoconf_parser(self, data):
        data = data[:-6]
        for line in data:
            pydict = dict()
            (key, value) = line.split('(GNU Autoconf)')
            pydict.update({'tag': key.strip()})
            pydict.update({'version': value.strip()})

        return pydict

    def bison_parser(self, data):
        data = data[:-5]
        for line in data:
            pydict = dict()
            (key, value) = line.split('(GNU Bison)')
            pydict.update({'tag': key.strip()})
            pydict.update({'version': value.strip()})

        return pydict

    def gcc_parser(self, data):
        data = data[:-4]
        for line in data:
            pydict = dict()
            (key, value) = line.split('(GCC)')
            pydict.update({'tag': key.strip()})
            pydict.update({'version': value.strip()})

        return pydict

    def java_parser(self, data):
        data = data[:-3]
        for line in data:
            pydict = dict()
            (key, value) = line.split(' version ')
            pydict.update({'tag': key.strip()})
            pydict.update({'version': value.strip('"')})

        return pydict

    def python_parser(self, data):
        data = data[:-1]
        for line in data:
            pydict = dict()
            (key, value) = line.split(' ')
            pydict.update({'tag': key.strip()})
            pydict.update({'version': value.strip('"')})

        return pydict

    def libtool_parser(self, data):
        data = data[:-5]
        for line in data:
            pydict = dict()
            (key, value) = line.split('(GNU libtool)')
            pydict.update({'tag': key.strip()})
            pydict.update({'version': value.strip()})

        return pydict

    def kernel_parser(self, data):
        for line in data:
            pydict = dict()
            key = line.split()[0]
            value = line.split()[2]
            pydict.update({'tag': key.strip()})
            pydict.update({'version': value.strip()})

        return pydict

    def vim_parser(self, data):
        data = data[:-26]
        for line in data:
            pydict = dict()
            key = line.split()[0]
            value = line.split()[4]
            pydict.update({'tag': key.strip()})
            pydict.update({'version': value.strip()})

        return pydict

    def rsyslogd_parser(self, data):
        data = data[:-10]
        for line in data:
            pydict = dict()
            (key, value) = line.split(',')[0].split()
            pydict.update({'tag': key.strip()})
            pydict.update({'version': value.strip()})

        return pydict

    def erlang_parser(self, data):
        data = data[:-5]
        for line in data:
            pydict = dict()
            key = line.split()[1]
            value = line.split()[3][14:21]
            pydict.update({'tag': key.strip()})
            pydict.update({'version': value.strip()})

        return pydict

    def rabbitmq_parser(self, data):
        data = data[2:][:-3]
        for line in data:
            pydict = dict()
            key = line.split(',')[1].strip('"')
            value = line.split(',')[2][1:6]
            pydict.update({'tag': key.strip()})
            pydict.update({'version': value.strip()})

        return pydict

    def perl_parser(self, data):
        data = data[:-7]
        for line in data:
            pydict = dict()
            key = line.split()[2]
            value = line.split()[8][2:8]
            pydict.update({'tag': key.strip()})
            pydict.update({'version': value.strip()})

        return pydict
