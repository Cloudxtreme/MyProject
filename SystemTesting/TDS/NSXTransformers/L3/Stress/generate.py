import sys

import jinja2
import yaml

ENV = jinja2.Environment(loader=jinja2.FileSystemLoader('./'))

def jinja2_expand(config, template, out):
    with open(config) as f:
        d =  yaml.load(f)
        # print d

        # Render template and print generated config to console
        template = ENV.get_template(template)
        o = template.render(config=d)
        with open(out, 'w+') as g:
            g.write(o)

if __name__ == '__main__':
    import argparse
    import doctest

    parser = argparse.ArgumentParser()
    parser.add_argument('--doctest', action='store_true', default=False)
    parser.add_argument('--config', default='config.yaml',
                        help='Config file for jinja2 template expansion')
    parser.add_argument('--template', default='jinja.tmpl',
                        help='Template file to be used for jinja2 expansion')
    parser.add_argument('--output', default='out.yaml',
                        help='Output filename to store the expanded template')

    args = parser.parse_args(sys.argv[1:])
    if args.doctest:
        doctest.testmod(optionflags=doctest.ELLIPSIS)
        sys.exit(0)
    jinja2_expand(args.config, args.template, args.output)
