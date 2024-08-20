#!/bin/bash

pgrep -f dummy_process.py | xargs -r kill 9
