<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exslt="http://exslt.org/common" version="1.0" extension-element-prefixes="exslt">
  <xsl:output omit-xml-declaration="yes" indent="no"/>
  <xsl:template match="/">
    <xsl:for-each select="/">
      <xsl:variable select="document('Localization.xml')" name="localization"/>
      <xsl:for-each select="//recipe[@craft_area]">
        <xsl:sort order="ascending" data-type="text" select="@craft_area"/>
        <xsl:sort order="ascending" data-type="text" select="@name"/>
        <xsl:variable select="@name" name="name"/>
        <xsl:variable select="@craft_area" name="area"/>
        <xsl:variable select="$localization/records/record[Key/text()=$area]/English/text()" name="translation"/>
        <xsl:variable select="$localization/records/record[Key/text()=concat($name,'Desc')]/English/text()" name="desc"/>
        <xsl:choose>
          <xsl:when test="boolean($desc) and not(contains($desc,$translation))">
            <xsl:text>MISSING </xsl:text>
            <xsl:call-template name="value-of-template">
              <xsl:with-param name="select" select="$translation"/>
            </xsl:call-template>
            <xsl:text>: </xsl:text>
            <xsl:call-template name="value-of-template">
              <xsl:with-param name="select" select="$localization/records/record[Key/text()=$name]/English/text()"/>
            </xsl:call-template>
            <xsl:text> [</xsl:text>
            <xsl:call-template name="value-of-template">
              <xsl:with-param name="select" select="@name"/>
            </xsl:call-template>
            <xsl:text>] </xsl:text>
            <xsl:call-template name="value-of-template">
              <xsl:with-param name="select" select="$desc"/>
            </xsl:call-template>
            <xsl:value-of select="'&#10;'"/>
          </xsl:when>
          <xsl:when test="not($desc)">
            <xsl:text>NO DESC </xsl:text>
            <xsl:call-template name="value-of-template">
              <xsl:with-param name="select" select="$translation"/>
            </xsl:call-template>
            <xsl:text>: </xsl:text>
            <xsl:call-template name="value-of-template">
              <xsl:with-param name="select" select="$localization/records/record[Key/text()=$name]/English/text()"/>
            </xsl:call-template>
            <xsl:text> [</xsl:text>
            <xsl:call-template name="value-of-template">
              <xsl:with-param name="select" select="@name"/>
            </xsl:call-template>
            <xsl:text>] </xsl:text>
            <xsl:value-of select="'&#10;'"/>
          </xsl:when>
        </xsl:choose>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>
  <xsl:template name="value-of-template">
    <xsl:param name="select"/>
    <xsl:value-of select="$select"/>
    <xsl:for-each select="exslt:node-set($select)[position()&gt;1]">
      <xsl:value-of select="'&#10;'"/>
      <xsl:value-of select="."/>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
