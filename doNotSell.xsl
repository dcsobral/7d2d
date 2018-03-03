<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
				xmlns:func="http://exslt.org/functions"
				xmlns:my="http://www.w3.org/2001/XMLSchema"
                version="1.0" extension-element-prefixes="func">
	<xsl:output method="xml" indent="yes" omit-xml-declaration="no" encoding="utf-8"/>
	<xsl:preserve-space elements="*"/>

	<xsl:key name="recipe" match="/recipes/recipe" use="@name"/>
	<xsl:variable name="recipes" select="document('recipes.xml')"/>

	<func:function name="my:hasRecipe">
		<xsl:param name="node"/>
		<xsl:for-each select="$recipes">
			<xsl:variable name="result" select="boolean(key('recipe', $node/@name))"/>
			<func:result select="$result"/>
		</xsl:for-each>
	</func:function>

	<func:function name="my:isSellable">
		<xsl:param name="node"/>
		<xsl:choose>
			<xsl:when test="$node/property[@name='SellableToTrader']">
				<func:result select="$node/property[@name='SellableToTrader']/@value='true'"/>
			</xsl:when>
			<xsl:when test="$node/property[@name='Extends']">
				<func:result select="my:isSellable($node/../*[@name=$node/property[@name='Extends']/@value])"/>
			</xsl:when>
			<xsl:otherwise>
				<func:result select="true()"/>
			</xsl:otherwise>
		</xsl:choose>
	</func:function>
	
	<xsl:template match="block">
		<xsl:call-template name="copyCheckSellable"/>
	</xsl:template>

	<xsl:template match="item">
		<xsl:call-template name="copyCheckSellable"/>
	</xsl:template>

	<xsl:template name="copyCheckSellable">
		<xsl:copy>
			<xsl:choose>
				<xsl:when test="my:hasRecipe(.) and my:isSellable(.)">
					<xsl:call-template name="setSellable"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="@*|node()"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template name="setSellable">
		<xsl:choose>
			<xsl:when test="property[@name='SellableToTrader']/@value='true'">
				<xsl:call-template name="changeSellable"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="addSellable"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="addSellable">
		<xsl:apply-templates select="node()|@*"/>
		<xsl:text>&#9;</xsl:text>
		<xsl:element name="property">
			<xsl:attribute name="name"><xsl:text>SellableToTrader</xsl:text></xsl:attribute>
			<xsl:attribute name="value"><xsl:text>false</xsl:text></xsl:attribute>
		</xsl:element>
		<xsl:text>&#10;</xsl:text>
	</xsl:template>
	
	<xsl:template name="changeSellable">
		<xsl:message>Changing explicitly sellable <xsl:value-of select="name(.)"/> <xsl:value-of select="@name"/> to false</xsl:message>
		<xsl:for-each select="node()|@*">
			<xsl:choose>
				<xsl:when test="boolean(self::*) and @name='SellableToTrader'">
					<xsl:element name="property">
						<xsl:attribute name="name"><xsl:text>SellableToTrader</xsl:text></xsl:attribute>
						<xsl:attribute name="value"><xsl:text>false</xsl:text></xsl:attribute>
					</xsl:element>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
  
	<xsl:template match="node()|@*">
		<xsl:copy>
		  <xsl:apply-templates select="node()|@*"/>
		</xsl:copy>
	</xsl:template>

</xsl:stylesheet>

