if [ -z "$STORAGE_DIRECTORY" ]; then
  STORAGE_DIRECTORY=~/.coda-config/client_storage
fi

if [ -z "$POSTGRES_PORT" ]; then
  POSTGRES_PORT=5432
fi

if [ -z "$DATABASE_NAME" ]; then
  DATABASE_NAME=coda
fi

if [ -z "$ADMIN" ]; then
  ADMIN=$(whoami)
fi

if [ -z "$HASURA_PORT" ]; then
  HASURA_PORT=9000
fi

init () {
    pg_ctl init -D $STORAGE_DIRECTORY;
    pg_ctl -o "-F -p $POSTGRES_PORT" start -D $STORAGE_DIRECTORY;
    createdb $DATABASE_NAME -p $POSTGRES_PORT;
    psql -p $POSTGRES_PORT -d $DATABASE_NAME -f src/app/archive/create_schema.sql;
    pg_ctl stop -D $STORAGE_DIRECTORY
}

start() {
  pg_ctl -o "-F -p $POSTGRES_PORT" start -D $STORAGE_DIRECTORY
}

start_hasura() {
    docker run -p $HASURA_PORT:8080 \
        -e HASURA_GRAPHQL_DATABASE_URL=postgres://$ADMIN:@host.docker.internal:$POSTGRES_PORT/$DATABASE_NAME \
        -e HASURA_GRAPHQL_ENABLE_CONSOLE=true \
        hasura/graphql-engine:v1.0.0-beta.6 &
    sleep 4
    
    # Makes a table queryable through graphql
    curl -d'{"type":"replace_metadata", "args":'$(cat scripts/archive/metadata.json)'}' http://localhost:$HASURA_PORT/v1/query;
    # Generates the graphql query types for OCaml
    python scripts/introspection_query.py --port $HASURA_PORT --uri /v1/graphql > src/app/archive/archive_graphql_schema.json
}

stop () {
    pg_ctl stop -D $STORAGE_DIRECTORY
}

flush () {
    rm -rf $STORAGE_DIRECTORY    
}

update_graphql () {
  python scripts/introspection_query.py > src/app/archive/graphql_schema.json
}

set -x #echo on
set -eu

if [[ $1 =~ ^(init|start|start_hasura|stop|flush)$ ]]; then
  "$@"
else
  echo "Invalid subcommand $1" >&2
  exit 1
fi