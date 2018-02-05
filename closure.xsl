<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                xmlns:exslt="http://exslt.org/common" 
				xmlns:math="http://exslt.org/math"
				xmlns:dyn="http://exslt.org/dynamic"
				xmlns:func="http://exslt.org/functions"
				xmlns:str="http://exslt.org/strings"
				xmlns:my="http://www.w3.org/2001/XMLSchema"
				xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
				xmlns:saxon="http://icl.com/saxon"
				xsi:noNamespaceSchemaLocation="xslt.xsd"
                version="1.0" extension-element-prefixes="exslt math dyn my func str">
				
				<xsl:param name="nodes"/>
				<xsl:param name="closureQuery"/>
				
	<xsl:output method="html" omit-xml-declaration="yes" indent="no"/>

	<!--
					<xsl:message><xsl:value-of select="$pos"/>:<xsl:for-each select="ancestor-or-self::*"><xsl:value-of select="name(.)"/>/</xsl:for-each><xsl:for-each select="attribute::*"><xsl:value-of select="name(.)"/>="<xsl:value-of select="."/>"</xsl:for-each></xsl:message>
	-->
	
	<func:function name="my:closure">
		<xsl:param name="nodeset"/>
		<xsl:param name="query"/>
		<xsl:param name="partial" select="/.."/>
		<xsl:param name="pos" select="1"/>
		<xsl:for-each select="$nodeset">
			<xsl:if test="position()=$pos">
				<xsl:variable name="queryResult" select="dyn:evaluate($query)"/>
				<xsl:variable name="nextPartial" select="$partial|$queryResult"/>
				<xsl:choose>
					<xsl:when test="position()=last() and count($nextPartial)=0">
						<func:result select="$nextPartial"/>
					</xsl:when>
					<xsl:when test="position()=last()">
						<func:result select="$nextPartial|my:closure($nextPartial, $query)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="next" select="$pos+1"/>
						<func:result select="my:closure($nodeset, $query, $nextPartial, $next)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>
		</xsl:for-each>
	</func:function>

	<xsl:template match="/">
		Nodes:
		<xsl:copy-of select="$nodes"/>
		
		Result:
		<xsl:copy-of select="my:closure($nodes, $closureQuery)"/>
	</xsl:template>
</xsl:stylesheet>