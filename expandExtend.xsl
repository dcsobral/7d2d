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
	<xsl:param name="debug" select="false()"/>

	<func:function name="my:needsMerge">
		<xsl:param name="node"/>
		<func:result select="name($node)='property' and $node/@class" />
	</func:function>
	
	<func:function name="my:keyAttribute">
		<xsl:param name="node"/>
		<xsl:variable name="result" select="exslt:node-set(my:keyAttributeHelper($node))/*[1]"/>
		<func:result select="$result"/>
	</func:function>

	<func:function name="my:keyAttributeHelper">
		<xsl:param name="node"/>
		<func:result>
			<xsl:element name="result">
				<xsl:choose>
					<xsl:when test="$node/@name">
						<xsl:attribute name="name"><xsl:text>name</xsl:text></xsl:attribute>
						<xsl:attribute name="value"><xsl:value-of select="$node/@name"/></xsl:attribute>
					</xsl:when>
					<xsl:when test="$node/@class">
						<xsl:attribute name="name"><xsl:text>class</xsl:text></xsl:attribute>
						<xsl:attribute name="value"><xsl:value-of select="$node/@class"/></xsl:attribute>
					</xsl:when>
					<xsl:when test="count($node/@*)=0">
					</xsl:when>
					<xsl:otherwise>
						<xsl:attribute name="name"><xsl:value-of select="name($node/@*[1])"/></xsl:attribute>
						<xsl:attribute name="value"><xsl:value-of select="$node/@*[1]"/></xsl:attribute>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:element>
		</func:result>
	</func:function>

	<func:function name="my:keyAttribute">
		<xsl:param name="node"/>
		<func:result>
			<xsl:choose>
				<xsl:when test="$node/@name"><xsl:text>name</xsl:text></xsl:when>
				<xsl:when test="$node/@class"><xsl:text>class</xsl:text></xsl:when>
				<xsl:when test="count($node/@*)>0"><xsl:value-of select="name($node/@*[1])"/></xsl:when>
				<xsl:otherwise><xsl:text/></xsl:otherwise>
			</xsl:choose>
		</func:result>
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
			<xsl:message>
				<xsl:text>Called copyAncestors </xsl:text>
				<xsl:call-template name="printNodeContext">
					<xsl:with-param name="node" select="."/>
				</xsl:call-template>
				<xsl:text> extends </xsl:text>
				<xsl:value-of select="$parentName"/>
			</xsl:message>
			<xsl:message>
				<xsl:text>Existing Properties: </xsl:text>
				<xsl:for-each select="$properties">
					<xsl:call-template name="printNameOrFirstAttribute">
						<xsl:with-param name="node" select="."/>
					</xsl:call-template>
					<xsl:if test="not(position()=last())">
						<xsl:text>, </xsl:text>
					</xsl:if>
				</xsl:for-each>
			</xsl:message>
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
			<xsl:message>
				<xsl:text>Called appendAttributes </xsl:text>
				<xsl:call-template name="printNodeContext">
					<xsl:with-param name="node" select="."/>
				</xsl:call-template>
				<xsl:text> extends </xsl:text>
				<xsl:value-of select="$parentName"/>
			</xsl:message>
			<xsl:message>
				<xsl:text>Existing Properties: </xsl:text>
				<xsl:for-each select="$properties">
					<xsl:call-template name="printNameOrFirstAttribute">
						<xsl:with-param name="node" select="."/>
					</xsl:call-template>
					<xsl:if test="not(position()=last())">
						<xsl:text>, </xsl:text>
					</xsl:if>
				</xsl:for-each>
			</xsl:message>
		</xsl:if>
		<xsl:variable name="parent" select="$context/*[@name=$parentName]"/>
		<xsl:for-each select="$parent/*">
			<xsl:variable name="propertyName" select="@name"/>
			<xsl:variable name="isSkipped" select="not(my:needsMerge(.)) and name(.)='property' and $properties[@name=$propertyName]"/>
			<xsl:if test="$debug">
				<xsl:message>
					<xsl:text>    </xsl:text>
					<xsl:call-template name="printNode">
						<xsl:with-param name="node" select="."/>
					</xsl:call-template>
					<xsl:choose>
						<xsl:when test="$isSkipped">
							<xsl:text> Skipping</xsl:text>
						</xsl:when>
						<xsl:otherwise> Copying</xsl:otherwise>
					</xsl:choose>
				</xsl:message>
			</xsl:if>
			<xsl:if test="$isSkipped">
				<xsl:copy>
					<xsl:apply-templates select="node()|@*"/>
				</xsl:copy>
			</xsl:if>
		</xsl:for-each>
		<xsl:if test="$parent/property[@name='Extends']">
				<xsl:call-template name="appendAttributes">
					<xsl:with-param name="context" select="$context"/>
					<xsl:with-param name="parentName" select="$parent/property[@name='Extends']/@value"/>
					<xsl:with-param name="properties" select="$properties|$parent/property"/>
				</xsl:call-template>
				<xsl:if test="$debug">
					<xsl:message terminate="yes">Recursed into <xsl:value-of select="$parent/property[@name='Extends']/@value"/></xsl:message>
				</xsl:if>
		</xsl:if>
	</xsl:template>

		<!-- Copy element: -->
		<!--   Parametors: -->
		<!--     Elemento -->
		<!--     Contexto -->
		<!--   Copy -->
		<!--   Copia atributos -->
		<!--   Merge element elemento, contexto, [] -->
		
	<!-- Copy elements -->
	<xsl:template name="copy">
		<xsl:param name="element"/>
		<xsl:param name="context"/>
		
		<!-- Copy node -->
		<xsl:copy>
		
			<!-- Copy node attributes -->
			<xsl:apply-templates select="@*"/>
			
			<!-- Merge subnodes --> 
			<xsl:call-template name="merge">
				<with-param name="element" select="$element"/>
				<with-param name="context" select="$context"/>
				<with-param name="seen" select="/.."/>
			</xsl:call-template>
		</xsl:copy>
	</xsl:template>

	<!-- Merge node with ancestors -->
	<xsl:template name="merge">
		<xsl:param name="element"/>
		<xsl:param name="context"/>
		<xsl:param name="seen"/>
		
		<xsl:for-each select="dyn:evaluate('$element/$context)/*">
			<xsl:variable name="idAttr" select="my:keyAttribute(.)"/>
			<xsl:variable name="propertyId" select="dyn:evaluate('$idAttr')"/>
			<xsl:variable name="isSkipped" select="name(.)='property' and $seen[dyn:evaluate('@$idAttr')=$propertyId]"/>
			<xsl:if test="not($isSkipped)">
				<xsl:call-template name="copy">
					<xsl:param name="element" select="$element"/>
					<xsl:param name="context" select="concat($context, '/', name(.)
				</xsl:call-template>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
	
		<!-- Merge element: -->
		<!--   Parametros: -->
		<!--     Elemento -->
		<!--     Contexto -->
		<!--     Elementos copiados -->
		<!--   Para cada elemento x em elemento/contexto/* -->
        <!--     Se elemento nao presente em elementos copiados -->
		<!--       Copy Element elemento, contexto/x -->
        <!--   Se elemento Extends -->
		<!--     Merge element elemento/sibling[id=@extends], contexto, elementos copiados | elemento/contexto/*
		
		<!-- Copy node -->
		<!-- Copy attributes -->
		<!-- Copy this non-merging nodes -->
		<!-- Copy parent non-merging nodes that are not duplicates -->
		<!-- Call extend with context on each mergeable node -->
		<!-- Recurse on extended class -->
		
		
		<xsl:for-each select="./*">
			<xsl:if test="not(my:needsMerge(.))">
				<xsl:copy>
					<xsl:apply-templates select="node()|@*"/>
				</xsl:copy>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
		
	<!-- Debugging helpers -->
	<xsl:template name="printNodeContext">
		<xsl:param name="node"/>
		<xsl:for-each select="$node/ancestor::*">
			<xsl:call-template name="printNode">
				<xsl:with-param name="node" select="."/>
			</xsl:call-template>
		</xsl:for-each>
		<xsl:call-template name="printNode">
			<xsl:with-param name="node" select="$node"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template name="printNode">
		<xsl:param name="node"/>
		<xsl:text>&lt;</xsl:text>
		<xsl:value-of select="name($node)"/>
		<xsl:variable name="attribute" select="my:keyAttribute($node)"/>
		<xsl:if test="$attribute">
			<xsl:text> @</xsl:text>
			<xsl:value-of select="$attribute"/>
			<xsl:text>="</xsl:text>
			<xsl:value-of select="$node/dyn:evaluate('@$attribute')"/>
			<xsl:text>"</xsl:text>
		</xsl:if>
		<xsl:text>&gt;</xsl:text>
	</xsl:template>
	
	<xsl:template name="printNameOrFirstAttribute">
		<xsl:param name="node"/>
		<xsl:variable name="attr" select="my:keyAttribute($node)"/>
		<xsl:if test="$attr">
			<xsl:value-of select="$node/dyn:evaluate('@$attr')"/>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>
