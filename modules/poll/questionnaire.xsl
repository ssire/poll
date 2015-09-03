<?xml version="1.0" encoding="UTF-8"?>

<!-- POLL - Oppidoc Poll Application

     Author: Stéphane Sire <s.sire@opppidoc.fr>

     Transforms an Order into a view suitable for inclusion inside a questionnaire template

     You can include a @Skin attribute on the Order root element to generate a skin,
     Use Skin="transform" to directly transform the XTiger template into the browser for test purpose

     June 2015 - (c) Copyright 2015 Oppidoc SARL. All Rights Reserved.
  -->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:site="http://oppidoc.com/oppidum/site"
  xmlns="http://www.w3.org/1999/xhtml">

  <xsl:output method="xml" media-type="text/html" omit-xml-declaration="yes" indent="yes"/>

  <xsl:param name="xslt.base-url">/</xsl:param>

  <xsl:template match="/">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <!-- FIXME: currently there is no way to tell epilogue to stop processing the output (!) -->
  <xsl:template match="error">
    <site:view>
    </site:view>
  </xsl:template>

  <xsl:template match="Order">
    <site:view>
      <xsl:apply-templates select="@Skin"/>
      <xsl:apply-templates select="//Variable"/>
    </site:view>
  </xsl:template>

  <!-- Used to simulate the template w/o Order with the ?test parameter -->
  <xsl:template match="@Skin">
    <xsl:attribute name='skin'><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <!-- Variables rendering for injection into epilogue.xql -->
  <xsl:template match="Variable">
    <site:field Key="{@Key}" filter="no">
      <span><xsl:value-of select="."/></span>
    </site:field>
  </xsl:template>
  
  <!-- Variables rendering for injection into epilogue.xql 
       Default text entry
       -->
  <xsl:template match="Variable[@Type = 'entry']">
    <site:field Key="{@Key}" filter="no"><xsl:value-of select="."/></site:field>
  </xsl:template>
</xsl:stylesheet>
  
