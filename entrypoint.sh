#!/bin/bash

while ! nc -z postgres 5432 ;
do
	echo "sleeping"
	sleep 1
done
echo "Connected!"


mix ecto.create && mix ecto.migrate
mix gitlab_data.load_clouds
mix gitlab_data.load_projects
mix phoenix.server
