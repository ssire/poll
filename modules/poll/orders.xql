xquery version "1.0";
(: ------------------------------------------------------------------
   POLL - Oppidoc Poll Application

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Orders CRUD controller

   Pre-requisite:
   - collection /db/sites/poll/forms MUST BE writable for guest

   June 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

declare namespace xdb = "http://exist-db.org/xquery/xmldb";
declare namespace request = "http://exist-db.org/xquery/request";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";
import module namespace poll = "http://oppidoc.com/ns/poll" at "../../lib/poll.xqm";
import module namespace services = "http://oppidoc.com/ns/services" at "../../lib/services.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Creates the $path hierarchy of collections directly below the $base-uri collection.
   The $base-uri collection MUST be available.
   Returns the database URI to the terminal collection whatever the outcome.
   ======================================================================
:)
declare function local:create-collection-lazy ( $base-uri as xs:string, $set as xs:string*, $user as xs:string, $group as xs:string ) as xs:string*
{
  let $exec :=
    for $t at $i in $set
    let $parent := concat($base-uri, '/', string-join($set[position() < $i], '/'))
    let $path := concat($base-uri, '/', string-join($set[position() < $i + 1], '/'))
    return
     if (xdb:collection-available($path)) then
       ()
     else
       if (xdb:collection-available($parent)) then
         if (xdb:create-collection($parent, $t)) then
           xdb:set-collection-permissions($path, $user, $group, util:base-to-integer(0777, 8))
         else
           ()
       else
         ()
  return
    concat($base-uri, '/', string-join($set, '/'))
};

(: ======================================================================
   Validates submitted data.
   Returns the first error that prevent Order execution
   ======================================================================
:)
declare function local:validate-submission( $submitted as element() ) as element()? {
  let $check := services:validate('poll', 'poll.orders', $submitted)
  return
    if (local-name($check) eq 'error') then
      $check
    else
      let $data := services:unmarshall($submitted)
      let $spec-uri := concat($globals:questionnaires-uri, '/', $data/Questionnaire, '.xml')
      return
        if (exists($data/Cancel) or exists($data/Close)) then
          if (fn:collection($globals:forms-uri)//Order[Id = $data/Id/text()]) then
            ()
          else
            oppidum:throw-error('ORDER-NOT-FOUND', $data/Id/text())
        else
          if (not(doc-available($spec-uri))) then
            oppidum:throw-error('QUESTIONNAIRE-NOT-FOUND', $data/Questionnaire/text())
          else if (fn:collection($globals:forms-uri)//Order[Id = $data/Id/text()]) then
            oppidum:throw-error('DUPLICATE-ORDER', $data/Id/text())
          else
            ()
};

(: ======================================================================
   Returns an Order for saving to database
   ======================================================================
:)
declare function local:gen-order-for-writing( $data as element() ) as element() {
  <Order>
    { $data/(Id | Secret | Questionnaire | Variables) }
    <Date>{ current-dateTime() }</Date>
  </Order>
};

(: ======================================================================
   Marks an Order as Closed
   ======================================================================
:)
declare function local:close-order ( $order as element() ) {
  let $legacy := fn:collection($globals:forms-uri)//Order[Id = $order/Id/text()]
  return
    if (not($legacy/Closed)) then (
      update insert <Closed>{ current-dateTime() }</Closed> into $legacy,
      services:report-success('INFO', concat('Order ', $order/Id ,' has been closed') , ())
      )
    else 
      oppidum:throw-error('CUSTOM', concat('Order already closed ', $order/Closed))
};

(: ======================================================================
   Cancel an Order (version that keeps the Order for debug)
   ======================================================================
:)
declare function local:cancel-order ( $order as element() ) {
  let $legacy := fn:collection($globals:forms-uri)//Order[Id = $order/Id/text()]
  return
    if (not($legacy/Cancelled)) then (
      update insert <Cancelled>{ current-dateTime() }</Cancelled> into $legacy,
      services:report-success('INFO', concat('Order ', $order/Id ,' has been cancelled') , ())
      )
    else 
      oppidum:throw-error('CUSTOM', concat('Order already cancelled ', $order/Cancelled))
};

(: ======================================================================
   Deletes an Order
   To be use for rollback immediatly after creation to cancel it 
   (e.G. if notification to end-user failed)
   ======================================================================
:)
declare function local:cancel-order-II ( $order as element() ) {
  let $legacy := fn:collection($globals:forms-uri)//Order[Id = $order/Id/text()]
  let $doc := util:document-name($legacy)
  let $path := util:collection-name($legacy)
  return (
    xdb:remove($path, $doc),
    services:report-success('CANCEL-ORDER-SUCCESS', $order/Id/text(), $order)
    )[last()]
};

(: ======================================================================
   Saves Order in YYYY/MM sub-collection of the questionnaire forms collection
   ======================================================================
:)
declare function local:save-order ( $order as element() ) {
  let $date := string(current-date())
  let $parent-uri := local:create-collection-lazy(
    $globals:forms-uri,
    (string($order/Questionnaire), substring($date, 1, 4), substring($date, 6, 2)),
    'admin',
    'poll'
    )
  let $name := concat($order/Id, '.xml')
  let $path := xdb:store($parent-uri, $name, $order)
  
  return
    if ($path) then
      services:report-success('CREATE-ORDER-SUCCESS', $order/Questionnaire/text(), $order)
    else
      oppidum:throw-error('WRITE-ORDER-FAILURE', $order/Questionnaire/text())
};

(: *** MAIN ENTRY POINT *** :)
let $submitted := oppidum:get-data()
let $errors := local:validate-submission($submitted)
return
  if (empty($errors)) then
    let $order := services:unmarshall($submitted)
    return
      if ($order/Cancel) then
        local:cancel-order($order)
      else if ($order/Close) then
        local:close-order($order)
      else
        local:save-order(local:gen-order-for-writing($order))
  else
    $errors
