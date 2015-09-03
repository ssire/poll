xquery version "1.0";
(: ------------------------------------------------------------------
   POLL - Oppidoc Poll application

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Simple service to test service inter-communication

   July 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

declare namespace request = "http://exist-db.org/xquery/request";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace services = "http://oppidoc.com/ns/services" at "../../lib/services.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Loops back submitted data after validation
   For instance can be configured as a test service in a 3rd party application
   to be called with services:post-to-service
   ======================================================================
:)
declare function local:test1 () {
  let $submitted := oppidum:get-data()
  return 
    if ($submitted) then
      let $check := services:validate('poll', 'poll.loopback', $submitted)
      return
        if (local-name($check) eq 'error') then
          $check
        else
          services:report-success('INFO', 'Submission OK', services:unmarshall($submitted))
    else
      oppidum:throw-error('CUSTOM', "You must submit data with POST for this test")
};

local:test1()
