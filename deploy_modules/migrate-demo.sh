#!/bin/bash

# Deploy module: demo migration.

t drush $1 -- mar
t drush $1 -- mi --group=demo --update
