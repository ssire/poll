xquery version "1.0";
(: ------------------------------------------------------------------
   POLL - Oppidoc Poll Application

   Creation: Stéphane Sire <s.sire@opppidoc.fr>

   Shared utilities

   July 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

module namespace poll = "http://oppidoc.com/ns/poll";

declare namespace request = "http://exist-db.org/xquery/request";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";

(: ======================================================================
   Converts edition-oriented tag names (i.e. Likert_XXX tag) towards 
   storage-oriented tag names (i.e. RatingScaleRef For="XXX")

   Benefit of using edition-oriented tag names is to simplify questionnaires 
   reengineering to change question order or add or remove questions 
   w/o requiring to migrate database content
   ======================================================================
:)
declare function poll:genPollDataForWriting( $nodes as item()* ) as item()* {
  for $node in $nodes
  return
    typeswitch($node)
      case text()
        return $node
      case attribute()
        return $node
      case element() return
        if (starts-with(local-name($node), 'Likert_')) then
          let $suffix := substring-after( local-name($node), 'Likert_')
          return
            element RatingScaleRef
              {
              attribute For { $suffix },
              $node/text()
              }
        else
          element { node-name($node) }
            { poll:genPollDataForWriting($node/(attribute()|node())) }
      default return $node
};

(: ======================================================================
   Reverse of local:encodePollData
   ======================================================================
:)
declare function poll:genPollDataForEditing ( $nodes as item()* ) as item()* {
  for $node in $nodes
  return
    typeswitch($node)
      case text()
        return $node
      case attribute()
        return $node
      case element() return
        if ($node/@For) then
          let $suffix := string($node/@For)
          return
            element { concat('Likert_', $suffix) }
              {
              $node/text()
              }
        else
          element { node-name($node) }
            { poll:genPollDataForEditing($node/(attribute()|node())) }
      default return $node
};

(: ======================================================================
   Returns the order in the command or raises an error
   The Order Id MUST be the command target
   ======================================================================
:)
declare function poll:get-order ( ) as element()? {
  let $cmd := request:get-attribute('oppidum.command')
  let $order-id := $cmd/resource/@name
  let $order := fn:collection($globals:forms-uri)//Order[Id = $order-id]
  return
    if ($order) then
      $order
    else
      oppidum:throw-error('ORDER-NOT-FOUND', $order-id)
};

(: ======================================================================
   Returns true if all the Bindings in the questionnaire specification
   hold true, false otherwise
   Works with Flat questionnaire model where answers are tags at 1st level
   Currently limited to ONE Recommended binding
   ======================================================================
:)
declare function poll:check-answers( $name as xs:string, $answers as element() ) as xs:boolean {
  let $spec := fn:collection($globals:questionnaires-uri)//Poll[Id eq $name]
  return
    if ($spec) then
      count(
        for $t in tokenize($spec/Bindings/Recommended/@Keys, ' ')
        let $key := 
          if ($spec/Bindings/Recommended/@Prefix) then 
            concat($spec/Bindings/Recommended/@Prefix, normalize-space($t))
          else
            normalize-space($t)
        return
          if ($answers/*[local-name(.) eq $key][. ne '']) then
            ()
          else
            1
       ) = 0
    else
      true()
};

(: ======================================================================
   Tests the user has at least answered to one question
   TODO: store XPath condition into Questionnaire spec and evaluate it
   when available to handle more complex logics ?
   ======================================================================
:)
declare function poll:check-no-answer( $name as xs:string, $answers as element() ) as xs:boolean {
  count($answers//*[. ne '']) eq 0
};

