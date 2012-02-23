Edit the "provisioner/cei_environment" file (add the correct credentials).

Then run:

$ cp chefsolo.sh provisioner/run.sh
$ tar cvzf provisioner.tar.gz provisioner/

Then proceed with launching "main.conf" per the documentation.

(it itself needs credentials: CLOUDINITD_IAAS_ACCESS_KEY and CLOUDINITD_IAAS_SECRET_KEY).
