#!/usr/bin/env python
USAGE = """rel2levels -- convert a rel file to a number of cloudinitd levels
Usage:
rel2levels path/to/rel/file [-f] [-h]
-f or --force: force overwriting pre-existing generated levels
-h or --help:  show this text
"""

import os
import sys
import yaml
import json
import shutil
import argparse
from string import Template

CLOUDINITD_CONFIG = "local.conf"
THIS_DIR=os.path.dirname(__file__)
JSON_TEMPLATE=os.path.join(THIS_DIR, "templates", "pyon.json")
CONF_TEMPLATE=os.path.join(THIS_DIR, "templates", "pyon.conf")
PYONAPP_PREFIX = "pyonapp"

TOP_LEVEL_CONF_MARKER = "########## Pyon Services ##########"

def error(msg, exit_code=1):
    print >>sys.stderr, msg
    sys.exit(exit_code)

def rel2levels(relpath, output_directory=None, json_template_path=None,
        conf_template_path=None, cloudinitd_config_path=None, force=False,
        extra_level=None):
    """Convert a pyon rel file to a launch level for each app

    """

    output_directory = output_directory or '.'
    json_template_path = json_template_path or JSON_TEMPLATE
    conf_template_path = conf_template_path or CONF_TEMPLATE
    cloudinitd_config_path = cloudinitd_config_path or CLOUDINITD_CONFIG

    try:
        with open(json_template_path) as jsonfile:
            json_template = Template(jsonfile.read())
    except:
        error("Problem opening '%s'. Cannot proceed." % json_template_path)

    try:
        with open(conf_template_path) as conffile:
            conf_template = Template(conffile.read())
    except:
        error("Problem opening '%s'. Cannot proceed." % conf_template_path)

    try:
        with open(relpath) as relfile:
            rel_yaml = relfile.read()
    except:
        raise
        error("Problem opening '%s'. Cannot proceed." % relpath)
    
    try:
        with open(cloudinitd_config_path) as cidconffile:
            cloudinitd_config = cidconffile.read()
    except:
        error("Problem opening '%s'. Cannot proceed." % cloudinitd_config_path)

    generated_levels = get_generated_levels(output_directory)
    if generated_levels:
        if force:
            print >>sys.stderr, "Found previously generated levels. Deleting them."
            remove_levels(generated_levels)
        else:
            msg = "Found previously generated levels. Aborting. Use -f to force."
            error(msg)


    app_names = []
    level_configs = []
    cloudinitd_config = clean_plan(cloudinitd_config)
    level_offset = get_last_level(cloudinitd_config)
    level_index = 0
    rel = yaml.load(rel_yaml)
    apps = rel['apps']

    for app in apps:
        validate(app)
        name = app['name']
        name = safe_get_appname(name, app_names)
        app_names.append(name)
        app_json = json.dumps(app, indent=2)
        conf_contents = conf_template.substitute(name=name)
        conf_filename = "%s%s%s.conf" % (PYONAPP_PREFIX, "_", name)
        json_contents = json_template.substitute(name=name, app_json=app_json)
        json_filename = "%s%s%s.json" % (PYONAPP_PREFIX, "_", name)

        level_directory = "%s%02d%s%s" % (PYONAPP_PREFIX, level_index, "_", name)
        level_directory = os.path.join(output_directory, level_directory)
        os.mkdir(level_directory)

        conf_path = os.path.join(level_directory, conf_filename)
        json_path = os.path.join(level_directory, json_filename)
        with open(conf_path, "w") as conf_file:
            conf_file.write(conf_contents)
        with open(json_path, "w") as json_file:
            json_file.write(json_contents)

        level_config = "level%s: %s" % (level_index + level_offset, conf_path)

        level_configs.append(level_config)
        level_index += 1

    if extra_level:
        level_config = "level%s: %s" % (level_index + level_offset, extra_level) 
        level_configs.append(level_config)

    cloudinitd_config = clean_plan(cloudinitd_config)
    cloudinitd_config = append_levels(cloudinitd_config, level_configs)
    
    with open(cloudinitd_config_path, "w") as cidconfig:
        cidconfig.write(cloudinitd_config)

def remove_levels(level_directories):
    for level in level_directories:
        shutil.rmtree(level)

def get_generated_levels(directory):
    files = os.listdir(directory)
    generated_levels = []
    for file in files:
        if PYONAPP_PREFIX in file:
            generated_levels.append(os.path.join(directory, file))

    return generated_levels


def clean_plan(cloudinitd_conf):
    """Remove any generated launch plan levels, and remove them from the 
    plan, and save the file
    """

    if TOP_LEVEL_CONF_MARKER not in cloudinitd_conf:
        msg = "The pyon services marker doesn't seem to be in your config.\n"
        msg += "'%s' should be after the last level in the file." % \
                TOP_LEVEL_CONF_MARKER
        error(msg)

    clean_conf = cloudinitd_conf.split(TOP_LEVEL_CONF_MARKER)[0]
    clean_conf += "%s\n" % TOP_LEVEL_CONF_MARKER
    return clean_conf

def get_last_level(cloudinitd_conf):
    """Get the number of the last level defined in a cloudinitd launch plan
    """

    i = 1
    while True:
        level = "level%s" % i
        if level not in cloudinitd_conf:
            if i == 1:
                msg = "There don't seem to be any levels in your launch plan. "
                msg += "There is probably something wrong with your config."
                error(msg)
            else:
                return i
        else:
            i += 1

def append_levels(cloudinitd_conf, levels):
    for level in levels:
        cloudinitd_conf += "\n%s" % level

    return cloudinitd_conf

def safe_get_appname(wanted_app_name, app_names):
    """ensures that app names are unique by checking against list for
    apps with the same name
    """
    if wanted_app_name not in app_names:
        return wanted_app_name

    i = 1
    while True:
        new_app_name = "%s_%s" % (wanted_app_name, i)
        if new_app_name not in app_names:
            return new_app_name
        else:
            i += 1

def validate(app):
    try:
        name = app['name']
    except KeyError, e:
        argname = e.args[0]
        error("Pyon app does not have required attribute '%s'. App:\n%s" % (
            argname, app))

# Parse cli and start
argv = list(sys.argv)
cmd_name = argv.pop(0)

parser = argparse.ArgumentParser(description='Create cloudinitd levels from a relfile')
parser.add_argument('relfile', metavar='path/to/rel.yml')
parser.add_argument('-f', '--force', dest='force', action='store_const', const=True)
parser.add_argument('-a', '--append-level', nargs=1, metavar='path/to/level.conf', default=[None])
parser.add_argument('-j', '--json-template', nargs=1, metavar='path/to/template.json', default=None)
parser.add_argument('-t', '--conf-template', nargs=1, metavar='path/to/template.conf', default=None)

opts = parser.parse_args()
rel2levels(opts.relfile, force=opts.force,
        extra_level=opts.append_level.pop(0), json_template_path=opts.json-template,         
        conf_template_path=opts.conf-template)
