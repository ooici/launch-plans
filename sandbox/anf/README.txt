Edit the deps-epu.conf (where it says "TODO" add the AWS credentials to plant on the worker node in order to pull down the protected binaries) 

Edit the "provisioner/cei_environment" file (add the correct credentials where it says "TODO").

Then run:

$ cp chefsolo.sh provisioner/run.sh
$ tar cvzf provisioner.tar.gz provisioner/

Then proceed with launching "main.conf" per the documentation.

(cloudinit.d itself needs credentials: CLOUDINITD_IAAS_ACCESS_KEY and CLOUDINITD_IAAS_SECRET_KEY).
