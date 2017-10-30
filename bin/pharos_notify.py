## Simple helper program is designed to curl private Pharos API endpoints
# in order to trigger email notifications about failed or stuck repository ingests.
# It requires a post request. It takes four inputs as params:
# - url : API endpoint or host
# - time: git
# - API User, uses default PHAROS_API_USER from env if empty
# - Secret token, uses default PHAROS_API_KEY from env if empty
# API endpoints:
# - notify_of_failed_fixity in the premis events controller
# - notify_of_successful_restoration in the work items controller.
# Both of those can take a :since parameter but default to 24 hours if one hasn't been provided and that's what the cron job should default to. There is no option, at least as of now, to toggle those notifications on or off but I could do that at a later date. I don't think the admins know yet but we did tell them about the alerts page, which they also have access to, and which also aggregates information about failed fixity checks.so they do have some way to check on those things already.

import requests
import os
import logging

logging.basicConfig(format='%(asctime)s %(message)s', level=logging.INFO)

PHAROS_API_USER = os.getenv('PHAROS_API_USER')
PHAROS_API_KEY = os.getenv('PHAROS_API_TOKEN')

PHAROS_HOST = os.getenv('PHAROS_HOST')
PHAROS_URL = { 'failed_fixity' : 'https://' + PHAROS_HOST + '/api/v2/notifications/failed_fixity',
               'successful_restore': 'https://' + PHAROS_HOST + '/api/v2/notifications/successful_restoration'}

headers = { 'X-PHAROS-API-USER': PHAROS_API_USER,
            'X-PHAROS-API-KEY': PHAROS_API_KEY,
            'Content-Type': 'application/json',
            'Accept' : 'application/json'}

r_fixity = requests.get(PHAROS_URL['failed_fixity'], headers=headers)
r_restore = requests.get(PHAROS_URL['successful_restore'],headers=headers)

logging.info('%s: %s %s', 'Failed Fixity Notification', r_fixity.status_code, r_fixity.text)
logging.info('%s: %s %s', 'Successful Restore Notification', r_restore.status_code, r_restore.text)
