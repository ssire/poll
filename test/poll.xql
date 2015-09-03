xquery version "1.0";
(: ------------------------------------------------------------------
   Poll - Oppidoc Poll Services

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Test file for lib/poll.xqm

   July 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

declare namespace request = "http://exist-db.org/xquery/request";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace services = "http://oppidoc.com/ns/services" at "../lib/services.xqm";
import module namespace poll = "http://oppidoc.com/ns/poll" at "../lib/poll.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Tests answers checker
   ======================================================================
:)
declare function local:test1 () {
  let $answers := 
    <Answers>
      <Suggestions>
        <Text>Add a visit to a park</Text>
      </Suggestions>
    </Answers>
  return
    poll:check-answers('sample', $answers)
};

<Results>
  { local:test1() }
</Results>