#Lightweight Launch Plan

##i. Getting the code:

To launch a plan locally, you can use the local.conf cloudinitd config file,
which will prepare a Process Dispatcher and an EEAgent (or a number of them),
for your services to be deployed in. To use this, you'll need to prepare a
virtualenv with your environment like so:

    $ virtualenv venv --no-site-packages
    $ source venv/bin/activate
    $ pip install -r https://raw.github.com/nimbusproject/epuharness/master/requirements.txt

Or if you already have an epu development virtualenv already setup, just
install the epu-harness package into your env. Do this with:

    $ source path/to/your/venv/bin/activate
    $ pip install -e 'git+git://github.com/nimbusproject/epuharness.git#egg=epuharness'


If you would like to launch pyon processes, you will need a pyon and
coi-services installation. You can make one with:

    $ git clone https://github.com/ooici/pyon.git
    $ git clone https://github.com/ooici/coi-services.git
    $ cd coi-services 
    $ git submodule update --init
    $ python bootstrap.py
    $ bin/buildout
    $ bin/generate_interfaces

Turn off force_clean in coi-services:
    Create res/config/pyon.local.yml with following content:

    system:
      force_clean: False

You will also need to ensure that you have RabbitMQ set up and running, and
couchdb running if you would like to use Pyon.

##ii. Setting up authentication:

Now you will need to ensure that you can ssh to your local machine without a
password. To do this, you will need to ensure that you have the ssh daemon
running on your system, and you will need an ssh key, and that same key needs
to be in your authorized_keys file. Test this with:

    $ ssh localhost

If you see something like the following, then you are set up.

    $ ssh localhost
    Last login: Wed Feb  1 13:18:00 2012
    $

If you see something like the following, you need to enable your ssh daemon:

    $ ssh localhost
    ssh: connect to host localhost port 22: Connection refused

If you see something like the following, you need to set up an ssh key. 

    $ ssh localhost
    user@localhost's password:

If you do not have an ssh key already, you can generate one:

    $ ls ~/.ssh/id_*
    ls: /home/user/.ssh/id_*: No such file or directory
    $ ssh-keygen

Once you have an ssh key available, simply append the public key to your
authorized_keys file:

    $ ls ~/.ssh/id_*
    /home/user/.ssh/id_rsa /home/user/.ssh/id_rsa.pub
    $ cp ~/.ssh/authorized_keys cp ~/.ssh/authorized_keys.backup
    $ cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

Now try sshing again:

    $ ssh localhost                                                              
    Last login: Wed Feb  1 13:18:00 2012                                         
    $ 


##iii. Running the Launch plan:

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
    export COUCHDB_USERNAME="guest"
    export COUCHDB_PASSWORD="guest"

    export EXCHANGE_SCOPE="xchg`date +%s`"

    if [ -n $EXCHANGE_SCOPE ]; then
        RUN=$EXCHANGE_SCOPE
    fi
    export RUN

Next, you will need to generate the pyon launch levels with the rel2levels.py script. Do this with:

    $ source ~/.secrets/local
    $ ./rel2levels.py $PYON_PATH/res/deploy/r2deploy.yml -f -a testsystem/testsystem.conf

Now you can launch the local launch plan with:

    $ source ~/.secrets/local ; cloudinitd boot local.conf -n $RUN 

Once you are done, you can terminate the plan with:

    $ cloudinitd terminate $RUN

##iv. Running the Launch plan on EC2

Now that we've run locally, let's try running on EC2. You're going to need a
similar file to ~/.secrets/local. You will also need to set up your Context
Broker and Amazon EC2 credentials. You will need to put your Context Broker
credentials in ~/.secrets/CTXBROKER_KEY, and ~/.secrets/CTXBROKER_SECRET, and
your AWS credentials in ~/.secrets/AWS_ACCESS_KEY_ID and
~/.secrets/AWS_SECRET_ACCESS_KEY .

    $ cat ~/.secrets/main

    # Credentials for Nimbus Context Broker
    # The default is the broker at FutureGrid hotel. Use your Cumulus creds.

    export CTXBROKER_KEY=`cat ~/.secrets/CTXBROKER_KEY_CALLIOPEX`
    export CTXBROKER_SECRET=`cat ~/.secrets/CTXBROKER_SECRET_CALLIOPEX`

    # Credentials for EC2
    # The provisioner uses to start worker nodes on EC2 in some situations
    export AWS_ACCESS_KEY_ID=`cat ~/.secrets/AWS_ACCESS_KEY_ID`
    export AWS_SECRET_ACCESS_KEY=`cat ~/.secrets/AWS_SECRET_ACCESS_KEY`

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

    export EXCHANGE_SCOPE="xchg`date +%s`"

    if [ -n $EXCHANGE_SCOPE ]; then
        RUN=$EXCHANGE_SCOPE
    fi
    export RUN

Next, you will need to generate the pyon launch levels with the rel2levels.py
script. Do this with:

    $ source ~/.secrets/main
    $ ./rel2levels.py $PYON_PATH/res/deploy/r2deploy.yml -f

Now you can launch the local launch plan with:

    $ source ~/.secrets/main ; cloudinitd boot main.conf -n $RUN 

Once you are done, you can terminate the plan with:

    $ cloudinitd terminate $RUN

