xquery version "1.0";
(: ------------------------------------------------------------------
   POLL - Oppidoc Poll Application

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Converts a questionnaire specification (POST) to a mesh
   Stores the mesh in /db/www/poll/mesh collection
   Stores the questionnaire specification into /db/sites/poll/questionnaires collection

   June 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

import module namespace system = "http://exist-db.org/xquery/system";

declare namespace xdb = "http://exist-db.org/xquery/xmldb";
declare namespace sm = "http://exist-db.org/xquery/securitymanager";
(:declare namespace file="http://exist-db.org/xquery/file";:)
declare namespace request = "http://exist-db.org/xquery/request";
declare namespace transform = "http://exist-db.org/xquery/transform";

import module namespace oppidum = "http://oppidoc.com/oppidum/util" at "../../../oppidum/lib/util.xqm";
import module namespace globals = "http://oppidoc.com/oppidum/globals" at "../../lib/globals.xqm";
import module namespace services = "http://oppidoc.com/ns/services" at "../../lib/services.xqm";

declare option exist:serialize "method=xml media-type=text/xml";

(: we need a DBA user to execute XSLT transformation (!) :)
(: this way it is not stored in the code depot but in the DB :)
(: however you must ensure that REST access to the DB is deactivated and that your database instance
   is not available through XML-RPC to the Java admin client for instance :)
declare variable $local:usecret := fn:doc($globals:settings-uri)//Sudoer/User/text();
declare variable $local:psecret := fn:doc($globals:settings-uri)//Sudoer/Password/text();

(: ======================================================================
   Validates submitted data.
   Returns the first error that prevent Order execution
   ======================================================================
:)
declare function local:validate-submission( $submitted as element() ) as element()? {
  let $check := services:validate('poll', 'poll.questionnaires', $submitted)
  return
    if (local-name($check) eq 'error') then
      $check
    else
      ()
};

(: ======================================================================
   Executes supergrid transformation on a template specification
   Pre-condition: MUST be a user with DBA role to run XSLT transformation
   TODO: tester avec XSLT transfo dans la base (pas besoin de admin ?)
   ======================================================================
:)
declare function local:gen-and-save-form( $name as xs:string, $base-url as xs:string, $spec as element() ) {
  let $col1-uri := '/db/www/poll/mesh'
  let $filename1 := concat($name, '.xhtml')
  let $filename2 := concat($name, '.xml')
  let $sg := concat('file://', system:get-exist-home(), '/webapp/', $globals:parent-dir, '/poll/modules/poll/poll.xsl')
  return
    if (doc-available($sg)) then
      let $data := $spec
      let $params := <parameters>
                       <param name="xslt.base-url" value="{$base-url}"/>
                       <param name="exist:stop-on-warn" value="yes"/>
                       <param name="exist:stop-on-error" value="yes"/>
                     </parameters>
      return
          let $form := transform:transform($data, $sg, $params)
          let $res1 := xdb:store($col1-uri, $filename1, $form)
          let $res2 := xdb:store($globals:questionnaires-uri, $filename2, $spec)
          return
            oppidum:throw-message('INFO', concat('Generated form copied to ', $res1))
    else
      oppidum:throw-error('CUSTOM', concat('Could not locate ', $sg))
};

let $submitted := oppidum:get-data()
let $errors := local:validate-submission($submitted)
return
  if (empty($errors)) then
    let $cmd := request:get-attribute('oppidum.command')
    let $spec := services:unmarshall($submitted)
    return
				(: it seems sm:user-exists cannot be called as a guest :)
        if (exists($local:usecret) and exists($local:psecret) (:and sm:user-exists($local:usecret):)) then 
          <poll>
            {
            system:as-user($local:usecret, $local:psecret, local:gen-and-save-form($spec/Id, $cmd/@base-url, $spec))
            }
          </poll>
        else
          oppidum:throw-error('CUSTOM', 'Please configure poll agent user in application settings')
  else
    $errors
