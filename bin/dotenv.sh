#!/bin/bash
# Loads .env into environment.

export $(cat ../.env | sed -e /^$/d -e /^#/d | xargs)

