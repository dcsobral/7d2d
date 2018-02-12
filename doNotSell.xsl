<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                xmlns:exslt="http://exslt.org/common" 
				xmlns:math="http://exslt.org/math"
				xmlns:func="http://exslt.org/functions"
				xmlns:dyn="http://exslt.org/dynamic"
				xmlns:my="http://www.w3.org/2001/XMLSchema"
                version="1.0" extension-element-prefixes="exslt math dyn func">
	<xsl:output omit-xml-declaration="no" indent="yes"/>
	<xsl:strip-space elements="*"/>

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
					<xsl:if test="property[@name='SellableToTrader']/@value='true'">
						<xsl:message>Changing explicitly sellable <xsl:value-of select="name(.)"/> <xsl:value-of select="@name"/> to false</xsl:message>
					</xsl:if>
					<xsl:apply-templates select="@*|*[not(@name) or @name!='SellableToTrader']"/>
					<property name="SellableToTrader" value="false"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="@*|node()"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:copy>
	</xsl:template>
  
	<xsl:template match="node()|@*">
		<xsl:copy>
		  <xsl:apply-templates select="node()|@*"/>
		</xsl:copy>
	</xsl:template>

</xsl:stylesheet>

