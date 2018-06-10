<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
				xmlns:func="http://exslt.org/functions"
				xmlns:math="http://exslt.org/math"
				xmlns:dyn="http://exslt.org/dynamic"
				xmlns:str="http://exslt.org/strings"
				xmlns:my="http://www.w3.org/2001/XMLSchema"
                version="1.0" extension-element-prefixes="func math dyn str my">
	<xsl:param name="language" select="'English'"/>
	<xsl:output method="text" indent="no" omit-xml-declaration="yes" encoding="utf-8"/>
	<xsl:strip-space elements="*"/>
	
	<xsl:variable name="localization" select="document('Localization.xml')"/>
	<xsl:variable name="questLocalization" select="document('Localization-Quest.xml')"/>

	<xsl:variable name="dummy-startup-messages">
		<xsl:message>Parameter 'language' set to '<xsl:value-of select="$language"/>'</xsl:message>
	</xsl:variable>
	
	<xsl:key name="group" match="/quests/quest" use="@group_name_key"/>

	<func:function name="my:translate">
		<xsl:param name="base"/>
		<xsl:param name="key"/>
		<func:result>
			<xsl:variable name="translation" select="$base/records/record[Key/text()=$key]/*[name(.)=$language]/text()"/>
			<xsl:choose>
				<xsl:when test="$translation">
					<xsl:value-of select="$translation"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$key"/>
				</xsl:otherwise>
			</xsl:choose>
		</func:result>
	</func:function>

	<func:function name="my:max">
		<xsl:param name="x"/>
		<xsl:param name="y"/>
		<xsl:choose>
			<xsl:when test="$x &lt; $y">
				<func:result select="$y"/>
			</xsl:when>
			<xsl:otherwise>
				<func:result select="$x"/>
			</xsl:otherwise>
		</xsl:choose>
	</func:function>
	
	<func:function name="my:type">
		<xsl:param name="type"/>
		<xsl:choose>
			<xsl:when test="$type='AnimalKill' or $type='ZombieKill'">
				<func:result select="'Kill'"/>
			</xsl:when>
			<xsl:when test="$type='BlockPlace'">
				<func:result select="'Place'"/>
			</xsl:when>
			<xsl:when test="$type='BlockUpgrade'">
				<func:result select="'Upgrade'"/>
			</xsl:when>
			<xsl:when test="$type='FetchKeep'">
				<func:result select="'Gather'"/>
			</xsl:when>
			<xsl:when test="$type='SkillPoints'">
				<func:result select="'Skill Points'"/>
			</xsl:when>
			<xsl:when test="$type='TreasureChest'">
				<func:result select="'Find Treasure'"/>
			</xsl:when>
			<xsl:otherwise>
				<func:result select="$type"/>
			</xsl:otherwise>
		</xsl:choose>
	</func:function>

	<xsl:template match="quests">
		<xsl:for-each select="quest[@group_name_key and count(. | key('group', @group_name_key)[1]) = 1]">
			<xsl:call-template name="quest_chain">
				<xsl:with-param name="group" select="@group_name_key"/>
			</xsl:call-template>
		</xsl:for-each>

		<xsl:call-template name="simple_quests"/>
	</xsl:template>
	
	<xsl:template name="quest_chain">
		<xsl:param name="group"/>
		<xsl:text>==</xsl:text>
		<xsl:value-of select="my:translate($questLocalization, $group)"/>
		<xsl:text>==&#10;</xsl:text>
		<xsl:text>{| class="wikitable"&#10;</xsl:text>
		<xsl:text>! colspan="3" rowspan="2" |Quest&#10;</xsl:text>
		<xsl:text>! colspan="3" |Goals&#10;</xsl:text>
		<xsl:text>! colspan="3" |Rewards&#10;</xsl:text>
		<xsl:text>! rowspan="2" |Description&#10;</xsl:text>
		<xsl:text>|-&#10;</xsl:text>
		<xsl:text>!Type&#10;</xsl:text>
		<xsl:text>!Target&#10;</xsl:text>
		<xsl:text>!Qty&#10;</xsl:text>
		<xsl:text>!Type&#10;</xsl:text>
		<xsl:text>!Name&#10;</xsl:text>
		<xsl:text>!Qty/Qlty&#10;</xsl:text>
		<xsl:text>|-&#10;</xsl:text>
		<xsl:for-each select="/quests/quest[@group_name_key=$group]">
			<xsl:sort select="@id" data-type="number"/>
			<xsl:variable name="objectives" select="count(objective)"/>
			<xsl:variable name="rewards" select="count(reward)"/>
			<xsl:variable name="rows" select="my:max($objectives, $rewards)"/>
			<!-- icon -->
			<xsl:text>| rowspan="</xsl:text>
			<xsl:value-of select="$rows"/>
			<xsl:text>" style="text-align:center;margin-left:auto;margin-right:auto;" |[[File:</xsl:text>
			<xsl:value-of select="@icon"/>
			<xsl:text>.png|thumb|32x32px]]&#10;</xsl:text>
			
			<!-- name -->
			<xsl:text>| rowspan="</xsl:text>
			<xsl:value-of select="$rows"/>
			<xsl:text>" | </xsl:text>
			<xsl:value-of select="my:translate($questLocalization, @name_key)"/>
			<xsl:text>&#10;</xsl:text>
			
			<!-- subtitle -->
			<xsl:text>| rowspan="</xsl:text>
			<xsl:value-of select="$rows"/>
			<xsl:text>" | </xsl:text>
			<xsl:value-of select="my:translate($questLocalization, @subtitle_key)"/>
			<xsl:text>&#10;</xsl:text>
			
			<!-- objectives -->
			<xsl:call-template name="goalsAndRewards">
				<xsl:with-param name="rows" select="$rows"/>
				<xsl:with-param name="rewards" select="$rewards"/>
				<xsl:with-param name="objectives" select="$objectives"/>
				<xsl:with-param name="node" select="."/>
			</xsl:call-template>
		</xsl:for-each>
		<xsl:text>|}&#10;</xsl:text>
	</xsl:template>
	
	<xsl:template name="simple_quests">
		<xsl:param name="group"/>
		<xsl:text>== Simple Quests ==&#10;</xsl:text>
		<xsl:text>{| class="wikitable"&#10;</xsl:text>
		<xsl:text>! colspan="3" rowspan="2" |Quest&#10;</xsl:text>
		<xsl:text>! colspan="3" |Goals&#10;</xsl:text>
		<xsl:text>! colspan="3" |Rewards&#10;</xsl:text>
		<xsl:text>! rowspan="2" |Description&#10;</xsl:text>
		<xsl:text>|-&#10;</xsl:text>
		<xsl:text>!Type&#10;</xsl:text>
		<xsl:text>!Target&#10;</xsl:text>
		<xsl:text>!Qty&#10;</xsl:text>
		<xsl:text>!Type&#10;</xsl:text>
		<xsl:text>!Name&#10;</xsl:text>
		<xsl:text>!Qty/Qlty&#10;</xsl:text>
		<xsl:text>|-&#10;</xsl:text>
		<xsl:for-each select="quest[not(@group_name_key)]">
			<xsl:sort select="@id" data-type="number"/>
			<xsl:variable name="objectives" select="count(objective)"/>
			<xsl:variable name="rewards" select="count(reward)"/>
			<xsl:variable name="rows" select="my:max($objectives, $rewards)"/>
			<!-- icon -->
			<xsl:text>| rowspan="</xsl:text>
			<xsl:value-of select="$rows"/>
			<xsl:text>" style="text-align:center;margin-left:auto;margin-right:auto;" |[[File:</xsl:text>
			<xsl:value-of select="@icon"/>
			<xsl:text>.png|thumb|32x32px]]&#10;</xsl:text>
			
			<!-- name -->
			<xsl:text>| rowspan="</xsl:text>
			<xsl:value-of select="$rows"/>
			<xsl:text>" | </xsl:text>
			<xsl:value-of select="my:translate($questLocalization, @name_key)"/>
			<xsl:text>&#10;</xsl:text>
			
			<!-- subtitle -->
			<xsl:text>| rowspan="</xsl:text>
			<xsl:value-of select="$rows"/>
			<xsl:text>" | </xsl:text>
			<xsl:value-of select="my:translate($questLocalization, @subtitle_key)"/>
			<xsl:text>&#10;</xsl:text>
			
			<!-- objectives -->
			<xsl:call-template name="goalsAndRewards">
				<xsl:with-param name="rows" select="$rows"/>
				<xsl:with-param name="rewards" select="$rewards"/>
				<xsl:with-param name="objectives" select="$objectives"/>
				<xsl:with-param name="node" select="."/>
			</xsl:call-template>
		</xsl:for-each>
		<xsl:text>|}&#10;</xsl:text>
	</xsl:template>

	<xsl:template name="goalsAndRewards">
		<xsl:param name="index" select="1"/>
		<xsl:param name="rows"/>
		<xsl:param name="objectives"/>
		<xsl:param name="rewards"/>
		<xsl:param name="node"/>
		
		<xsl:choose>
			<xsl:when test="$index &gt; $objectives">
				<xsl:text>| colspan="3" |&#10;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="$node/objective[$index]"/>
			</xsl:otherwise>
		</xsl:choose>

		<xsl:choose>
			<xsl:when test="$index &gt; $rewards">
				<xsl:text>| colspan="3" |&#10;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="$node/reward[$index]"/>
			</xsl:otherwise>
		</xsl:choose>
		
		<xsl:if test="$index=1">
			<xsl:text>| rowspan="</xsl:text>
			<xsl:value-of select="$rows"/>
			<xsl:text>" | </xsl:text>
			<xsl:value-of select="my:translate($questLocalization, @description_key)"/>
			<xsl:text>&#10;</xsl:text>
		</xsl:if>

		<xsl:text>|-&#10;</xsl:text>

		<xsl:if test="$index &lt; $rows">
			<xsl:call-template name="goalsAndRewards">
				<xsl:with-param name="index" select="$index + 1"/>
				<xsl:with-param name="rows" select="$rows"/>
				<xsl:with-param name="rewards" select="$rewards"/>
				<xsl:with-param name="objectives" select="$objectives"/>
				<xsl:with-param name="node" select="."/>
			</xsl:call-template>
		</xsl:if>

		</xsl:template>
	
	<xsl:template match="objective[@type='ZombieKill']">
		<xsl:text>| </xsl:text><xsl:value-of select="my:type(@type)"/><xsl:text>&#10;</xsl:text>
		<xsl:text>| style="border-right-width:0;" | </xsl:text>
		<xsl:choose>
			<xsl:when test="contains(@id,',')">
				<xsl:for-each select="str:tokenize(@id,',')">
					<xsl:value-of select="my:translate($localization, .)"/>
					<xsl:if test="not(position()=last())">
						<xsl:text>, </xsl:text>
					</xsl:if>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="my:translate($localization, @id)"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>&#10;</xsl:text>
		<xsl:text>| style="border-left-width:0;text-align:right;" | </xsl:text><xsl:value-of select="@value"/><xsl:text>&#10;</xsl:text>
	</xsl:template>
	
	<xsl:template match="objective[@type='TreasureChest']">
		<xsl:text>| colspan="3" | </xsl:text><xsl:value-of select="my:type(@type)"/><xsl:text>&#10;</xsl:text>
	</xsl:template>
	
	<xsl:template match="objective">
		<xsl:text>| </xsl:text><xsl:value-of select="my:type(@type)"/><xsl:text>&#10;</xsl:text>
		<xsl:text>| style="border-right-width:0;" | </xsl:text><xsl:value-of select="my:translate($localization, @id)"/><xsl:text>&#10;</xsl:text>
		<xsl:text>| style="border-left-width:0;text-align:right;" | </xsl:text><xsl:value-of select="@value"/><xsl:text>&#10;</xsl:text>
	</xsl:template>
	
	<xsl:template match="reward[@type='Quest']">
		<xsl:text>| </xsl:text><xsl:value-of select="my:type(@type)"/><xsl:text>&#10;</xsl:text>
		<xsl:text>| colspan="2" | </xsl:text><xsl:value-of select="my:translate($questLocalization, @id)"/><xsl:text>&#10;</xsl:text>
	</xsl:template>

	<xsl:template match="reward">
		<xsl:text>| </xsl:text><xsl:value-of select="my:type(@type)"/><xsl:text>&#10;</xsl:text>
		<xsl:text>| style="border-right-width:0;" | </xsl:text><xsl:value-of select="my:translate($localization, @id)"/><xsl:text>&#10;</xsl:text>
		<xsl:text>| style="border-left-width:0;text-align:right;" | </xsl:text><xsl:value-of select="@value"/><xsl:text>&#10;</xsl:text>
	</xsl:template>

</xsl:stylesheet>
