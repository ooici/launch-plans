#Deployable type testing harness

This launch plan allows relatively easy testing of deployable types. It runs
Provisioner and DTRS services locally on your machine using ``epu-harness``
but starts VMs on a real IaaS service.

To use this plan you need the following environment variables defined:

    export DEPLOYABLE_TYPE=dt_you_want_to_launch
    export EPU_IAAS_ALLOCATION=m1.small
    export EPU_IAAS_CREDENTIALS=path/to/iaas.creds.yml
    export EPU_IAAS_SITE=your.iaas.site

    export CTXBROKER_HOST=some.ctxbroker.org
    export CTXBROKER_KEY=yourkey
    export CTXBROKER_SECRET=yoursecret

    export EXCHANGE_SCOPE=somethingunique
    export RABBITMQ_HOST=localhosy
    export RABBITMQ_PASSWORD=guest
    export RABBITMQ_USERNAME=guest

    # extra envs used to populate Provisioner vars
    # note that couch does not necessarily need to be running
    export COI_SYSTEM_NAME=somethingunique
    export COUCHDB_PASSWORD=couchuser
    export COUCHDB_USERNAME=couchpass

You also need a virtualenv with epu-harness and cloudinit.d installed. Your
deployable type may require provisioner variables not present in the launch.
You can add them to provision/vars.json.

The plan starts a single instance of the specified deployable type. After the
launch completes you can query instance info using ceictl:

    $ ceictl -n $RUN provisioner describe

When you terminate the launch, all instances should be killed but you should
check IaaS to be sure.
