<?xml version="1.0" encoding="UTF-8"?>

<!-- POLL - Oppidoc Poll Application

     Author: Stéphane Sire <s.sire@opppidoc.fr>

     Transforms a list of Questionnaires and their Orders into a list of clickable links
     Access should be limited to authorized user

     June 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
  -->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:param name="xslt.base-url">/</xsl:param>

  <xsl:template match="/Admin">
    <site:view>
      <site:title><h1>Administration</h1></site:title>
      <site:content>
        <xsl:apply-templates select="Questionnaire"/>
      </site:content>
    </site:view>
  </xsl:template>

  <xsl:template match="Questionnaire">
    <h2><xsl:value-of select="Title"/></h2>
    <ul>
      <xsl:apply-templates select="Order"/>
    </ul>
  </xsl:template>

  <xsl:template match="Order">
    <li><a href="forms/{Id}"><xsl:value-of select="Id"/></a> of <xsl:value-of select="substring(Date, 1, 10)"/> at <xsl:value-of select="substring(Date, 12, 8)"/><xsl:apply-templates select="Closed|Cancelled|Submitted"/></li>
  </xsl:template>

  <xsl:template match="Closed|Cancelled|Submitted"><xsl:text>, </xsl:text><xsl:value-of select="local-name(.)"/> (<xsl:value-of select="substring-before(.,'T')"/>)
  </xsl:template>
</xsl:stylesheet>

