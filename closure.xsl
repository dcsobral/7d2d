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
				
	<func:function name="my:closure">
		<xsl:param name="nodeset"/>
		<xsl:param name="query"/>
		<xsl:variable name="partial" select="my:closureHelper($nodeset, $query, 1)"/>
		<xsl:choose>
			<xsl:when test="count($partial)=0">
				<func:result select="$partial"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:message>Recursing (partial count <xsl:value-of select="count($partial)"/>)</xsl:message>
				<func:result select="$partial|my:closure($partial,$query)"/>
			</xsl:otherwise>
		</xsl:choose>
	</func:function>
	
	<func:function name="my:closureHelper">
		<xsl:param name="nodeset"/>
		<xsl:param name="query"/>
		<xsl:param name="pos"/>
		<xsl:for-each select="$nodeset">
			<xsl:if test="position()=$pos">
				<xsl:message><xsl:value-of select="$pos"/>:<xsl:for-each select="ancestor-or-self::*"><xsl:value-of select="name(.)"/>/</xsl:for-each><xsl:for-each select="attribute::*"><xsl:value-of select="name(.)"/>="<xsl:value-of select="."/>"</xsl:for-each></xsl:message>
				<xsl:choose>
					<xsl:when test="position()=last()">
						<func:result select="dyn:evaluate($query)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="next" select="$pos+1"/>
						<func:result select="dyn:evaluate($query)|my:closureHelper($nodeset, $query, $next)"/>
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