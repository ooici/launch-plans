#OOICI Release 2 Launch Plan

This launch plan deploys the OOI R2 system. It supports a few different
deployments:

* local (lightweight) - run all services on your local machine. This mode is
  great for testing service deployments quickly without booting VMs.

* OOI Nimbus - deploy onto the OOI Nimbus cloud. This is the production target.

* EC2 - scale testing and other experiments can be easier on EC2 where there is
  more capacity, so this mode is also supported. Note that different base images
  are used so dependencies can be problematic.


##i. Getting the code:

###First steps:

Regardless of whether you want to run locally or on VMs, you will need to set up
a virtualenv and cloudinitd. cloudinitd is what runs the launch plan:

    $ virtualenv venv --no-site-packages
    $ source venv/bin/activate
    $ pip install -e 'git+git://github.com/nimbusproject/cloudinit.d.git#egg=cloudinitd'
    $ pip install -e 'git+git://github.com/nimbusproject/ceiclient.git#egg=ceiclient'

###Setting up local tools (lightweight only):

If you want to run a launch plan on your local machine, you will need to install
Pyon, coi-services, and epuharness. If you plan on running on VMs only, you can skip
to step ii.

To launch a plan locally, you can use the local.conf cloudinitd config file,
which will prepare a Process Dispatcher and an EEAgent (or a number of them),
for your services to be deployed in. To use this, you'll need to prepare a
virtualenv with your environment like so:

    $ pip install -r https://raw.github.com/nimbusproject/epuharness/master/requirements.txt

Or if you already have an epu development virtualenv already setup, just
install the epu-harness package into your env. Do this with:

    $ source path/to/your/venv/bin/activate
    $ pip install -e 'git+git://github.com/nimbusproject/epuharness.git#egg=epuharness'


You will also need a pyon and coi-services installation:

    $ git clone https://github.com/ooici/pyon.git
    $ git clone https://github.com/ooici/coi-services.git
    $ cd coi-services 
    $ git submodule update --init
    $ python bootstrap.py
    $ bin/buildout
    $ bin/generate_interfaces

*Is this needed anymore after the Pyon refactor?*

Turn off force_clean in coi-services:
    Create res/config/pyon.local.yml with following content:

    system:
      force_clean: False


You will also need to ensure that you have RabbitMQ set up and running, and
couchdb running if you would like to use Pyon.


##ii. Running the launch plan locally:

Now you will need to set up a few environment variables to set your RabbitMQ
credentials and exchange. The easiest way to do this is with a file that you
source:

    $ cat ~/.secrets/local

    # Pyon installation
    export PYON_PATH=/path/to/coi-services

    # Set to 0 if you would rather not clean the db on each launch
    export CLEANCOUCHDB=1

    # Credentials for RabbitMQ
    export RABBITMQ_HOST="localhost"
    export RABBITMQ_USERNAME="guest"
    export RABBITMQ_PASSWORD="guest"

    # Credentials for CouchDB
    export COUCHDB_HOST="localhost"
    export COUCHDB_USERNAME=""
    export COUCHDB_PASSWORD=""

    export COI_SYSTEM_NAME=`uuidgen`

    export EXCHANGE_SCOPE="xchg`date +%s`"

    if [ -n $EXCHANGE_SCOPE ]; then
        RUN=$EXCHANGE_SCOPE
    fi
    export RUN

Next, you will need to generate the pyon launch levels with the rel2levels.py script. Do this with:

    $ source ~/.secrets/local
    $ ./rel2levels.py -c local.conf $PYON_PATH/res/deploy/r2deploy.yml -f -a testsystem/testsystem.conf

Now you can launch the local launch plan with:

    $ source ~/.secrets/local ; cloudinitd boot local.conf -n $RUN 

Once you are done, you can terminate the plan with:

    $ cloudinitd terminate $RUN

##iii. Running the launch plan on OOI Nimbus

Now that we've run locally, let's try running with real VMs. You're going to
need a similar file to ~/.secrets/local. You will also need to set up your
Nimbus credentials. If you are outside the UCSD network you will need to be
connected to the VPN.

    $ cat ~/.secrets/nimbus

    # Credentials for Nimbus
    
    export NIMBUS_KEY=`cat ~/.secrets/OOINIMBUS_KEY`
    export NIMBUS_SECRET=`cat ~/.secrets/OOINIMBUS_SECRET`

    export CTXBROKER_KEY="$NIMBUS_KEY"
    export CTXBROKER_SECRET="$NIMBUS_SECRET"

    export EPU_IAAS_SITE="ooi.ucsd"
    export EPU_IAAS_CREDENTIALS="~/.secrets/$EPU_IAAS_SITE.yml"

    # Credentials for cloudinit.d itself
    # cloudinit.d uses to start the base nodes
    export CLOUDINITD_IAAS_ACCESS_KEY="$NIMBUS_KEY"
    export CLOUDINITD_IAAS_SECRET_KEY="$NIMBUS_SECRET"
    export CLOUDINITD_IAAS_SSHKEYNAME="ooi"
    export CLOUDINITD_IAAS_SSHKEY="~/.ssh/id_rsa.pub"

    # Credentials for RabbitMQ
    export RABBITMQ_USERNAME=`uuidgen`
    export RABBITMQ_PASSWORD=`uuidgen`

    export COUCHDB_USERNAME=`uuidgen`
    export COUCHDB_PASSWORD=`uuidgen`

    export COI_SYSTEM_NAME=sys`uuidgen`

    export EXCHANGE_SCOPE="xchg`date +%s`"

    if [ -n $EXCHANGE_SCOPE ]; then
        RUN=$EXCHANGE_SCOPE
    fi
    export RUN

You will need to create a credentials file in ~/.secrets/ooi.ucsd.yml . It
should look something like this:

    ---
    access_key: YOUR_NIMBUS_KEY_HERE
    secret_key: YOUR_NIMBUS_SECRET_HERE
    key_name: ooi


Next, you will need to generate the pyon launch levels with the rel2levels.py
script. Do this with:

    $ source ~/.secrets/nimbus
    $ ./rel2levels.py -c ooinimbus.conf $PYON_PATH/res/deploy/r2deploy.yml -f

Now you can launch the local launch plan with:

    $ source ~/.secrets/nimbus ; cloudinitd boot ooinimbus.conf -n $RUN 

Once you are done, you can terminate the plan with:

    $ cloudinitd terminate $RUN


##iv. Running the launch plan on EC2 (experimental)

EC2 is also supported, however be forewarned that the base image is
different. Not all dependencies may be available or compatible.

You're going to need a
similar file to ~/.secrets/local. You will also need to set up your Context
Broker and Amazon EC2 credentials. You will need to put your Context Broker
credentials in ~/.secrets/CTXBROKER_KEY, and ~/.secrets/CTXBROKER_SECRET, and
your AWS credentials in ~/.secrets/AWS_ACCESS_KEY_ID and
~/.secrets/AWS_SECRET_ACCESS_KEY .

    $ cat ~/.secrets/ec2

    # Credentials for Nimbus Context Broker
    # The default is the broker at FutureGrid hotel. Use your Cumulus creds.

    export CTXBROKER_KEY=`cat ~/.secrets/CTXBROKER_KEY`
    export CTXBROKER_SECRET=`cat ~/.secrets/CTXBROKER_SECRET`

    # Credentials for EC2
    # The provisioner uses to start worker nodes on EC2 in some situations
    export AWS_ACCESS_KEY_ID=`cat ~/.secrets/AWS_ACCESS_KEY_ID`
    export AWS_SECRET_ACCESS_KEY=`cat ~/.secrets/AWS_SECRET_ACCESS_KEY`

    export EPU_IAAS_SITE="ec2.us-west-1"
    export EPU_IAAS_CREDENTIALS="~/.secrets/$EPU_IAAS_SITE.yml"

    # Credentials for cloudinit.d itself
    # cloudinit.d uses to start the base nodes
    export CLOUDINITD_IAAS_ACCESS_KEY="$AWS_ACCESS_KEY_ID"
    export CLOUDINITD_IAAS_SECRET_KEY="$AWS_SECRET_ACCESS_KEY"
    export CLOUDINITD_IAAS_SSHKEYNAME="ooi"
    export CLOUDINITD_IAAS_SSHKEY="~/.ssh/id_rsa.pub"

    # Credentials for RabbitMQ
    export RABBITMQ_USERNAME=`uuidgen`
    export RABBITMQ_PASSWORD=`uuidgen`

    export COUCHDB_USERNAME=`uuidgen`
    export COUCHDB_PASSWORD=`uuidgen`

    export COI_SYSTEM_NAME=sys`uuidgen`

    export EXCHANGE_SCOPE="xchg`date +%s`"

    if [ -n $EXCHANGE_SCOPE ]; then
        RUN=$EXCHANGE_SCOPE
    fi
    export RUN

You will need to create a credentials file in ~/.secrets/ec2.us-west-1.yml . It
should look something like this:

    ---
    access_key: YOUR_AWS_KEY_HERE
    secret_key: YOUR_AWS_SECRET_HERE
    key_name: ooi


Next, you will need to generate the pyon launch levels with the rel2levels.py
script. Do this with:

    $ source ~/.secrets/ec2
    $ ./rel2levels.py -c ec2.conf $PYON_PATH/res/deploy/r2deploy.yml -f

Now you can launch the local launch plan with:

    $ source ~/.secrets/ec2 ; cloudinitd boot ec2.conf -n $RUN 

Once you are done, you can terminate the plan with:

    $ cloudinitd terminate $RUN

