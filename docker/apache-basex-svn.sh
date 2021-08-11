#!/bin/bash

echo $1 _ $2 _ $3 _ $4

sudo -u basex echo $(whoami) $JAVA_HOME _ $PATH

sudo -u basex env "PATH=$PATH" java -version

sudo -u basex env "PATH=$PATH" basex/bin/basexhttp -h$1 -p$2 -s$3 -S

sudo -u basex env "PATH=$PATH" basex/bin/basexclient -p$2 -Padmin -Uadmin -c "ALTER PASSWORD admin $4"

/sbin/apachectl -DFOREGROUND
