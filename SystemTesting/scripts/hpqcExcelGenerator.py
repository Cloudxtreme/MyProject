#!/usr/bin/env python
########################################################################
# Copyright (C) 2012 VMware, Inc.
# All Rights Reserved
# Usage : python hpqcExcelGenerator.py  --yaml <yaml tds> --xls <xls file name>
#           --skip [OPTIONAL]
# To run this script install PyYAML and xlwt package
#       $ pip install PyYAML
#       $ pip install xlwt
########################################################################

import abc
import json
import os
import pprint
import sys
import xlwt
import yaml

import yaml_utils.vdnet_spec as vdnet_spec

DEFAULT_KEYWORD_GENERIC = 'generic'


class Constraint:
    """ This is the abstract class for all constraint type classes
    """
    key = ""
    required = False

    @abc.abstractproperty
    def is_valid(self, inp):
        pass


class TextConstraint(Constraint):
    """ This class is used for fields with text boxes
    """
    type = ""

    def is_valid(self, inp):
        if self.type == "Number":
            if inp is None or not (type(inp) is int or inp.isdigit()):
                print ("Invalid value: '" + str(inp) + "' for field '" +
                       self.key + "'. Value should be numeric.")
                return False
        return True


class SelectConstraint(Constraint):
    """ This class is used for fields with drop down boxes
    """
    list = []

    def is_valid(self, inp):
        for value in self.list:
            if inp is not None and value.lower() == inp.lower():
                return True
        print ("Invalid value: '" + str(inp) + "' for field '" + self.key +
               "'. This value is not in allowed list")
        print "Allowed list is : %s" % self.list

        return False


class ConstraintList:
    """ Collection class for the constraints
    """

# List of constraint objects
    clist = list()

    def create_list_from_json(self, json_data):
        """ Method used to add constraints to the constraint list
        :param json_data: data extracted from constraints.json
        :return: None
        """
        for field in json_data:
            temp_constraint = Constraint()
            if field["ConstraintType"] == "Input":
                temp_constraint = TextConstraint()
                temp_constraint.key = field["FieldName"]
                temp_constraint.required = field["IsRequired"]
                temp_constraint.type = field["AllowedInput"]
            if field["ConstraintType"] == "Select":
                temp_constraint = SelectConstraint()
                temp_constraint.key = field["FieldName"]
                temp_constraint.required = field["IsRequired"]
                temp_ConstraintList = list()
                for inputVal in field["AllowedInput"]:
                    temp_ConstraintList.append(inputVal)
                    temp_constraint.list = temp_ConstraintList
            self.clist.append(temp_constraint)

    def is_valid(self, key, value):
        for constraint in self.clist:
            if constraint.key.lower() == key.lower():
                if not constraint.is_valid(value):
                    return False
        return True

    def json_object_has_required_fields(self, json_object1):
        """ This method is used to check if all the fields that are required
            by the constraint list are present in the input test details
        :param json_object1:
        :return:
        """
        json_object = {}
        for key, value in json_object1.iteritems():
            json_object[key.lower()] = value

        for constraint in self.clist:
            if constraint.key != "subject":
                if constraint.required:
                    if constraint.key not in json_object:
                        print ("Field '" + constraint.key +
                               "' is required field, please modify yaml.")
                        return False
                    if not json_object[constraint.key]:
                        print ("Field '" + constraint.key +
                               "' is required field, please modify yaml.")
                        return False
        return True


def write_header(ws0, style, json_data):
    ws0.write_merge(1, 1, 0, 8, 'TEST CASE DEFINITIONS', style)
    ws0.write_merge(1, 1, 9, 20, 'TEST CASE METADATA - LIFECYCLE, METRICS',
                    style)
    ws0.write_merge(1, 1, 21, 22, 'TEST CONFIGURATIONS', style)
    ws0.write_merge(1, 1, 23, 24, 'REFERENCES', style)
    for field in json_data:
        ws0.write(2, int(field["ColumnNumber"]), field["ColumnName"], style)


def add_row(ws0, rowexcel, i, json_data, style):
    row = {}
    for key, value in rowexcel.iteritems():
        row[key.lower()] = value

    keywords = []
    for field in json_data:
        column = int(field['ColumnNumber'])
        fieldname = field['FieldName']
        required = field['IsRequired']
        if fieldname == 'tags':
            if fieldname in row:
                keywords.append(row[fieldname])
            rowData = ','.join(keywords)
        elif fieldname == 'subject':
            if 'qcpath' in row and row['qcpath']:
                subject = ('', row['product'], row['category'],
                           row['component'], row['qcpath'])
                keywords.append(row['qcpath'])
            else:
                subject = ('', row['product'], row['category'],
                           row['component'])
                keywords.append(DEFAULT_KEYWORD_GENERIC)
            rowData = '\\'.join(subject)
        elif fieldname == 'procedure':
            # If the procedure is provided as a list, combine the steps into a
            # delimited string. Data for the row must ultimately be formatted
            # as a string.
            try:
                iter(row['procedure'])
                if type(row['procedure']) is str:
                    rowData = row['procedure']
                else:
                    rowData = '\n'.join(row['procedure'])
            except TypeError:
                rowData = str(row['procedure'])
        else:
            if fieldname not in row:
                if required:
                    print ('Field %s is required, but not set in:' % fieldname)
                    pprint.pprint(row)
                    sys.exit(1)
                else:
                    continue  # Skip values that are not required
            else:
                rowData = row[fieldname]
        ws0.write(i, column, rowData, style)


def hpqcExcelGenerator(yaml_file_list, xls_file, skip_vdnet_spec):
    fnt = xlwt.Font()
    fnt.name = 'Arial'
    fnt.colour_index = 0
    fnt.bold = True

    # Setting style information for cells
    borders = xlwt.Borders()
    borders.left = 1
    borders.right = 1
    borders.top = 1
    borders.bottom = 1
    al = xlwt.Alignment()
    al.horz = xlwt.Alignment.HORZ_CENTER
    al.vert = xlwt.Alignment.VERT_CENTER
    style = xlwt.XFStyle()
    style.font = fnt
    style.borders = borders
    style.alignment = al

    # Creating the Excel worksheet
    wb = xlwt.Workbook()
    ws0 = wb.add_sheet('sheet0')

    # Getting field information from a JSON file
    scriptDir = os.path.dirname(os.path.realpath(__file__))
    field_data = json.loads(
        open(scriptDir + os.sep + "constraints.json").read())

    write_header(ws0, style, field_data)

    # Getting constraint information from previously extracted fieldi
    # information
    constList = ConstraintList()
    constList.create_list_from_json(field_data)

    j = 3
    for tds in yaml_file_list:
        if skip_vdnet_spec:
            data = yaml.load(open(tds, 'r'))
        else:
            data = vdnet_spec.resolve_tds(tds, None, None, None)
        for row in data:
            if not skip_vdnet_spec and not vdnet_spec.is_a_test(data[row]):
                msg = "%s [missing keys TestName|WORKLOADS]" % row
                print msg, 'Continuing,  with others ...'
                continue
            # Checking constraints before adding new row
            isDataValid = True
            if not constList.json_object_has_required_fields(data[row]):
                isDataValid = False
                print "Data validation failed for test %s" % row
            for key, value in data[row].iteritems():
                if not constList.is_valid(key, value):
                    isDataValid = False
            if not isDataValid:
                pprint.pprint(data[row])
                print "Offending Testcase : " + row + " with data:"
                # In case of invalid data fail the entire file
                sys.exit(1)
            add_row(ws0, data[row], j, field_data, style)
            j += 1
    wb.save(xls_file)


if __name__ == '__main__':
    import argparse
    import doctest

    parser = argparse.ArgumentParser()
    parser.add_argument('--doctest', action='store_true', default=False)
    parser.add_argument('--yaml', action='append', nargs='+',
                        help='List of tds yaml files to convert')
    parser.add_argument('--xls', default='hpqc_out.xls',
                        help='File name of xls file that needs to be created')
    parser.add_argument('--skip-vdnet-spec', action='store_true', default=False,
                        help='Option to skip vdnet_spec and use pure yaml')

    args = parser.parse_args(sys.argv[1:])
    if args.doctest:
        doctest.testmod(optionflags=doctest.ELLIPSIS)
        sys.exit(0)
    yaml_list = sum(args.yaml, [])
    hpqcExcelGenerator(yaml_list, args.xls, args.skip_vdnet_spec)
