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
				
	<xsl:param name="categories"/>
	<xsl:variable name="useCategories" select="$categories='yes'"/>
				
	<xsl:output method="text" omit-xml-declaration="yes" indent="no"/>
	<func:function name="my:printNode">
		<xsl:param name="node"/>
		<func:result>
		<xsl:for-each select="$node/ancestor-or-self::*">
			<xsl:value-of select="name(.)"/>
			<xsl:text>/</xsl:text>
		</xsl:for-each>
		<xsl:for-each select="$node/attribute::*">
			<xsl:text> </xsl:text>
			<xsl:value-of select="name(.)"/>
			<xsl:text>="</xsl:text>
			<xsl:value-of select="."/>
			<xsl:text>"</xsl:text>
		</xsl:for-each>
		</func:result>
	</func:function>

	<xsl:key name="block" match="/blocks/block" use="@name"/>
	<xsl:key name="item" match="/items/item" use="@name"/>
	<xsl:key name="customIcon" match="//property[@name='CustomIcon']" use="@value"/>
	<xsl:key name="categoriesUi" match="//property[@name='Categories_UI']" use="@value"/>
	<xsl:key name="buff" match="/buffs/buff" use="@id"/>
	
	<xsl:variable name="blocks" select="document('blocks.xml')"/>
	<xsl:variable name="items" select="document('items.xml')"/>
	<xsl:variable name="buffs" select="document('buffs.xml')"/>
	<xsl:variable name="progression" select="document('progression.xml')"/>
	<xsl:variable name="quests" select="document('quests.xml')"/>
	<xsl:variable name="iconAttr" select="($blocks|$items|$buffs|$progression|$quests)//*/@icon/.."/>
	<xsl:variable name="controls" select="document('XUi/controls.xml')"/>
	<xsl:variable name="windows" select="document('XUi/windows.xml')"/>
	<xsl:variable name="sprites" select="($controls|$windows)//sprite"/>
	
	<func:function name="my:isBlockName">
		<xsl:param name="name"/>
		<xsl:for-each select="$blocks">
			<xsl:variable name="customIcon" select="boolean(key('customIcon', $name))"/>
			<xsl:variable name="categoriesUi" select="$useCategories and boolean(key('categoriesUi', $name))"/>
			<xsl:variable name="result" select="boolean(key('block', $name))"/>
			<func:result select="$customIcon or $categoriesUi or $result"/>
		</xsl:for-each>
	</func:function>
	
	<func:function name="my:isItemName">
		<xsl:param name="name"/>
		<xsl:for-each select="$items">
			<xsl:variable name="customIcon" select="boolean(key('customIcon', $name))"/>
			<xsl:variable name="categoriesUi" select="$useCategories and boolean(key('categoriesUi', $name))"/>
			<xsl:variable name="result" select="boolean(key('item', $name))"/>
			<func:result select="$customIcon or $categoriesUi or $result"/>
		</xsl:for-each>
	</func:function>
	
	<func:function name="my:isBuffName">
		<xsl:param name="name"/>
		<xsl:for-each select="$buffs">
			<xsl:variable name="result" select="boolean(key('buff', $name))"/>
			<func:result select="$result"/>
		</xsl:for-each>
	</func:function>
	
	<func:function name="my:isIconAttr">
		<xsl:param name="name"/>
		<xsl:variable name="result" select="boolean($iconAttr[@icon=$name])"/>
		<func:result select="$result"/>
	</func:function>
	
	<func:function name="my:isSprite">
		<xsl:param name="name"/>
		<xsl:variable name="result" select="boolean($sprites[@sprite=$name])"/>
		<func:result select="$result"/>
	</func:function>
	
	<func:function name="my:isSkill">
		<xsl:param name="name"/>
		<xsl:variable name="result" select="boolean($progression//*[@name=$name])"/>
		<func:result select="$result"/>
	</func:function>
	
	<func:function name="my:isUsed">
		<xsl:param name="name"/>
		<func:result select="my:isBlockName($name) or my:isItemName($name) or my:isBuffName($name) or my:isIconAttr($name) or my:isSprite($name) or my:isSkill($name)"/>
	</func:function>

	<xsl:template match="/">
		<xsl:for-each select="/dir/f">
			<xsl:variable name="filename" select="substring-before(@n, '.png')"/>
			<xsl:if test="not(my:isUsed($filename))">
				<xsl:value-of select="@n"/>
				<xsl:text>&#10;</xsl:text>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>
