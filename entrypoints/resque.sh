#!/bin/bash

if [ ! -f config/database.yml ]; then
    cp config/database.yml.sample config/database.yml
fi