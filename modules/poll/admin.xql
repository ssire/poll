xquery version "1.0";
(: ------------------------------------------------------------------
   POLL - Oppidoc Poll Application

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Simple admin view to monitor orders

   June 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.  
   ------------------------------------------------------------------ :)

declare namespace request = "http://exist-db.org/xquery/request";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";
import module namespace poll = "http://oppidoc.com/ns/poll" at "../../lib/poll.xqm";

declare function local:gen-orders-for-questionnaire( $spec as element() ) as element()* {
  let $col-uri := concat($globals:forms-uri, '/', $spec/Id)
  return
    for $o in fn:collection($col-uri)//Order
    order by $o/Date
    return 
      <Order col="{$col-uri}">{ $o/( Id | Date | Cancel | Closed | Submitted ) }</Order>
};

<Admin>
  {
  for $spec in fn:collection($globals:questionnaires-uri)//Poll
  return
    <Questionnaire>
      { $spec/Title }
      { local:gen-orders-for-questionnaire($spec) }
    </Questionnaire>
  }
</Admin>
