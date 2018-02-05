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

	<func:function name="my:fold">
		<xsl:param name="nodeset"/>
		<xsl:param name="query"/>
		<xsl:param name="accumulator"/>
		<xsl:param name="combine"/>
		<xsl:param name="partial" select="/.."/>
		<xsl:param name="pos" select="1"/>
		<xsl:for-each select="$nodeset">
			<xsl:if test="position()=$pos">
				<xsl:message><xsl:value-of select="$pos"/>:<xsl:for-each select="ancestor-or-self::*"><xsl:value-of select="name(.)"/>/</xsl:for-each><xsl:for-each select="attribute::*"><xsl:value-of select="name(.)"/>="<xsl:value-of select="."/>"</xsl:for-each></xsl:message>
				<xsl:variable name="queryResult" select="dyn:evaluate($query)"/>
				<xsl:variable name="nextPartial" select="$partial|$queryResult"/>
				<xsl:choose>
					<xsl:when test="position()=last() and count($nextPartial)=0">
						<func:result select="$accumulator"/>
					</xsl:when>
					<xsl:when test="position()=last()">
						<func:result select="my:fold($nextPartial, $query, dyn:evaluate($combine), $combine)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="next" select="$pos+1"/>
						<func:result select="my:fold($nodeset, $query, dyn:evaluate($combine), $combine, $nextPartial, $next)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>
		</xsl:for-each>
	</func:function>

	<func:function name="my:appendNode">
		<xsl:param name="nodeset"/>
		<xsl:param name="node"/>
		<func:result select="exslt:node-set(my:appendNodeHelper($nodeset, $node))"/>
	</func:function>
	
	<func:function name="my:appendNodeHelper">
		<xsl:param name="nodeset"/>
		<xsl:param name="node"/>
		<func:result>
			<xml>
				<xsl:for-each select="$nodeset/xml/*">
					<xsl:copy-of select="."/>
				</xsl:for-each>
				<xsl:copy-of select="$node"/>
			</xml>
		</func:result>
	</func:function>
	
		<func:function name="my:scan">
		<xsl:param name="nodeset"/>
		<xsl:param name="query"/>
		<func:result select="my:fold($nodeset, $query, /.., 'my:appendNode($accumulator, $queryResult)')"/>
	</func:function>
	
	<func:function name="my:closure">
		<xsl:param name="nodeset"/>
		<xsl:param name="query"/>
		<func:result select="my:fold($nodeset, $query, /.., '$accumulator|$queryResult')"/>
	</func:function>

	
	<xsl:template match="/">
		Nodes:
		<xsl:copy-of select="$nodes"/>
		
		Scan:
		<xsl:copy-of select="my:scan($nodes, $closureQuery)"/>
		
		Closure:
		<xsl:copy-of select="my:closure($nodes, $closureQuery)"/>
	</xsl:template>
</xsl:stylesheet>