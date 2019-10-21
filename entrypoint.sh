#!/bin/bash

while ! nc -z $DB_HOST 5432 ;
do
	echo "sleeping"
	sleep 1
done
sleep 5
echo "Connected!"

mix ecto.create || true
mix ecto.migrate
mix gitlab_data.load_clouds
mix gitlab_data.load_projects
mix phoenix.server
