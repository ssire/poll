xquery version "1.0";
(: ------------------------------------------------------------------
   Poll - Oppidoc Poll Services

   Author: Stéphane Sire <s.sire@opppidoc.fr>

   Bootstrap script :

   - creates /db/sites/poll/questionnaires
   - creates /db/sites/poll/forms
   - creates xsl-agent (with abcdef password - see also config/settings.xml) 
   - creates poll with poll password

	 Notes
	- /db/sites/poll/forms must be writable by guest since anyone can answer a questionnaire 

   MUST be run with DBA role
    
   July 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
   ------------------------------------------------------------------ :)

declare namespace xdb = "http://exist-db.org/xquery/xmldb";
declare namespace sm = "http://exist-db.org/xquery/securitymanager";

declare option exist:serialize "method=xml media-type=text/xml";

<Bootstrap>
  <p>Begin</p>
  <p>Create collection { xmldb:create-collection('/db/sites/poll', 'forms') }</p>
  <p>Create collection { xmldb:create-collection('/db/sites/poll', 'questionnaires') }</p>
  <p>Set rights on forms collection { xmldb:chmod-collection('/db/sites/poll/forms', util:base-to-integer(0777, 8)) }</p>
  <p>Create xsl-agent account { 
		if (sm:user-exists('xsl-agent')) then
		": user already existing"
		else
			sm:create-account('xsl-agent', 'abcdef', 'dba', ('poll'), 'XSL agent', 'agent user to generate questionnaires') 
		}
	</p>
  <p>Create poll account { 
		if (sm:user-exists('poll')) then
			": user already existing"
		else
			sm:create-account('poll', 'poll', ('guest'), 'poll administrator', 'poll administrator user with access to list of orders') 
		}
	</p>,
  <p>End</p>
</Bootstrap>