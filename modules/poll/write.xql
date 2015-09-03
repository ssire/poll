xquery version "1.0";
(: ------------------------------------------------------------------
   POLL - Oppidoc Poll Application

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Saves answers to a questionnaire

   Calls web hook if one is defined in /db/sites/questionnaires/:name

   June 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.  
   ------------------------------------------------------------------ :)

declare namespace request = "http://exist-db.org/xquery/request";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";
import module namespace poll = "http://oppidoc.com/ns/poll" at "../../lib/poll.xqm";
import module namespace services = "http://oppidoc.com/ns/services" at "../../lib/services.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: ======================================================================
   Writes answers into database
   ======================================================================
:)
declare function local:save-answers( $order as element(), $answers as element() ) {
  if ($order/Answers) then
    update replace $order/Answers with $answers
  else
    update insert $answers into $order
};

(: ======================================================================
   Utility to generate Order model to submit back to client application
   ======================================================================
:)
declare function local:gen-order-for-submitting( $order as element(), $answers as element() ) as element() {
  <Order>
    { $order/(Id | Secret) }
    { $answers }
  </Order>
};

(: ======================================================================
   Executes optional Hook associated with the Questionnaire referred in the Order
   Returns the empty sequence or an error
   ======================================================================
:)
declare function local:hook( $order as element(), $answers as element() ) as element()? {
  let $spec-uri := concat($globals:questionnaires-uri, '/', $order/Questionnaire, '.xml')
  return
    if (not(doc-available($spec-uri))) then
      oppidum:throw-error('QUESTIONNAIRE-NOT-FOUND', $order/Questionnaire/text())
    else if (fn:doc($spec-uri)//Hook) then
      let $hook := fn:doc($spec-uri)//Hook
      let $address := string($hook)
      let $payload := local:gen-order-for-submitting($order, $answers)
      let $res := services:post-to-address($address, $payload, ("200", "201", "202"), string($hook/@Name))
      return
        if (local-name($res) eq 'error') then
          $res
        else
          ()
    else (: no hook :)
      ()
};

let $order := poll:get-order()
let $data := oppidum:get-data()
return
  if (local-name($order) eq 'Order') then
    if (empty($order/Submitted) and empty($order/Closed) and empty($order/Cancelled)) then
      let $submitted :=  <Answers LastModification="{ current-dateTime() }">{ poll:genPollDataForWriting($data/*) }</Answers>
      let $save := local:save-answers($order, $submitted)
      return
        if (request:get-parameter('_confirmed', '0') eq '0') then (: Pre-Submission to confirm, AXEL-FORMS 'save' command protocol :)
          if (poll:check-no-answer($order/Questionnaire/text(), $data)) then
            oppidum:throw-error('POLL-EMPTY-SUBMISSION', ())
          else if (poll:check-answers($order/Questionnaire/text(), $data)) then
            oppidum:throw-message('POLL-CONFIRM-FULL-SUBMISSION', ())
          else
            oppidum:throw-message('POLL-CONFIRM-PARTIAL-SUBMISSION', ())
        else (: Confirmed submission, AXEL-FORMS 'save' command protocol :)
          let $hook := local:hook($order, $submitted)
          return
            if ($hook) then (: Ajax response : immediate error :)
              $hook
            else (: redirection: flash message :)
              let $msg := oppidum:add-message('ANSWERS-SUBMITTED', (), true())
              let $redirect := concat('../forms/', $order/Id)
              return (
                update insert <Submitted>{ current-dateTime() }</Submitted> into $order,
                response:set-status-code(201),
                response:set-header('Location', $redirect),
                $msg
                )
    else
      oppidum:throw-error('FORM-WRITE-FORBIDDEN', ())
  else
    $order (: error message :)

