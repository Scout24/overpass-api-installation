# overpass-api-installation
collection of installation scripts in /bin/bash to install required components: overpass-api (7.58), its init.d service and an nginx integration

check out the repo and start `installation_all.sh`, this downloads the latest state of a dev branch of the overpass api mmd: https://github.com/mmd-osm/Overpass-API/tree/test758_lz4hash

After installation is installs nginx configurations and an additional overpass service to start and stop the actual running overpass implementation.
This implementation however, requires still a database to run on. 

# Tested only in

* Ubuntu Trusty