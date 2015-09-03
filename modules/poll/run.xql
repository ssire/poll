xquery version "1.0";
(: ------------------------------------------------------------------
   POLL - Oppidoc Poll Application

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Generates data model for form editing page for a given order 

   June 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.  
   ------------------------------------------------------------------ :)

declare namespace request = "http://exist-db.org/xquery/request";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";
import module namespace poll = "http://oppidoc.com/ns/poll" at "../../lib/poll.xqm";

declare function local:gen-date( $date as element()? ) as element()? {
  if ($date) then 
    element { local-name($date) }
      {
      concat(substring($date,9,2), '/', substring($date,6,2), '/', substring($date,1,4))
      }
  else
    ()
};

let $order := poll:get-order()
return
  if (local-name($order) eq 'Order') then
    let $spec := fn:collection($globals:questionnaires-uri)//Poll[Id eq $order/Questionnaire]
    let $submit := empty($order/Closed) and empty($order/Cancelled) and empty($order/Submitted)
    return
      <Run>
        { $spec/Title }
        <Order>
          { 
          $order/Id,
          $order/Questionnaire,
          local:gen-date($order/Date),
          local:gen-date($order/Closed),
          local:gen-date($order/Cancelled),
          local:gen-date($order/Submitted)
          }
        </Order>
        { if ($submit) then <Submit/> else () }
      </Run>
  else
    $order
