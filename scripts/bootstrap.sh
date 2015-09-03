# Synopsis  : ./bootstrap.sh {admin-password}
# Parameter : database admin password
# ---
# Preconditions
# - eXist instance running
# - edit ../../../../client.properties to point to the running instance (port number, etc.)
# ---
# Creates and loads /db/www/poll/config and /db/www/poll/mesh collections
../../../../bin/client.sh -u admin -P $1 -m /db/www/poll/mesh -p ../mesh
../../../../bin/client.sh -u admin -P $1 -m /db/www/poll/config -p ../config
../../../../bin/client.sh -u admin -P $1 -F bootstrap.xql

