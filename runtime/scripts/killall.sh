#!/bin/bash

pkill -f worker.py
pkill -f datastream
pkill -f discovery_server
pkill -f filereader_server
pkill -f worker.sh
