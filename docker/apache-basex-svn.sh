#!/bin/bash

echo $1 _ $2 _ $3 _ $4

sudo -u basex echo $(whoami) $JAVA_HOME _ $PATH

# https://unix.stackexchange.com/questions/83191/how-to-make-sudo-preserve-path#answer-83194
# (remember we are on Debian because the Alpine apache/svn combo gave us segfaults when using authz)

sudo -u basex env "PATH=$PATH" java -version

sudo -u basex env "PATH=$PATH" basex/bin/basexhttp -h$1 -p$2 -s$3 -S

sudo -u basex env "PATH=$PATH" basex/bin/basexclient -p$2 -Padmin -Uadmin -c "ALTER PASSWORD admin $4"

/sbin/apachectl -DFOREGROUND
