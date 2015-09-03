<?xml version="1.0" encoding="UTF-8"?>

<!-- POLL - Oppidoc Poll Application

     Author: Stéphane Sire <s.sire@opppidoc.fr>

     Transforms a Run Order into a view configured to load and transform the corresponding 
     questionnaire template.
     
     TODO: 
     - read hint message from Questionnaire specification

     June 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
  -->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:param name="xslt.base-url">/</xsl:param>

  <!-- si Order @Test rajouter une skin 'simulate' -->
  <xsl:template match="/">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="error">
    <site:view>
      <site:title><h1>Not found</h1></site:title>
    </site:view>
  </xsl:template>

  <xsl:template match="Run">
    <site:view skin="transform">
      <site:title><h1><xsl:value-of select="Title"/></h1></site:title>
      <site:content>
        <noscript><p class="text-error">You must activate Javascript in your browser to answer this questionnaire !</p></noscript>
        <form action="" onsubmit="return false;">
          <xsl:apply-templates select="Submit|Order/Closed|Order/Submitted|Order/Cancelled" mode="explain"/>
          <div id="form-editor"
               data-template="../questionnaires/{Order/Questionnaire}?o={Order/Id}"
               data-src="../answers/{Order/Id}">
          </div>
          <xsl:apply-templates select="Submit"/>
        </form>
      </site:content>
    </site:view>
  </xsl:template>

  <!-- Cancelled questionnaire should not have been notified by e-mail, so nobody should reach it -->
  <xsl:template match="Cancelled" mode="explain">
    <p class="ended">This questionnaire has been cancelled on <xsl:value-of select="."/>. You cannot Submit it.</p>
  </xsl:template>

  <xsl:template match="Closed" mode="explain">
    <p class="ended">You received an invitation to answer this questionnaire on <xsl:value-of select="../Date"/> but it has been closed on <xsl:value-of select="."/> on behalf of the organizer. You cannot Submit it anymore. Sorry for the inconvenience.</p>
  </xsl:template>
  
	<!-- TODO: parameterize deactivation delay -->
  <xsl:template match="Submitted" mode="explain">
    <p class="done">This questionnaire has been answered and submitted on <xsl:value-of select="."/>. Since you cannot answer twice there is no Submit button. This URL will be deactivated in a few days.</p>
  </xsl:template>

	<!-- TODO: allow custom message read from XML questionnaire specification -->
  <xsl:template match="Submit" mode="explain">
    <p class="ready">Please read carefully and answer the following questions. Do not forget to click on the <b>Submit</b> button at the bottom of the page when you have finished.</p>
  </xsl:template>

  <xsl:template match="Submit">
    <div>
      <p class="text-center">
        <button data-command="save" data-target="form-editor" class="btn btn-primary">Submit</button>
      </p>
    </div>
  </xsl:template>

</xsl:stylesheet>

