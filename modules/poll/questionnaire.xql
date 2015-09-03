xquery version "1.0";
(: ------------------------------------------------------------------
   POLL - Oppidoc Poll Application

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Generates an Order model to feed to the corresponding questionnaire XTiger template / mesh 
   to generate questionnaire for a given order

   June 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.  
   ------------------------------------------------------------------ :)
declare namespace request = "http://exist-db.org/xquery/request";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";
import module namespace poll = "http://oppidoc.com/ns/poll" at "../../lib/poll.xqm";

let $order-id := request:get-parameter('o', ())
let $test := request:get-parameter-names() = 'test'
return
  if ($order-id) then
    let $order := fn:collection($globals:forms-uri)//Order[Id = $order-id]
    return
      if ($order) then (: sub-order part to generate personalized questionnaire with epilogue :)
        <Order>
          { if ($test) then attribute Skin { 'transform' } else () }
          { $order/Variables }
        </Order>
      else
        oppidum:throw-error('URI-NOT-FOUND', ())
  else if ($test) then (: blank test :)
    <Order Skin="transform"/>
  else
    oppidum:throw-error('CUSTOM', "Missing order identifier")
