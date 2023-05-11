#!/bin/bash

mkdir -p postgres-upgrade-testing
cd postgres-upgrade-testing
OLD='12'
NEW='15'
DBname='testDB'
SQLFILE='./testDB_backup.sql'


docker pull "postgres:$OLD"
docker run -dit --name postgres-upgrade-testing -e POSTGRES_PASSWORD=password -v "$PWD/$OLD/data":/var/lib/postgresql/data "postgres:$OLD"

docker exec -i postgres-upgrade-testing psql -U postgres -c "CREATE DATABASE $DBname"
cat $SQLFILE | docker exec -i postgres-upgrade-testing psql -U postgres -d $DBname

docker stop postgres-upgrade-testing
docker rm postgres-upgrade-testing

docker run --rm -v "$PWD":/var/lib/postgresql "tianon/postgres-upgrade:$OLD-to-$NEW" --link

docker pull "postgres:$NEW"
docker run -dit --name postgres-upgrade-testing -e POSTGRES_PASSWORD=password -v "$PWD/$NEW/data":/var/lib/postgresql/data "postgres:$NEW"

sudo chown -R $USER:$USER ..
docker exec -i postgres-upgrade-testing pg_dump -U postgres $DBname > ../${DBname}_dump_$(date +%Y-%m-%d_%H_%M_%S).sql

cd ..
sudo rm -fr postgres-upgrade-testing

unset OLD NEW DBname SQLFILE
