#!/usr/bin/python
## Simple helper program is designed to curl private Pharos API endpoints
# in order to trigger email notifications about failed or stuck repository
# ingests.
# It requires a post request. It takes four inputs as params:
# - url : API endpoint or host
# - time: git
# - API User, uses default PHAROS_API_USER from env if empty
# - Secret token, uses default PHAROS_API_KEY from env if empty
# API endpoints:
# - notify_of_failed_fixity in the premis events controller
# - notify_of_successful_restoration in the work items controller.
# - snapshot: generates a snapshot of institutional total deposits
# The failed_fixity and successful_restoration endpoints can take a :since
# parameter but default to 24 hours if one hasn't been provided and that's
# what the cron job should default to. There is no option, at least as of now,
# to toggle those notifications on or off.

import os
import logging
import argparse
import requests

class EnvDefault(argparse.Action):
    def __init__(self, envvar, required=True, default=None, **kwargs):
        if not default and envvar:
            if envvar in os.environ:
                default = os.environ[envvar]
        if required and default:
            required = False
        super(EnvDefault, self).__init__(default=default, required=required,
                                         **kwargs)

    def __call__(self, parser, namespace, values, option_string=None):
        setattr(namespace, self.dest, values)

parser = argparse.ArgumentParser(description="Helper script to call Pharos API \
        endpoints to trigger notifications.")
parser.add_argument('-u', '--user', \
	action=EnvDefault, envvar='PHAROS_API_USER', \
        help='API User for Pharos. Needs admin privileges.')
parser.add_argument('-k', '--key', \
	action=EnvDefault, envvar='PHAROS_API_KEY', \
        help='Pharos API key (default from env var)')
parser.add_argument('-H', '--host', metavar='PHAROS_HOST', \
	action=EnvDefault, envvar='PHAROS_HOST', \
        help='Host to connect to.')
parser.add_argument('-o', '--opt', nargs='+', \
        choices=['fixity', 'restore', 'snapshot', 'deletion'], \
        default=['fixity', 'restore'], \
        help='Notification options (fixity, restore, snapshot, deletion [defaults to fixity,restore])')

args = parser.parse_args()

logging.basicConfig(format='%(asctime)s %(message)s', level=logging.INFO)
headers = {'X-PHAROS-API-USER': args.user, \
        'X-PHAROS-API-KEY': args.key, \
        'Content-Type': 'application/json', \
        'Accept' : 'application/json'}

for option in args.opt:
    if option == 'fixity':
        OPT_ENDPOINT = '/notifications/failed_fixity'
    elif option == 'restore':
        OPT_ENDPOINT = '/notifications/successful_restoration'
    elif option == 'snapshot':
        OPT_ENDPOINT = '/group_snapshot'
    elif option == 'deletion':
        OPT_ENDPOINT = '/notifications/deletion'

    PHAROS_URL = 'https://' + args.host + '/api/v2' + OPT_ENDPOINT
    r_option = requests.get(PHAROS_URL, headers=headers)
    logging.info('%s: %s %s', OPT_ENDPOINT + ' Status: ', \
            r_option.status_code, r_option.text)
