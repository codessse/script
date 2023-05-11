#!/bin/bash

mkdir -p postgres-upgrade-testing
cd postgres-upgrade-testing
OLD='12'
NEW='15'
DBname='testDB'
SQLFILE='./testDB_backup.sql'

echo "Create Old PostgreSQL container..."
docker run -dit --name postgres-upgrade-testing -e POSTGRES_PASSWORD=password -v "$PWD/$OLD/data":/var/lib/postgresql/data "postgres:$OLD"

sleep 1

echo "Container Created"
echo "Processing Old PostgreSQL..."
docker exec -i postgres-upgrade-testing psql -U postgres -c "CREATE DATABASE $DBname;"
cat $SQLFILE | docker exec -i postgres-upgrade-testing psql -U postgres -d $DBname

docker stop postgres-upgrade-testing
docker rm postgres-upgrade-testing

echo "Upgrading Database..."
docker run --rm -v "$PWD":/var/lib/postgresql "tianon/postgres-upgrade:$OLD-to-$NEW" --link

echo "Processing New PostgreSQL..."
docker run -dit --name postgres-upgrade-testing -e POSTGRES_PASSWORD=password -v "$PWD/$NEW/data":/var/lib/postgresql/data "postgres:$NEW"

sleep 1

sudo chown -R $USER:$USER ..
echo "Exporting New PostgreSQL file..."
docker exec -i postgres-upgrade-testing pg_dump -U postgres $DBname > ../${DBname}_dump_$(date +%Y-%m-%d_%H_%M_%S).sql

cd ..

echo "Done"

docker stop postgres-upgrade-testing
docker rm postgres-upgrade-testing
sudo rm -fr postgres-upgrade-testing

unset OLD NEW DBname SQLFILE
echo "Container Deleted"
