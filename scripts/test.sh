#!/bin/bash
# ---
# Usage: 
# - loopback test              : ./test.sh
# - questionnaire updload test : ./test.sh questionnaire
# - order upload test          : ./test.sh create
# - order cancel test          : ./test.sh cancel
# - order close test          : ./test.sh close

PORT=9191
PARENT="projects"
TARGET=$1

if [ -z "$TARGET" ]; then
  curl "http://localhost:{$PORT}/exist/{$PARENT}/poll/loopback" -H "Content-Type: application/xml" --data $"@../samples/order1.xml"
fi
if [ "${TARGET}" = 'questionnaire' ]; then
  curl "http://localhost:{$PORT}/exist/{$PARENT}/poll/questionnaires" -H "Content-Type: application/xml" --data $"@../samples/questionnaire1.xml"
fi
if [ "${TARGET}" = 'create' ]; then
  curl "http://localhost:{$PORT}/exist/{$PARENT}/poll/orders" -H "Content-Type: application/xml" --data $"@../samples/order1.xml"
fi
if [ "${TARGET}" = 'cancel' ]; then
  curl "http://localhost:{$PORT}/exist/{$PARENT}/poll/orders" -H "Content-Type: application/xml" --data $"@../samples/order2.xml"
fi
if [ "${TARGET}" = 'close' ]; then
  curl "http://localhost:{$PORT}/exist/{$PARENT}/poll/orders" -H "Content-Type: application/xml" --data $"@../samples/order3.xml"
fi
