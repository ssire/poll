xquery version "1.0";
(: ------------------------------------------------------------------
   POLL - Oppidoc Poll Application

   Creation: Stéphane Sire <s.sire@opppidoc.fr>

   June 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

declare default element namespace "http://www.w3.org/1999/xhtml";
declare namespace site = "http://oppidoc.com/oppidum/site";
declare namespace xt = "http://ns.inria.org/xtiger";

declare namespace request = "http://exist-db.org/xquery/request";
declare namespace xdb = "http://exist-db.org/xquery/xmldb";
declare namespace session = "http://exist-db.org/xquery/session";
import module namespace util="http://exist-db.org/xquery/util";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../oppidum/lib/util.xqm";
import module namespace skin = "http://oppidoc.com/oppidum/skin" at "../oppidum/lib/skin.xqm";
import module namespace epilogue = "http://oppidoc.com/oppidum/epilogue" at "../oppidum/lib/epilogue.xqm";
(:import module namespace partial = "http://oppidoc.com/oppidum/partial" at "lib/partial.xqm";:)

declare variable $site:dico-uri := '/db/www/poll/config/dictionary.xml';

(: ======================================================================
   Trick to use request:get-uri behind a reverse proxy that injects
   /exist/.../poll path into the URL in production
   ======================================================================
:)
declare function local:my-get-uri ( $cmd as element() ) {
  concat($cmd/@base-url, $cmd/@trail, if ($cmd/@verb eq 'custom') then concat('/', $cmd/@action) else ())
};

(: ======================================================================
   Typeswitch function
   -------------------
   Plug all the <site:{module}> functions here and define them below
   ======================================================================
:)
declare function site:branch( $cmd as element(), $source as element(), $view as element()* ) as node()*
{
 typeswitch($source)
 case element(site:skin) return site:skin($cmd, $view)
 case element(site:navigation) return site:navigation($cmd, $view)
 case element(site:error) return site:error($cmd, $view)
 case element(site:message) return site:message($cmd)
 case element(site:login) return site:login($cmd)
 (:case element(site:lang) return site:lang($cmd, $view) :)
 case element(site:field) return site:field($cmd, $source, $view)
 case element(site:conditional) return site:conditional($cmd, $source, $view)
 default return $view/*[local-name(.) = local-name($source)]/*
 (: default treatment to implicitly manage other modules :)
};

(: ======================================================================
   Inserts CSS links and JS scripts to the page
   selection is defined by the current mesh, the optional skin attribute
   of the site:view element, and the site's 'skin.xml' resource
   ======================================================================
:)
declare function site:skin( $cmd as element(), $view as element() ) as node()*
{
  (
  skin:gen-skin('poll', oppidum:get-epilogue($cmd), $view/@skin),
  if (empty($view/site:links)) then () else skin:rewrite-css-link('poll', $view/site:links)
  )
};

(: ======================================================================
   Generates error essages in <site:error>
   ======================================================================
:)
declare function site:error( $cmd as element(), $view as element() ) as node()*
{
  let $resolved := oppidum:render-errors($cmd/@confbase, $cmd/@lang)
  return (
    (:    attribute class { 'active' },  :)
    for $m in $resolved/*[local-name(.) eq 'message'] return <p>{$m/text()}</p>
    )
};

(: ======================================================================
   Generates information messages in <site:message>
   Be careful to call session:invalidate() to clear the flash after logout redirection !
   ======================================================================
:)
declare function site:message( $cmd as element() ) as node()*
{
  let $messages := oppidum:render-messages($cmd/@confbase, $cmd/@lang)
  return
    for $m in $messages
    return (
      (: trick because messages are stored inside session :)
      if ($m/@type = "ACTION-LOGOUT-SUCCESS") then session:invalidate() else (),
      <p>
        {(
        for $a in $m/@*[local-name(.) ne 'type']
        return attribute { concat('data-', local-name($a)) } { string($a) },
        $m/text()
        )}
      </p>
      )
};

(: ======================================================================
   Generates <site:navigation> menu
   ======================================================================
:)
declare function site:navigation( $cmd as element(), $view as element() ) as element()*
{
  <ul class="nav">
  {
  if ($cmd/@trail eq 'about') then
    <li><a class="active" href="{string($cmd/@base-url)}about">About</a></li>
  else
    <li><a href="{string($cmd/@base-url)}about">About</a></li>
  }
  </ul>
};

(: ======================================================================
   Handles <site:login> LOGIN banner
   ======================================================================
:)
declare function site:login( $cmd as element() ) as element()*
{
 let
   $uri := local:my-get-uri($cmd),
   $user := xdb:get-current-user()
 return
   if ($user = 'guest')  then
     if (not(ends-with($uri, '/login'))) then
       <a class="login" href="{$cmd/@base-url}login?url={$uri}">LOGIN</a>
     else
       <span>...</span>
   else
    let $user := if (string-length($user) > 7) then
                   if (substring($user,8,1) eq '-') then
                     substring($user, 1, 7)
                   else
                     concat(substring($user, 1, 7),'...')
                 else
                   $user
    return
      (
      <a href="{$cmd/@base-url}me" style="color:#333;text-decoration:none">{$user}</a>,
      <a class="login" href="{$cmd/@base-url}logout?url={$cmd/@base-url}">LOGOUT</a>
      )
};

(: ======================================================================
   Generates language menu
    - Simple logic so that default langauge is implicit (does not appear in URL)
   ======================================================================
:)
declare function site:lang( $cmd as element(), $view as element() ) as element()*
{
  let $lang := string($cmd/@lang)
  let $qs := request:get-query-string()
  let $uri := local:my-get-uri($cmd)
  return
    <span id="c-curLg">EN</span>
};

(: ======================================================================
   Applies a simple logic to filter conditional source blocks.
   Keeps (/ Removes) the source when all these conditions hold true (logical AND):
   - @avoid does not match current goal (/ matches goal)
   - @meet matches current goal (/ does not match goal)
   - @flag is present in the request parameters  (/ is not present in parameters)
   - @noflag not present in request parameters (/ is present in parameters)
   ======================================================================
:)
declare function site:conditional( $cmd as element(), $source as element(), $view as element()* ) as node()* {
  let $goal := request:get-parameter('goal', 'read')
  let $flags := request:get-parameter-names()
  return
    (: Filters out failing @meet AND @avoid and @noflag AND @flag :)
    if (not(
               (not($source/@meet) or ($source/@meet = $goal))
           and (not($source/@avoid) or not($source/@avoid = $goal))
           and (not($source/@flag) or ($source/@flag = $flags))
           and (not($source/@noflag) or not($source/@noflag = $flags))
        ))
    then
      ()
    else
      for $child in $source/node()
      return
        if ($child instance of element()) then
          (: FIXME: hard-coded 'site:' prefix we should better use namespace-uri
                    - currently limited to site:field :)
          if (starts-with(xs:string(node-name($child)), 'site:field')) then
            site:field($cmd, $child, $view)
          else
            local:render($cmd, $child, $view)
        else
          $child
};

(: ======================================================================
   Forms fields inclusion
   Fields marked as filter="copy" are removed or replaced with a constant
   field when readonly flag is set on the template URL.
   TODO: simplify (no readonly mode, etc.)
   ======================================================================
:)
declare function site:field( $cmd as element(), $source as element(), $view as element()* ) as node()* {
  let $goal := request:get-parameter('goal', 'read')
  return
    if (($source/@avoid = $goal) or ($source/@meet and not($source/@meet = $goal))) then
      ()
    else if ($source[@filter = 'copy']) then
      if ($goal = 'read') then
        if ($source[@signature = 'multitext']) then (: sg <MultiText> :)
          <xt:use types="html" param="class=span a-control" label="{$source/xt:use/@label}"/>
        else if ($source[@signature = 'plain']) then (: sg <Plain> :)
          <xt:use types="constant" label="{$source/xt:use/@label}"/>
        else if ($source/xt:use[@types='input']) then (: sg <Input> :)
          let $media := if (contains($source/xt:use/@param, 'constant_media=')) then concat(';constant_media=', substring-after($source/xt:use/@param, 'constant_media=')) else ''
          return
            <xt:use types="constant" param="class=uneditable-input span a-control{$media}">
              { $source/xt:use/@label }
            </xt:use>
        else if ($source/xt:use[@types='text']) then (: sg <Text> :)
          <xt:use types="constant" param="class=sg-multiline uneditable-input span a-control">
            { $source/xt:use/@label }
          </xt:use>
        else if ($source[@signature = 'richtext']) then (: sg <RichText> :)
          <xt:use types="html" param="class=span a-control" label="{$source/div/xt:repeat/@label}"/>
        else if ($source[@signature = 'append']) then (: sg <Constant> with @Append :)
          <div class="input-append fill">
            <xt:use param="class=uneditable-input fill a-control text-right;" label="{$source/@Tag}" types="constant"></xt:use>
            { $source/div/span }
          </div>
        else
          $source/*
      else
        $source/*
    else
      let $f := $view/site:field[@Key = $source/@Key]
      return
        if ($f) then
          if ($f[@filter = 'no']) then
              $f/(*|text())
          else
            (: we could use @Size but span12 is compatible anywhere in row-fluid :)
            (: FIXME: for types="constant" you must set the correct span :)
            <xt:use localized="1">
              {
              $f/xt:use/(@types|@values|@i18n|@default),
              let $lang := string($cmd/@lang)
              let $ext :=  (
                if ($source/@Filter) then concat('filter=', $source/@Filter) else (), (: FIXME: handle param with pre-existing filter ??? :)
                if ($source/@Required) then 'required=true' else (),
                if ($source/@Placeholder-loc) then concat('placeholder=',site:get-local-string($lang, $source/@Placeholder-loc)) else ()
                )
              return
                if (empty($ext)) then
                  $f/xt:use/@param
                else
                  attribute { 'param'} {
                    if ($f/xt:use/@param) then
                      concat($f/xt:use/@param, ';', string-join($ext, ';'))
                    else
                      string-join($ext, ';')
                  },
              if ($f/xt:use/@label) then $f/xt:use/@label else attribute { 'label' } { $source/@Tag/string() },
              $f/xt:use/text()
              }
            </xt:use>
        else if ($source/@type eq 'var') then
          <span style="color:red">@@{ string($source/@Key) }@@</span>
        else
          (: plain constant field (no id, no appended symbol) :)
          <xt:use types="constant" label="{$source/@Tag}" param="class=uneditable-input span a-control"/>
};

(: ======================================================================
   Recursive rendering function
   ----------------------------
   Copy this function as is inside your epilogue to render a mesh
   ======================================================================
:)
declare function local:render( $cmd as element(), $source as element(), $view as element()* ) as element()
{
  element { node-name($source) }
  {
    $source/@*,
    for $child in $source/node()
    return
      if ($child instance of text()) then
        $child
      else
        (: FIXME: hard-coded 'site:' prefix we should better use namespace-uri :)
        if (starts-with(xs:string(node-name($child)), 'site:')) then
          (
            if (($child/@force) or
                ($view/*[local-name(.) = local-name($child)])) then
                 site:branch($cmd, $child, $view)
            else
              ()
          )
        else if ($child/*) then
          if ($child/@condition) then
          let $go :=
            if (string($child/@condition) = 'has-error') then
              oppidum:has-error()
            else if (string($child/@condition) = 'has-message') then
              oppidum:has-message()
            else if ($view/*[local-name(.) = substring-after($child/@condition, ':')]) then
                true()
            else
              false()
          return
            if ($go) then
              local:render($cmd, $child, $view)
            else
              ()
        else
           local:render($cmd, $child, $view)
        else
         $child
  }
};

(: ======================================================================
   Returns a localized string for a given $lang and $key
   ======================================================================
:)
declare function site:get-local-string( $lang as xs:string, $key as xs:string ) as xs:string {
  let $res := fn:doc($site:dico-uri)/site:Dictionary/site:Translations[@lang = $lang]/site:Translation[@key = $key]/text()
  return
    if ($res) then
      $res
    else
      concat('missing [', $key, ', lang="', $lang, '"]')
};

(: ======================================================================
   Typeswitch function
   -------------------
   Filters loc and {name}-loc attributes to localize content using a dictionary
   $dict is a dictionary element with a @lang attribute
   ======================================================================
:)
declare function site:localize( $dict as element()?, $source as element(), $sticky as xs:boolean ) as node()*
{
  if ($source/@localized) then (: optimization mainly for search results tables :)
    $source
  else
  element { node-name($source) }
  {
    if ($sticky) then $source/@loc else (),
    for $attr in $source/@*[local-name(.) ne 'loc']
    let $name := local-name($attr)
    return
      if (ends-with($name, '-loc')) then
        let $key := string($attr)
        let $t := $dict/site:Translation[@key = $key]/text()
        return attribute { substring-before($name, '-loc') } { if ($t) then $t else concat('missing [', $key,', lang="', string($dict/@lang), '"]') }
      else if ($source/@*[local-name(.) = concat($name, '-loc')]) then (: skip it :)
        ()
      else
        $attr,
    for $child in $source/node()
    return
      if ($child instance of text()) then
        if ($source/@loc) then
          let $t := $dict/site:Translation[@key = string($source/@loc)]/text()
          return
            if ($t) then
              $t
            else (
              <span style="color:red">
              {
              concat('missing [', string($source/@loc), ', lang="', string($dict/@lang), '"]')
              }
              </span>
            )
        else
          $child
      else if ($child instance of element()) then
        site:localize($dict, $child, $sticky)
      else
        $child (: FIXME: should we care about other stuff like coments ? :)
  }
};

(: ======================================================================
   Epilogue entry point
   --------------------
   Copy this code as is inside your epilogue
   ======================================================================
:)
let $mesh := epilogue:finalize()
let $cmd := request:get-attribute('oppidum.command')
let $sticky := false()
let $lang := $cmd/@lang
let $dico := fn:doc($site:dico-uri)/site:Dictionary/site:Translations[@lang = $lang]
let $isa_tpl := contains($cmd/@trail,"questionnaires/") or ends-with($cmd/@trail,"/template")
return
  if ($mesh) then
    let $type := if ($isa_tpl) then
                   "application/xhtml+xml"
                 else
                   "text/html"
    let $page := local:render($cmd, $mesh, oppidum:get-data())
    return (
      util:declare-option("exist:serialize", concat("method=html5 media-type=", $type, " encoding=utf-8 indent=yes")),
      $page
      (:site:localize($dico, $page, $sticky):)
      )
  else
    request:get-data()
    (:site:localize($dico, request:get-data(), $sticky):)
