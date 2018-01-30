<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                xmlns:exslt="http://exslt.org/common" 
				xmlns:math="http://exslt.org/math"
				xmlns:func="http://exslt.org/functions"
				xmlns:dyn="http://exslt.org/dynamic"
				xmlns:my="http://www.w3.org/2001/XMLSchema"
                version="1.0" extension-element-prefixes="exslt math dyn func">
	<xsl:output omit-xml-declaration="yes" indent="yes"/>
	<xsl:strip-space elements="*"/>
	<xsl:variable name="debug" select="false()"/>
	<func:function name="my:needsMerge">
		<xsl:param name="node"/>
		<func:result select="name($node)='property' and $node/@class" />
	</func:function>
	<xsl:template match="node()|@*">
		<xsl:copy>
		  <xsl:apply-templates select="node()|@*"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="node()[property/@name='Extends']">
		<xsl:copy>
			<!-- Copy node attributes -->
			<xsl:apply-templates select="@*"/>
			<!-- Copy only those elements without descendants -->
			<xsl:call-template name="appendAttributes">
				<xsl:with-param name="context" select=".."/>
				<xsl:with-param name="parentName" select="property[@name='Extends']/@value"/>
				<xsl:with-param name="properties" select="./property"/>
			</xsl:call-template>
			<!-- Merge elements with descendants -->
<!--
			<xsl:call-template name="mergeAttributes">
				<xsl:with-param name="context" select=".."/>
				<xsl:with-param name="parentName" select="property[@name='Extends']/@value"/>
				<xsl:with-param name="properties" select="./property"/>
			</xsl:call-template>
-->
<!--
			<xsl:call-template name="copyAncestors">
				<xsl:with-param name="context" select=".."/>
				<xsl:with-param name="parentName" select="property[@name='Extends']/@value"/>
				<xsl:with-param name="properties" select="./property"/>
			</xsl:call-template>
-->
		</xsl:copy>
	</xsl:template>
	<xsl:template name="copyAncestors">
		<xsl:param name="context"/>
		<xsl:param name="parentName"/>
		<xsl:param name="properties"/>
		<xsl:if test="$debug">
			<xsl:message>copyAncestors <xsl:for-each select="$context"><xsl:for-each select="ancestor-or-self::*"><xsl:value-of select="name(.)"/>/</xsl:for-each></xsl:for-each><xsl:value-of select="name(.)"/><xsl:text> </xsl:text><xsl:value-of select="@name"/>: <xsl:value-of select="$parentName"/></xsl:message>
			<xsl:message>Existing Properties: <xsl:for-each select="$properties"><xsl:value-of select="@name"/>,</xsl:for-each></xsl:message>
		</xsl:if>
		<xsl:variable name="parent" select="$context/*[@name=$parentName]"/>
		<xsl:for-each select="$parent/*">
			<xsl:variable name="propertyName" select="@name"/>
			<xsl:if test="$debug">
				<xsl:message>Copying node <xsl:value-of select="name(.)"/>: <xsl:value-of select="@name"/> Skip? <xsl:copy-of select="boolean(name(.)='property' and $properties[@name=$propertyName])"/></xsl:message>
			</xsl:if>
			<xsl:if test="not(name(.)='property' and $properties[@name=$propertyName])">
				<xsl:copy>
					<xsl:apply-templates select="node()|@*"/>
				</xsl:copy>
			</xsl:if>
		</xsl:for-each>
		<xsl:if test="$parent/property[@name='Extends']">
				<xsl:call-template name="copyAncestors">
					<xsl:with-param name="context" select="$context"/>
					<xsl:with-param name="parentName" select="$parent/property[@name='Extends']/@value"/>
					<xsl:with-param name="properties" select="$properties|$parent/property"/>
				</xsl:call-template>
				<xsl:if test="$debug">
					<xsl:message terminate="yes">Recursed into <xsl:value-of select="$parent/property[@name='Extends']/@value"/></xsl:message>
				</xsl:if>
		</xsl:if>
	</xsl:template>

	<!-- Merge with parent's elements without descendants -->
	<xsl:template name="appendAttributes">
		<xsl:param name="context"/>
		<xsl:param name="parentName"/>
		<xsl:param name="properties"/>
		<xsl:for-each select="./*">
			<xsl:if test="not(my:needsMerge(.))">
				<xsl:copy>
					<xsl:apply-templates select="node()|@*"/>
				</xsl:copy>
			</xsl:if>
		</xsl:for-each>
		<xsl:if test="$debug">
			<xsl:message>appendAttributes <xsl:for-each select="$context"><xsl:for-each select="ancestor-or-self::*"><xsl:value-of select="name(.)"/>/</xsl:for-each></xsl:for-each><xsl:value-of select="name(.)"/><xsl:text> </xsl:text><xsl:value-of select="@name"/>: <xsl:value-of select="$parentName"/></xsl:message>
			<xsl:message>Existing Properties: <xsl:for-each select="$properties"><xsl:value-of select="@name"/>,</xsl:for-each></xsl:message>
		</xsl:if>
		<xsl:variable name="parent" select="$context/*[@name=$parentName]"/>
		<xsl:for-each select="$parent/*">
			<xsl:variable name="propertyName" select="@name"/>
			<xsl:if test="$debug">
				<xsl:message>Copying node <xsl:value-of select="name(.)"/>: <xsl:value-of select="@name"/> Skip? <xsl:copy-of select="boolean(name(.)='property' and $properties[@name=$propertyName])"/></xsl:message>
			</xsl:if>
			<xsl:if test="not(my:needsMerge(.)) and not(name(.)='property' and $properties[@name=$propertyName])">
				<xsl:copy>
					<xsl:apply-templates select="node()|@*"/>
				</xsl:copy>
			</xsl:if>
		</xsl:for-each>
		<xsl:if test="$parent/property[@name='Extends']">
				<xsl:call-template name="copyAncestors">
					<xsl:with-param name="context" select="$context"/>
					<xsl:with-param name="parentName" select="$parent/property[@name='Extends']/@value"/>
					<xsl:with-param name="properties" select="$properties|$parent/property"/>
				</xsl:call-template>
				<xsl:if test="$debug">
					<xsl:message terminate="yes">Recursed into <xsl:value-of select="$parent/property[@name='Extends']/@value"/></xsl:message>
				</xsl:if>
		</xsl:if>
	</xsl:template>

	<!-- Merge elements with descendants -->

</xsl:stylesheet>
