<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                xmlns:exslt="http://exslt.org/common" 
				xmlns:math="http://exslt.org/math"
				xmlns:dyn="http://exslt.org/dynamic"
				xmlns:func="http://exslt.org/functions"
				xmlns:str="http://exslt.org/strings"
				xmlns:my="http://www.w3.org/2001/XMLSchema"
				xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
				xsi:noNamespaceSchemaLocation="xslt.xsd"
                version="1.0" extension-element-prefixes="exslt math dyn my func str">
				
	<xsl:param name="upperBound" select="2048"/>
	<xsl:output method="text" omit-xml-declaration="yes" indent="no"/>
	
	<func:function name="my:printRange">
		<xsl:param name="lower"/>
		<xsl:param name="upper"/>
		<func:result>
			<xsl:value-of select="$lower"/>
			<xsl:if test="$lower + 1 &lt; $upper">
				<xsl:text>-</xsl:text>
				<xsl:value-of select="$upper - 1"/>
			</xsl:if>
		</func:result>
	</func:function>

	<xsl:template match="/">
		<xsl:call-template name="nextFree">
			<xsl:with-param name="i" select="1"/>
			<xsl:with-param name="hasPrevious" select="false()"/>
			<xsl:with-param name="count" select="0"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template name="nextFree">
		<xsl:param name="i"/>
		<xsl:param name="hasPrevious"/>
		<xsl:param name="count"/>
		<xsl:choose>
			<xsl:when test="$i = $upperBound">
				<xsl:text>&#10;</xsl:text>
				<xsl:value-of select="$count"/><xsl:text> free blocks</xsl:text>
			</xsl:when>
			<xsl:when test="not(//block[@id=$i])">
				<xsl:if test="$hasPrevious">
					<xsl:text>,</xsl:text>
				</xsl:if>
				<xsl:call-template name="nextOccupied">
					<xsl:with-param name="initial" select="$i"/>
					<xsl:with-param name="i" select="$i + 1"/>
					<xsl:with-param name="count" select="$count"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="nextFree">
					<xsl:with-param name="i" select="$i + 1"/>
					<xsl:with-param name="hasPrevious" select="$hasPrevious"/>
					<xsl:with-param name="count" select="$count"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="nextOccupied">
		<xsl:param name="initial"/>
		<xsl:param name="i"/>
		<xsl:param name="count"/>
		<xsl:choose>
			<xsl:when test="$i = $upperBound">
				<xsl:value-of select="my:printRange($initial, $i)"/>
				<xsl:text>&#10;</xsl:text>
				<xsl:value-of select="$count"/><xsl:text> free blocks</xsl:text>
			</xsl:when>
			<xsl:when test="//block[@id=$i]">
				<xsl:value-of select="my:printRange($initial, $i)"/>
				<xsl:call-template name="nextFree">
					<xsl:with-param name="i" select="$i + 1"/>
					<xsl:with-param name="hasPrevious" select="true()"/>
					<xsl:with-param name="count" select="$count + ($i - $initial)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="nextOccupied">
					<xsl:with-param name="initial" select="$initial"/>
					<xsl:with-param name="i" select="$i+1"/>
					<xsl:with-param name="count" select="$count"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
