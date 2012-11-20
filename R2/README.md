OOICI Release 2 Launch Plan
===========================

This is not a launch plan directly but rather a _generator_ for launch plans.
The Release 2 system is complex and supports many different launch modes and
behaviors so it is much easier to generate plans for each needed launch
instead of building the casing logic into a single plan.


Installation
------------

The first step is installing needed dependencies. It is recommended to create
and source a virtualenv. You may use virtualenvwrapper or just directly create
an environment in this directory:

    $ virtualenv venv
    $ source venv/bin/activate

Once your virtualenv is created and sourced, install needed plan dependencies
using ``pip``. Different installation options are available. If you are only
concerned with running standard VM launches, install the default requirements:

    $ pip install -r requirements/default.txt

If instead, you also want to run local (lightweight) launches, use the
``local.txt`` requirements file. This brings in a number of additional
dependencies which are used to simulate a launch environment on your machine.

    $ pip install -r requirements/local.txt

For local launches, you will also need an installation of
[coi-services](https://github.com/ooici/coi-services).


Generating Launch Plans
-----------------------

Launch plans are created using the ``bin/generate-plan`` command line tool.
Check this command's help output for detailed usage information:

    $ bin/generate-plan --help

Several inputs are used to create each launch plan. First you must select a
launch profile from the supported set. Currently these are:

* ``local`` - lightweight launch run on your machine only
* ``ooinimbus-dynamic`` - self-contained launch on OOI Nimbus cloud
* ``ooinimbus-static`` - use the OOI Nimbus cloud with external RabbitMQ
  and CouchDB services.
* ``ec2-dynamic`` - self-contained launch on EC2 West 1 region
* ``ec2-static`` - use the EC2 West 1 region with external RabbitMQ
  and CouchDB services.

You also need an OOI REL file (usually ``r2deploy.yml``) and a CEI launch
file. These can be found in the ion-definitions repository, under the
``res/deploy/`` and ``res/launch/`` directories respectively.

Finally you must provide an output path for the generated plan. This should
be a nonexistent directory. If you want to overwrite an existing generated
plan, use the ``--force`` option (carefully!).

For example, here is a command that creates a launch plan using the
ooinimbus-dynamic profile:

    $ bin/generate-plan --profile ooinimbus-dynamic --rel r2deploy.yml --launch alpha.yml plans/alpha

This will generate a plan into the ``plans/alpha/`` directory. Conventionally,
plans are placed into this ``plans/`` directory but you can provide any path. The
generated plan is self-contained, so you can move it elsewhere at will.

Generating a lightweight launch plan might look like:

    $ bin/generate-plan --profile local --rel r2deploy.yml --launch lightweight.yml plans/lightweight

If needed, you can specify an alternate pyon config file (that will be loaded
into the directory on boot) with the ``--pyon-config`` argument. By default
the file ``src/baseplan/common/pyon.yml`` will be used.


Booting Launch Plans
--------------------

TODO (same as before, for now. source envs and run cloudinitd)


Development
-----------

Some tools are provided to ease development and testing of the launch plans
and generator. For developing static plan components (such as the base CEI
boot levels), the ``--use-links`` flag to ``bin/generate-plan`` is helpful:
instead of copying static components, they will be symlinked into the plan.
This allows changes to be made more easily and to be tracked by git.

For developing the generator script itself, the ``--no-cleanup`` flag is
useful. When a plan cannot be generated, this flag prevents the temporary
output directory from being deleted (under the same parent directory as the
destination output directory). This allows an easier postmortem of the
partially-generated plan.


