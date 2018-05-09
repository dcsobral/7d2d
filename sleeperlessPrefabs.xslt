<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exslt="http://exslt.org/common" version="1.0" extension-element-prefixes="exslt">
  <xsl:output omit-xml-declaration="yes" indent="no"/>
  <xsl:template match="/">
    <xsl:for-each select="//prefab_rule[not(@name='detailFillerGroup' or @name='traderGroup')]/prefab[@name]">
      <xsl:variable select="document(concat('../Prefabs/',@name,'.xml'))" name="prefab"/>
      <xsl:choose>
        <xsl:when test="$prefab/prefab">
          <xsl:choose>
            <xsl:when test="not($prefab//property[@name='SleeperVolumeStart'] and $prefab//property[@name='SleeperVolumeSize'] and $prefab//property[@name='SleeperVolumeGroup'])">
              <xsl:call-template name="value-of-template">
                <xsl:with-param name="select" select="@name"/>
              </xsl:call-template>
              <xsl:text> (</xsl:text>
              <xsl:call-template name="value-of-template">
                <xsl:with-param name="select" select="../@name"/>
              </xsl:call-template>
              <xsl:text>)</xsl:text>
              <xsl:choose>
                <xsl:when test="$prefab//property[starts-with(@name,'Sleeper')]">
                  <xsl:text> has only </xsl:text>
                  <xsl:for-each select="$prefab//property[starts-with(@name, 'Sleeper')]">
                    <xsl:call-template name="value-of-template">
                      <xsl:with-param name="select" select="@name"/>
                    </xsl:call-template>
                    <xsl:text> </xsl:text>
                  </xsl:for-each>
                  <xsl:text>)</xsl:text>
                </xsl:when>
              </xsl:choose>
              <xsl:value-of select="'&#10;'"/>
            </xsl:when>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="value-of-template">
            <xsl:with-param name="select" select="@name"/>
          </xsl:call-template>
          <xsl:text> Not Found</xsl:text>
          <xsl:value-of select="'&#10;'"/>
        </xsl:otherwise>
      </xsl:choose>
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
