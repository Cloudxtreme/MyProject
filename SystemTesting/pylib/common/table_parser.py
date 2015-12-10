import HTMLParser
import logging

LOG_FORMAT = '%(asctime)s %(levelname)-8s %(message)s'

logging.basicConfig(level=logging.DEBUG,
                    format=LOG_FORMAT,
                    datefmt='%a, %d %b %Y %H:%M:%S')

class TableParser(HTMLParser.HTMLParser):
    '''Class to parse any table in html data and
       return table contents in a dictionary
    '''
    def __init__(self):
        HTMLParser.HTMLParser.__init__(self)
        self.table_id = ''
        self.in_table = False
        self.new_row = False
        self.in_td = False
        self.in_th = False
        self.att_no = 0
        self.row_key = ''
        self.table_data = {}
        self.headings = []

    def handle_starttag(self, tag, attrs):
        '''Method is called when an html tag starts.
           eg <tr>....
           Param          Type         Description
           tag            String       html tag
           attrs          String       Attributes associated with the tag
        '''
        if tag == 'table':
            if ('id', self.table_id) in attrs:
                self.in_table = True

        if self.in_table and tag == 'tr':
            self.att_no = 0
            self.new_row =True

        if self.new_row and tag == 'td':
            self.in_td = True
        if self.new_row and tag == 'th':
            self.in_th = True

    def handle_data(self, data):
        '''Method is called when value between html tags is read.
           Param          Type         Description
           data           String       value between the html tags
        '''
        if  self.in_th:
            data = data.strip().strip('\n')
            self.headings.append(data)

        if self.new_row and self.in_td:

            try:
                if self.att_no == 0:
                    self.row_key = data
                    self.table_data[self.row_key] = {}
                else:
                    self.table_data[self.row_key][self.headings[self.att_no]] = data
            except IndexError, ie:
                logging.debug("Read more elements than table headings")
                self.table_data[self.row_key][self.headings[len(self.headings)-1]] += data

            self.att_no += 1

    def handle_endtag(self, tag):
        '''Method is called when an html tag ends.
           eg </tr>....
           Param          Type         Description
           tag            String       html tag
        '''
        if self.in_table and tag == 'tr':
            self.new_row = False
        if self.new_row and tag == 'td':
            self.in_td = False
        if self.new_row and tag == 'th':
            self.in_th = False
        if tag == 'table':
            self.in_th = False

    def get_table_data(self, table_id, html):
        '''Method takes the table name and html text and
           returns the table contents in a dictionary object.
           Param          Type         Description
           table_id       String       Table ID/name
           html           String       HTML text
        '''
        self.table_id = table_id
        self.feed(html)
        return self.table_data

