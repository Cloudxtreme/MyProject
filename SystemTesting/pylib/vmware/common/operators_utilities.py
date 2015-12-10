import os
import sys


def file_equal_to(pyset_from_server, expected_output_file_path):
    """
    Compares the contents from the available pyset from server
    with the contents of the specified file.

    Returns True on exact match else returns False
    """
    pyset = set()
    for l in open(os.path.dirname(
            os.path.realpath(sys.argv[0])) + "/" +
            expected_output_file_path, "r"):
        if len(l.strip()) > 0:
            pyset.add(l.strip())

    pyset_from_server = eval(pyset_from_server)
    if pyset == pyset_from_server:
        return "SUCCESS"

    return "FAILURE"


def is_between(actual_value, expected_value):
    """
    Compares the server data between expected range

    Returns True on exact match else returns False
    """
    lower_upper = expected_value.split("-", 1)
    lower = int(lower_upper[0])
    upper = int(lower_upper[1])
    if int(actual_value) >= lower and int(actual_value) <= upper:
        return "SUCCESS"
    return "FAILURE"


def super_set(actual_value, expected_value):
    """
    Compares the server data between expected range

    Returns SUCCESS on exact match else returns FAILURE
    """
    import json
    import re
    actual_value_json = json.dumps(actual_value)
    for py_dict in expected_value:
        for value in py_dict.values():
            for individual_value in value.split(','):
                match_individual_value = re.search(
                    individual_value, actual_value_json)
                if not match_individual_value:
                    return "FAILURE"

    return "SUCCESS"
