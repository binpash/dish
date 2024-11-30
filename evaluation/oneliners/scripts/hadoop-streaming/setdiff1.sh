#!/bin/bash
cat $1 | cut -d ' ' -f 1 | tr [:lower:] [:upper:]
