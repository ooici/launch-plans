#!/usr/bin/env python
USAGE = """rel2levels -- convert a rel file to a number of cloudinitd levels
Usage:
rel2levels path/to/rel/file [-f] [-h]
-f or --force: force overwriting pre-existing generated levels
-h or --help:  show this text
"""

import os
import sys
import uuid
import yaml
import json
import shutil
import argparse
from string import Template
from collections import defaultdict
from subprocess import check_call

THIS_DIR = os.path.abspath(os.path.dirname(__file__))
CLOUDINITD_CONFIG = os.path.join(THIS_DIR, "local.conf")
OLD_JSON_TEMPLATE = os.path.join(THIS_DIR, "templates", "pyon.json")
JSON_TEMPLATE = os.path.join(THIS_DIR, "templates", "pyon_process_start.json")
CONF_TEMPLATE = os.path.join(THIS_DIR, "templates", "pyon.conf")
PD_TEMPLATE = os.path.join(THIS_DIR, "templates", "process_definition.json")
HAAGENT_TEMPLATE = os.path.join(THIS_DIR, "templates", "haagent_process.json")
PYONAPP_PREFIX = "pyonapp"

TOP_LEVEL_CONF_MARKER = "########## Pyon Services ##########"


def error(msg, exit_code=1):
    print >>sys.stderr, msg
    sys.exit(exit_code)


def rel2levels(
        relpath, output_directory=None, json_template_path=None,
        pd_template_path=None, haagent_template_path=None,
        conf_template_path=None, cloudinitd_config_path=None, force=False,
        extra_level=None, ignore_bootlevels=False, no_ha=False,
        old_pd_api=False):
    """Convert a pyon rel file to a launch level for each app

    """

    output_directory = output_directory or THIS_DIR
    if json_template_path:
        json_template_path = json_template_path
    elif old_pd_api:
        json_template_path = OLD_JSON_TEMPLATE
    else:
        json_template_path = JSON_TEMPLATE
    conf_template_path = conf_template_path or CONF_TEMPLATE
    pd_template_path = pd_template_path or PD_TEMPLATE
    haagent_template_path = haagent_template_path or HAAGENT_TEMPLATE
    cloudinitd_config_path = os.path.join(THIS_DIR, cloudinitd_config_path)

    json_template = load_template(json_template_path)
    conf_template = load_template(conf_template_path)
    pd_json_template = load_template(pd_template_path)
    haagent_template = load_template(haagent_template_path)

    if relpath[0] != '/':
        relpath = os.path.normpath(os.path.join(os.getcwd(), relpath))

    rel_yaml = load_file(relpath)
    cloudinitd_config = load_file(cloudinitd_config_path)

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

    validate_apps(apps, ignore_bootlevels=ignore_bootlevels)

    process_definition_dir = os.path.join( output_directory, "pd-bootstrap",
            "pd-bootstrap", "process-definitions")

    # ha agent is special case added as a process definition
    haagent_definition_id = make_process_definition("haagent",
            "ion.agents.cei.high_availability_agent", "HighAvailabilityAgent",
            pd_json_template, process_definition_dir)
    app_names.append("haagent")

    # dictionary of lists of apps in each level. bootlevel numbers don't
    # necessarily need to be sequential.
    levels = defaultdict(list)

    # first sort apps into bootlevels
    for app in apps:
        include = app['deploy'].get('include', True)
        if not include:
            print >> sys.stderr, "Not including %s in generated levels" % app['name']
            continue
        bootlevel = app['deploy']['bootlevel']
        levels[bootlevel].append(app)

    # then walk levels and write out all of the files
    for level in sorted(levels.keys()):
        level_apps = levels[level]

        if len(level_apps) == 1:
            name = level_apps[0]['name']
            name = safe_get_appname(name, app_names)
            level_name = "%s%02d_%s" % (PYONAPP_PREFIX, level_index, name)
        else:
            level_name = "%s%02d" % (PYONAPP_PREFIX, level_index)

        level_directory = level_name
        conf_filename = "%s.conf" % level_name
        conf_relative_path = os.path.join(level_directory, conf_filename)
        level_directory_path = os.path.join(output_directory, level_directory)
        os.mkdir(level_directory_path)

        conf_contents = ""
        for app in level_apps:
            name = app['name']
            name = safe_get_appname(name, app_names)
            app_names.append(name)

            process_name, process_module, process_class = app['processapp']
            process_config = app.get('config', {})
            definition_id = make_process_definition(name,
                    process_module, process_class, pd_json_template,
                    process_definition_dir)

            haagent_dashi_name = "ha_%s" % name
            ha_block = app['deploy'].get('ha')
            use_haagent = ha_block and not no_ha

            # write cloudinitd [service] block for app -- with or without HA
            if use_haagent:
                app_conf = conf_template.substitute(name=name,
                        definition_id=haagent_definition_id,
                        haagent_dashi_name=haagent_dashi_name)
            else:
                app_conf = conf_template.substitute(name=name,
                        definition_id=definition_id,
                        haagent_dashi_name="")
            conf_contents += app_conf + "\n"

            # now write the cloudinitd JSON bootconf for the app
            if old_pd_api:
                app_json = json.dumps(app, indent=2)
                json_contents = json_template.substitute(name=name, app_json=app_json)

            elif use_haagent:
                try:
                    policy_name = ha_block['policy']
                    policy_params = ha_block['parameters']
                except KeyError, e:
                    error("ha block for app '%s' is missing '%s' value" % (name, e))

                policy_params_json=json.dumps(policy_params, indent=8)
                process_config_json = json.dumps(process_config, indent=4)
                json_contents = haagent_template.substitute(policy_name=policy_name,
                        policy_parameters=policy_params_json,
                        haagent_dashi_name=haagent_dashi_name,
                        process_definition_id=definition_id,
                        process_config=process_config_json,
                        resource_id=uuid.uuid4().hex)
            else:
                process_config_json = json.dumps(process_config, indent=2)
                json_contents = json_template.substitute(process_config=process_config_json)


            json_filename = "%s_%s.json" % (PYONAPP_PREFIX, name)
            json_path = os.path.join(level_directory_path, json_filename)
            with open(json_path, "w") as json_file:
                json_file.write(json_contents)


        conf_path = os.path.join(level_directory_path, conf_filename)
        with open(conf_path, "w") as conf_file:
            conf_file.write(conf_contents)
        level_config = "level%s: %s" % (level_index + level_offset, conf_relative_path)

        level_configs.append(level_config)
        level_index += 1

    clean_process_definitions(app_names, process_definition_dir)
    tar_process_definitions(output_directory)

    if extra_level:
        if not os.path.isabs(extra_level):
            extra_level = os.path.join(os.getcwd(), extra_level)
        level_config = "level%s: %s" % (level_index + level_offset, extra_level)
        level_configs.append(level_config)

    cloudinitd_config = clean_plan(cloudinitd_config)
    cloudinitd_config = append_levels(cloudinitd_config, level_configs)

    with open(cloudinitd_config_path, "w") as cidconfig:
        cidconfig.write(cloudinitd_config)

def load_file(path):
    try:
        with open(path) as f:
            return f.read()
    except Exception, e:
        error("Problem opening '%s'. Cannot proceed. Error: %s" % (path, str(e)))

def load_template(path):
    return Template(load_file(path))

def remove_levels(level_directories):
    for level in level_directories:
        shutil.rmtree(level)

def clean_process_definitions(app_names, definition_dir):
    """Remove any process definition files not known to be apps
    """
    for f in os.listdir(definition_dir):
        root, ext =  os.path.splitext(f)
        if ext == ".yml" and root not in app_names:
            os.remove(os.path.join(definition_dir, f))


def make_process_definition(name, module, klass, pd_template, definition_dir):
    """Create or update process definition file. Returns process definition ID
    """

    process_definition_filename = "%s.yml" % name
    process_definition_file_path = os.path.join(definition_dir,
            process_definition_filename)

    # first look for an existing definition file
    try:
        with open(process_definition_file_path) as f:
            definition = yaml.load(f)
            process_definition_id = definition.get("process_definition_id")
    except Exception:
        process_definition_id = None

    if not process_definition_id:
        process_definition_id = uuid.uuid4().hex

    pd = pd_template.substitute(name=name, module=module, klass=klass,
            process_definition_id=process_definition_id)

    with open(process_definition_file_path, "w") as pd_file:
        pd_file.write(pd)

    return process_definition_id


def tar_process_definitions(output_dir):
    make_tarball_exe = os.path.join(
        output_dir, "pd-bootstrap", "prepare-tarball.sh")

    check_call(make_tarball_exe)


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


def validate_apps(apps, ignore_bootlevels=False):
    pred = lambda app: 'deploy' in app and 'bootlevel' in app['deploy']

    any_bootlevels = any(pred(app) for app in apps)
    if any_bootlevels and not ignore_bootlevels:
        if not all(pred(app) for app in apps):
            error("Either every app in the rel file must have a bootlevel, or none may.")

    for ndex, app in enumerate(apps):
        validate_app(app)
        if ignore_bootlevels or not any_bootlevels:
            # stick a fake bootlevel on each app
            if not app.get('deploy'):
                app['deploy'] = {}
            app['deploy']['bootlevel'] = ndex + 1


def validate_app(app):
    try:
        name = app['name']
    except KeyError, e:
        argname = e.args[0]
        error("Pyon app does not have required attribute '%s'. App:\n%s" % (
            argname, app))
    bootlevel = app.get('deploy', {}).get('bootlevel')
    if bootlevel is not None:
        try:
            bootlevel = int(bootlevel)
            if bootlevel < 1:
                error("Pyon app '%s' has invalid bootlevel: %s" % (name, bootlevel))
        except ValueError:
            error("Pyon app '%s' has invalid bootlevel value: %s" % (name, bootlevel))


# Parse cli and start
argv = list(sys.argv)
cmd_name = argv.pop(0)

parser = argparse.ArgumentParser(description='Create cloudinitd levels from a relfile')
parser.add_argument('relfile', metavar='path/to/rel.yml')
parser.add_argument('-f', '--force', dest='force', action='store_const', const=True)
parser.add_argument('-a', '--append-level', nargs=1, metavar='path/to/level.conf', default=[None])
parser.add_argument('-j', '--json-template', nargs=1, metavar='path/to/template.json', default=None)
parser.add_argument('-t', '--conf-template', nargs=1, metavar='path/to/template.conf', default=None)
parser.add_argument('-c', '--top-level-config', nargs=1, metavar='path/to/main.conf', default=["local.conf"])
parser.add_argument('-i', '--ignore-bootlevels', dest='ignore_bootlevels',
                    action='store_const', const=True,
                    help="ignore bootlevels in rel and generate one level per app")
parser.add_argument('--no-ha', dest='no_ha',
                    action='store_const', const=True,
                    help="disable HA agents and launch one process per app")
parser.add_argument('-o', '--old-pd-api', dest='old_pd_api',
                    action='store_const', const=True,
                    help="Use old PD API where processes definition and creation is one step")

opts = parser.parse_args()
rel2levels(
    opts.relfile, force=opts.force,
    extra_level=opts.append_level.pop(0), json_template_path=opts.json_template,
    conf_template_path=opts.conf_template,
    cloudinitd_config_path=opts.top_level_config.pop(0),
    ignore_bootlevels=opts.ignore_bootlevels, no_ha=opts.no_ha,
    old_pd_api=opts.old_pd_api)
