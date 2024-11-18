#!/bin/bash

set -e

if [ "$RUN_MIGRATIONS" == "true" ]; then
    echo 'Running initial migration and data loading...'
    python manage.py migrate 
    python manage.py dumpdata --database=sqlite --natural-foreign --natural-primary -e contenttypes -e auth.Permission --indent 4 > datadump.json
    python manage.py loaddata datadump.json
else
    echo 'Migration already completed.'
    python manage.py migrate;
fi

[ -f db.sqlite3 ] && rm -f db.sqlite3

python manage.py runserver 0.0.0.0:8000