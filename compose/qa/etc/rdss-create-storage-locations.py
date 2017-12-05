#!/bin/env python

"""This script aims to create two Transfer Storage locations in the
Archivematica storage service if they don't already exist. These relate to the
"automated workflow" and the "interactive workflow" that are used in the RDSS
deployment.

It first lists the existing Locations defined in the Storage Service via the
API. It checks to see if any of them have the same path as the two locations we
wish to add - `/home/automated` and `/home/interactive`.

If either of the two locations do not exist, it creates them. It first obtains
the resource URIs for the Pipeline and Space that the new locations will be
added to using the Storage Service API. It assumes that there will only be one
Pipeline and Space, since this is what is expected in the RDSS deployment.

Having identified the URIs for the pipeline and space, it then uses the API to
create the required locations."""

import requests

# Iterate through all the existing locations and determine if the "automated"
# and "interactive" Transfer Source locations already exist

automated_exists = False
interactive_exists = False

r = requests.get(
    'http://localhost:8000/api/v2/location/',
    headers={'Authorization': 'ApiKey test:test'}
)

for loc in r.json()['objects']:
    if loc['path'] == '/home/automated':
        automated_exists = True
    if loc['path'] == '/home/interactive':
        interactive_exists = True

if not automated_exists or not interactive_exists:
    # Get the URI of the pipeline. In RDSS we only have one.
    pipeline_uri = requests.get(
            'http://localhost:8000/api/v2/pipeline/',
            headers={
                'Authorization': 'ApiKey test:test',
                'Content-Type': 'application/json'
            }
        ).json()['objects'][0]['resource_uri']

    # Get the URI of the space. In RDSS we only have one.
    space_uri = requests.get(
            'http://localhost:8000/api/v2/space/',
            headers={
                'Authorization': 'ApiKey test:test',
                'Content-Type': 'application/json'
            }
        ).json()['objects'][0]['resource_uri']

    if not automated_exists:
        # Location for automated workflow doesn't exist, create it
        r = requests.post(
            'http://localhost:8000/api/v2/location/',
            headers={'Authorization': 'ApiKey test:test'},
            json={
                'pipeline': [pipeline_uri],
                'purpose': 'TS',
                'relative_path': 'home/automated',
                'description': 'automated workflow',
                'space': space_uri
            }
        )
        if r.ok:
            print "Location for automated workflow created."
        else:
            print "%s %s" % (r.status_code, r.reason)
            print r.text
    else:
        print "Location for automated workflow already exists."

    if not interactive_exists:
        # Location for interactive workflow doesn't exist, create it
        r = requests.post(
            'http://localhost:8000/api/v2/location/',
            headers={'Authorization': 'ApiKey test:test'},
            json={
                'pipeline': [pipeline_uri],
                'purpose': 'TS',
                'relative_path': 'home/interactive',
                'description': 'interactive workflow',
                'space': space_uri
            }
        )
        if r.ok:
            print "Location for interactive workflow created."
        else:
            print "%s %s" % (r.status_code, r.reason)
            print r.text
    else:
        print "Location for interactive workflow already exists."

else:
    print "Locations for automated and interactive workflows already exist."
