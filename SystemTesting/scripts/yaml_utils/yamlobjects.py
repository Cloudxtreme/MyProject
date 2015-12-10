import yaml


class Step(yaml.YAMLObject):
    yaml_tag = u'!Step'
    setup = None
    verify = None
    cleanup = None
    can_be_optimized = True


class TestStep(Step):
    yaml_tag = u'!TestStep'
    can_be_optimized = False


if __name__ == '__main__':
    import argparse
    import doctest
    import sys

    parser = argparse.ArgumentParser()
    parser.add_argument('--doctest', action='store_true', default=False)

    args = parser.parse_args(sys.argv[1:])
    if args.doctest:
        doctest.testmod(optionflags=doctest.ELLIPSIS)
        sys.exit(0)
