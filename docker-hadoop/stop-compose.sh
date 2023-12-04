#!/bin/bash

# Call with -v to remove volumes
# https://docs.docker.com/compose/migrate
docker-compose down $@  || docker compose down $@
