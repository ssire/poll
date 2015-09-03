xquery version "1.0";
(: ------------------------------------------------------------------
   POLL - Oppidoc Poll Application

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Returns previous answers to a given Order questionnaire
   in a format suitable for editing

   June 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.  
   ------------------------------------------------------------------ :)

declare namespace request = "http://exist-db.org/xquery/request";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";
import module namespace poll = "http://oppidoc.com/ns/poll" at "../../lib/poll.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

let $order := poll:get-order()
return
  if (local-name($order) eq 'Order') then
    if ($order/Answers) then
      poll:genPollDataForEditing($order/Answers)
      (:$order/Answers:)
    else
      <Answers/>
  else
    $order
