<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                xmlns:exslt="http://exslt.org/common" 
				xmlns:math="http://exslt.org/math"
				xmlns:dyn="http://exslt.org/dynamic"
				xmlns:func="http://exslt.org/functions"
				xmlns:str="http://exslt.org/strings"
				xmlns:my="http://www.w3.org/2001/XMLSchema"
                version="1.0" extension-element-prefixes="exslt math dyn my func str">
				
	<xsl:param name="language" select="'NONE'"/>
	<xsl:output method="html" omit-xml-declaration="yes" indent="no"/>
	<xsl:strip-space elements="*"/>

	<xsl:key name="property" match="//property" use="@name"/>
	<xsl:key name="recipe" match="/recipes/recipe" use="@name"/>
	<xsl:key name="craftArea" match="/recipes/recipe" use="@craft_area"/>
	<xsl:key name="block" match="/blocks/block" use="@name"/>
	<xsl:key name="thingsByName" match="/*/*" use="@name"/>

	<func:function name="my:group">
		<xsl:param name="node"/>
		<xsl:choose>
			<xsl:when test="$node/property[@name='Group']">
				<func:result select="$node/property[@name='Group']/@value"/>
			</xsl:when>
			<xsl:when test="$node/property[@name='Extends']">
				<func:result select="my:group($node/../*[@name=$node/property[@name='Extends']/@value])"/>
			</xsl:when>
			<xsl:otherwise>
				<func:result select="/.."/>
			</xsl:otherwise>
		</xsl:choose>
	</func:function>

	<func:function name="my:creativeMode">
		<xsl:param name="node"/>
		<xsl:choose>
			<xsl:when test="$node/property[@name='CreativeMode']">
				<func:result select="$node/property[@name='CreativeMode']/@value"/>
			</xsl:when>
			<xsl:when test="$node/property[@name='Extends']">
				<func:result select="my:creativeMode($node/../*[@name=$node/property[@name='Extends']/@value])"/>
			</xsl:when>
			<xsl:otherwise>
				<func:result select="'All'"/>
			</xsl:otherwise>
		</xsl:choose>
	</func:function>

	<func:function name="my:getDescriptionKey">
		<xsl:param name="node"/>
		<xsl:choose>
			<xsl:when test="$node/property[@name='DescriptionKey']">
				<func:result select="$node/property[@name='DescriptionKey']/@value"/>
			</xsl:when>
			<xsl:when test="$node/property[@name='Extends']">
				<func:result select="my:creativeMode($node/../*[@name=$node/property[@name='Extends']/@value])"/>
			</xsl:when>
			<xsl:otherwise>
				<func:result select="'No Description'"/>
			</xsl:otherwise>
		</xsl:choose>
	</func:function>

	<func:function name="my:canBeEaten">
		<xsl:param name="node"/>
		<xsl:choose>
			<xsl:when test="$node/property[@class='Action1']/property[@name='Class']">
				<func:result select="$node/property[@class='Action1']/property[@name='Class']/@value='Eat'"/>
			</xsl:when>
			<xsl:when test="$node/property[@name='Extends']">
				<func:result select="my:canBeEaten($node/../*[@name=$node/property[@name='Extends']/@value])"/>
			</xsl:when>
			<xsl:otherwise>
				<func:result select="false()"/>
			</xsl:otherwise>
		</xsl:choose>
	</func:function>

	<func:function name="my:getGain">
		<xsl:param name="node"/>
		<xsl:param name="stat"/>
		<xsl:choose>
			<xsl:when test="$node/property[@class='Action1']/property[@name=$stat]">
				<func:result select="$node/property[@class='Action1']/property[@name=$stat]/@value"/>
			</xsl:when>
			<xsl:when test="$node/property[@name='Extends']">
				<func:result select="my:getGain($node/../*[@name=$node/property[@name='Extends']/@value], $stat)"/>
			</xsl:when>
			<xsl:otherwise>
				<func:result select="0"/>
			</xsl:otherwise>
		</xsl:choose>
	</func:function>

	<func:function name="my:isCrafted">
		<xsl:param name="item"/>
		<xsl:for-each select="$recipes">
			<xsl:variable name="result" select="boolean(key('recipe', $item/@name))"/>
			<func:result select="$result"/>
		</xsl:for-each>
	</func:function>
	
	<func:function name="my:isHarvested">
		<xsl:param name="item"/>
		<xsl:choose>
			<xsl:when test="$harvest[@name=$item/@name]">
				<func:result select="true()"/>
			</xsl:when>
			<xsl:otherwise>
				<func:result select="false()"/>
			</xsl:otherwise>
		</xsl:choose>
	</func:function>
	
	<func:function name="my:base">
		<xsl:param name="node"/>
		<xsl:for-each select="$node[1]">
			<xsl:variable name="extends" select="property[@name='Extends']"/>
			<xsl:choose>
				<xsl:when test="$extends">
					<func:result select="my:base(key('thingsByName', $extends/@value))"/>
				</xsl:when>
				<xsl:otherwise>
					<func:result select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</func:function>
	
	<func:function name="my:isPlant">
		<xsl:param name="node"/>
		<xsl:variable name="base" select="my:base($node)"/>
		<func:result select="$base/@name='treeMaster' or $base/@name='cropsGrowingMaster' or $base/@name='seedMaster'"/>
	</func:function>

	<func:function name="my:isSeed">
		<xsl:param name="blockName"/>
		<func:result select="$seeds[@name=$blockName]"/>
	</func:function>
	
	<func:function name="my:isFood">
		<xsl:param name="itemName"/>
		<func:result select="$foods[@name=$itemName]"/>
	</func:function>

	<func:function name="my:recipeList">
		<xsl:param name="theseRecipes"/>
		<func:result>
			<xsl:text disable-output-escaping="yes">&lt;figcaption&gt;</xsl:text>
			<xsl:value-of select="count($theseRecipes)"/><xsl:text> recipes:</xsl:text>
			<xsl:text disable-output-escaping="yes">&lt;/figcaption&gt;</xsl:text>
			<xsl:for-each select="$theseRecipes">
				<xsl:text disable-output-escaping="yes">&lt;ul&gt;</xsl:text>
				<xsl:for-each select="ingredient">
					<xsl:text disable-output-escaping="yes">&lt;li&gt;</xsl:text>
					<xsl:value-of select="@count"/><xsl:text> </xsl:text><xsl:value-of select="@name"/>
					<xsl:text disable-output-escaping="yes">&lt;/li&gt;</xsl:text>
				</xsl:for-each>
				<xsl:text disable-output-escaping="yes">&lt;/ul&gt;</xsl:text>
				<xsl:if test="not(position()=last())">
					<xsl:text disable-output-escaping="yes">&lt;hr/&gt;</xsl:text>
				</xsl:if>
			</xsl:for-each>
		</func:result>
	</func:function>
	
	<xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'" />
	<xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
	<func:function name="my:tolower">
		<xsl:param name="text"/>
		<func:result select="translate($text, $uppercase, $lowercase)"/>
	</func:function>
	
	<func:function name="my:translate">
		<xsl:param name="key"/>
		<func:result>
			<xsl:variable name="translations" select="$localization/records/record[Key/text()=$key]"/>
			<xsl:variable name="query" select="concat('$translations/', $language, '/text()')"/>
			<xsl:variable name="translation" select="dyn:evaluate($query)"/>
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

	<!-- Input files -->
	<xsl:variable name="items" select="document('items.xml')"/>
	<xsl:variable name="recipes" select="document('recipes.xml')"/>
	<xsl:variable name="blocks" select="document('blocks.xml')"/>
	<xsl:variable name="progression" select="document('progression.xml')"/>
	<!-- Remove need for this var! -->
	<xsl:variable name="localization" select="document('Localization.xml')"/>
	<xsl:variable name="foods" select="$items/items/item[my:group(.)='Food/Cooking' and my:canBeEaten(.)]"/>
	<xsl:variable name="harvest" select="$blocks//drop[@event='Harvest']|document('entityclasses.xml')//drop[@event='Harvest']"/>
    <xsl:variable name="greenThumb" select="$progression//perk[@name='Green Thumb']/recipe"/>
	<xsl:variable name="seeds" select="$blocks/blocks/block[my:isPlant(.)]|$items/items/item[my:isPlant(.)]"/>
    <xsl:variable name="seedRecipes" select="$recipes/recipes/recipe[my:isSeed(@name)]"/>
	
	<!-- Derived data -->
	<xsl:variable name="gains">
		<xsl:for-each select="//property[starts-with(@name,'Gain_') and count(. | key('property', @name)[1]) = 1]">
			<xsl:sort select="@name"/>
			<xsl:variable name="name" select="substring-after(@name, '_')"/>
			<xsl:element name="gainings">
				<xsl:attribute name="name">
					<xsl:value-of select="concat(translate(substring($name,1,1), $lowercase, $uppercase), substring($name, 2))"/>
				</xsl:attribute>
				<xsl:attribute name="key">
					<xsl:value-of select="@name"/>
				</xsl:attribute>
				<xsl:attribute name="desc">
					<xsl:choose>
						<xsl:when test="$name='food' or $name='water'">
							Amount of <xsl:value-of select="$name"/> gained (72 <xsl:value-of select="$name"/> is 100%).
						</xsl:when>
						<xsl:otherwise>
							Amount of <xsl:value-of select="$name"/> gained.
						</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
			</xsl:element>
		</xsl:for-each>
	</xsl:variable>

	<xsl:variable name="craftAreas" select="$recipes/recipes/recipe[@craft_area and count(. | key('craftArea', @craft_area)[1]) = 1]"/>
	<xsl:variable name="foodCraftAreas">
		<xsl:if test="$recipes/recipes/recipe[not(@craft_area) and my:isFood(@name)]">
			<craftArea name="Hand" desc="Things crafted in your own inventory" key="Hand"/>
		</xsl:if>
		<xsl:for-each select="$craftAreas">
			<xsl:sort select="my:translate(@craft_area)"/>
			<xsl:if test="key('craftArea', @craft_area)[my:isFood(@name)]">
				<xsl:element name="craftArea">
					<xsl:attribute name="name">
						<xsl:value-of select="my:translate(@craft_area)"/>
					</xsl:attribute>
					<xsl:attribute name="key">
						<xsl:value-of select="@craft_area"/>
					</xsl:attribute>

					<xsl:variable name="craftAreaDesc" select="concat(@craft_area, 'Desc')"/>
					<xsl:variable name="comment" select="my:translate($craftAreaDesc)"/>
					<xsl:attribute name="desc">
						[<xsl:value-of select="@craft_area"/>]
						<xsl:if test="not($comment=$craftAreaDesc)">
							<xsl:text> </xsl:text><xsl:value-of select="str:replace($comment, '\n', '&lt;br/>')" disable-output-escaping="yes"/>
						</xsl:if>
					</xsl:attribute>
					<xsl:attribute name="class">
						<xsl:text>filter-select</xsl:text>
					</xsl:attribute>
				</xsl:element>
			</xsl:if>
		</xsl:for-each>
	</xsl:variable>

	<xsl:variable name="otherFields">
		<!--<x name="Crafted?"/>-->
		<x name="Harvested?" desc="Plants, animal products, minerals." class="filter-select"/>
		<x name="Green Thumb Level" desc="Green Thumb level required to make seeds for it." class="mixed"/>
		<x name="Wellness Efficiency" desc="Measure of how much wellness is gained by unit of food or water. The smaller the value, the more you gain wellness before being &quot;full&quot;. Only computed for positive wellness." class="mixed"/>
		<x name="Creative Mode" desc="Where it appears on the creative menu.&lt;BR/>Options are All, Player, Dev and None."/>
	</xsl:variable>

	<xsl:variable name="fields" select="exslt:node-set($gains)/*|exslt:node-set($otherFields)/*|exslt:node-set($foodCraftAreas)/*"/>

	<xsl:template match="/">
		<HTML>
			<HEAD>
				<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.12.1/themes/cupertino/jquery-ui.min.css" type="text/css"/>
				<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.29.4/css/theme.blue.css" type="text/css"/>
				<STYLE>
				    .tablesorter-blue-header {
						font: 12px/18px Arial, Sans-serif;
						font-weight: bold;
						color: #000;
						background-color: #99bfe6;
						border-collapse: collapse;
						padding: 4px;
						text-shadow: 0 1px 0 rgba(204, 204, 204, 0.7);
					}
					
					.tablesorter-blue-td {
						color: #3d3d3d;
						background-color: #fff;
						padding: 4px;
						vertical-align: top;
					}
					
					.tablesorter-blue-override {
						width: 100%;
						background-color: #fff;
						background-image: none;
						margin: 10px 0 15px;
						text-align: left;
						border-spacing: 0;
						border: #cdcdcd 1px solid;
						border-width: 1px 0 0 1px;

					}

					.CellWithComment{
						position:relative;
					}

					.CellComment{
						display:none;
						position:absolute; 
						z-index:100;
						border:1px;
						background-color: black;
						color: #fff;
						border-style:solid;
						border-width:1px;
						border-color:#fff;
						padding:3px;
						top: 100%;
						left: 20px;
						opacity: 0;
						transition: opacity 1s;
					}

					.CellWithComment:hover div.CellComment{
						display:block;
						opacity: 1;
					}
					
					.CellComment::after {
						content: " ";
						position: absolute;
						bottom: 100%;  /* At the top of the tooltip */
						left: 20px;
						margin-left: -5px;
						border-width: 5px;
						border-style: solid;
						border-color: transparent transparent black transparent;
					}
					
					th .CellComment {
						width: 200%;
						left: -50%;
					}

					th .CellComment::after {
						left: 50%;
						margin-left: -10px;
					}
					
					th:last-child .CellComment {
						top: 25%;
						width: 200%;
						right: 105%;
						left: auto;
					}

					th:last-child .CellComment::after {
						top: 50%;
						left: 100%; /* To the right of the tooltip */
						margin-top: -5px;
						margin-left: 0;
						border-color: transparent transparent transparent black;
					}
					
					tr:last-child .CellComment {
						top: auto;
						bottom: 100%;
					}

					tr:last-child .CellComment::after {
						top: 100%;  /* At the bottom of the tooltip */
						bottom: auto;
						border-color: black transparent transparent transparent;
					}
					
					.dialog {
						display:none;
					}
					
					td.integer { text-align: right; }
					td.decimal { text-align: right; white-space: nowrap; }
					th.name { text-align: center; }
					td.name { text-align: left; white-space: nowrap; }
				
					/* TABLE BACKGROUND color (match the original theme) */
					table.hover-highlight td:before,
					table.focus-highlight td:before {
					  background: #fff;
					}

					/* ODD ZEBRA STRIPE color (needs zebra widget) */
					.hover-highlight .odd td:before, .hover-highlight .odd th:before,
					.focus-highlight .odd td:before, .focus-highlight .odd th:before {
					  background: #ebf2fa;
					}
					/* EVEN ZEBRA STRIPE color (needs zebra widget) */
					.hover-highlight .even td:before, .hover-highlight .even th:before,
					.focus-highlight .even td:before, .focus-highlight .even th:before {
					  background-color: #fff;
					}

					/* FOCUS ROW highlight color (touch devices) */
					.focus-highlight td:focus::before, .focus-highlight th:focus::before {
					  background-color: lightblue;
					}
					/* FOCUS COLUMN highlight color (touch devices) */
					.focus-highlight td:focus::after, .focus-highlight th:focus::after {
					  background-color: lightblue;
					}
					/* FOCUS CELL highlight color */
					.focus-highlight th:focus, .focus-highlight td:focus,
					.focus-highlight .even th:focus, .focus-highlight .even td:focus,
					.focus-highlight .odd th:focus, .focus-highlight .odd td:focus {
					  background-color: #d9d9d9;
					  color: #333;
					}

					/* HOVER ROW highlight colors */
					table.hover-highlight tbody > tr:hover > td, /* override tablesorter theme row hover */
					table.hover-highlight tbody > tr.odd:hover > td,
					table.hover-highlight tbody > tr.even:hover > td {
					  background-color: #ffa;
					}
					/* HOVER COLUMN highlight colors */
					.hover-highlight tbody tr td:hover::after,
					.hover-highlight tbody tr th:hover::after {
					  background-color: #ffa;
					}

					/* ************************************************* */
					/* **** No need to modify the definitions below **** */
					/* ************************************************* */
					.focus-highlight td:focus::after, .focus-highlight th:focus::after,
					.hover-highlight td:hover::after, .hover-highlight th:hover::after {
					  content: '';
					  position: absolute;
					  width: 100%;
					  height: 999em;
					  left: 0;
					  top: -555em;
					  z-index: -1;
					}
					.focus-highlight td:focus::before, .focus-highlight th:focus::before {
					  content: '';
					  position: absolute;
					  width: 999em;
					  height: 100%;
					  left: -555em;
					  top: 0;
					  z-index: -2;
					}
					/* required styles */
					.hover-highlight,
					.focus-highlight {
					  overflow: hidden;
					}
					.hover-highlight td, .hover-highlight th,
					.focus-highlight td, .focus-highlight th {
					  position: relative;
					  outline: 0;
					}
					/* override the tablesorter theme styling */
					table.hover-highlight, table.hover-highlight tbody > tr > td,
					table.focus-highlight, table.focus-highlight tbody > tr > td,
					/* override zebra styling */
					table.hover-highlight tbody tr.even > th,
					table.hover-highlight tbody tr.even > td,
					table.hover-highlight tbody tr.odd > th,
					table.hover-highlight tbody tr.odd > td,
					table.focus-highlight tbody tr.even > th,
					table.focus-highlight tbody tr.even > td,
					table.focus-highlight tbody tr.odd > th,
					table.focus-highlight tbody tr.odd > td {
					  background: transparent;
					}
					/* table background positioned under the highlight */
					table.hover-highlight td:before,
					table.focus-highlight td:before {
					  content: '';
					  position: absolute;
					  width: 100%;
					  height: 100%;
					  left: 0;
					  top: 0;
					  z-index: -3;
					}
				</STYLE>
				<script
					src="https://code.jquery.com/jquery-1.12.4.min.js"
					integrity="sha256-ZosEbRLbNQzLpnKIkEdrPv7lOy9C27hHQ+Xp8a4MxAQ="
					crossorigin="anonymous">
				</script>
				<script
					src="https://code.jquery.com/ui/1.12.1/jquery-ui.min.js"
					integrity="sha256-VazP97ZCwtekAsvgPBSUwPFKdrwD3unUfSGVYrahUqU="
					crossorigin="anonymous">
				</script>
				
				<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.29.4/js/jquery.tablesorter.min.js"/>
				<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.29.4/js/jquery.tablesorter.widgets.min.js"/>
				
				<script>
					$(function() {

					  // Extend the themes to change any of the default class names
					  $.extend($.tablesorter.themes.jui, {
						table        : 'ui-widget ui-widget-content ui-corner-all',
						caption      : 'ui-widget-content',
						header       : 'ui-widget-header ui-corner-all ui-state-default',
						sortNone     : '',
						sortAsc      : '',
						sortDesc     : '',
						active       : 'ui-state-active',
						hover        : 'ui-state-hover',
						icons        : 'ui-icon',
						iconSortNone : 'ui-icon-carat-2-n-s ui-icon-caret-2-n-s',
						iconSortAsc  : 'ui-icon-carat-1-n ui-icon-caret-1-n',
						iconSortDesc : 'ui-icon-carat-1-s ui-icon-caret-1-s',
						filterRow    : '',
						footerRow    : '',
						footerCells  : '',
						even         : 'ui-widget-content',
						odd          : 'ui-state-default'
					  });

					  $("table").tablesorter({
						theme : 'blue',
						headerTemplate : '{content} {icon}',
						widgets : ['filter', 'zebra', 'stickyHeaders'],
						widgetOptions : {
						  filter_defaultAttrib : 'data-value',
						  zebra   : ["even", "odd"],
						  filter_functions: {
							".mixed" : {
								"Present"      : function(e, n, f, i, $r, c, data) { return !isNaN(e); },
								"N/A"          : function(e, n, f, i, $r, c, data) { return isNaN(e); },
							},
						  },
						}
					  });
					  
						if ( $('.focus-highlight').length ) {
							$('.focus-highlight').find('td, th')
							  .attr('tabindex', '1')
							  // add touch device support
							  .on('touchstart', function() {
								$(this).focus();
							  });
						}

					}); 
					
					// Toggle collapse on collapse class elements, with a elements of permalink class on table rows. Not in use.
					//animating = false;
					//clicked = false;
					//$('.collapsible').hide();
					//$('a.permalink').click(function(){
					//	var $el = $(this);
					//	setTimeout(function(){
					//		if (!animating &amp;&amp; !clicked) {
					//			animating = true;
					//			$el.closest('tr').find('.collapsible').slideToggle();
					//			setTimeout(function(){ animating = false; }, 200);
					//		}
					//	}, 200);
					//	return false;
					//});

				</script>
			</HEAD>
			<BODY>
				<TABLE class="tablesorter hover-highlight focus-highlight">
					<CAPTION>Food and Drinks (<a href="https://github.com/dcsobral/7d2d/blob/master/foodPlus.xsl" target="_blank">xslt</a>)</CAPTION>
					<THEAD>
						<TR>
							<TH>Item</TH>
							<xsl:for-each select="$fields">
								<!-- Add a style for the comment of the last field in the header -->
								<xsl:choose>
									<xsl:when test="@name='Creative Mode'">
										<TH class="name CellWithComment" data-value="All|Player">
											<xsl:value-of select="@name"/>
											<div class="CellComment">
												<xsl:value-of select="@desc" disable-output-escaping="yes"/>
											</div>
										</TH>
									</xsl:when>
									<xsl:when test="@class">
										<TH>
											<xsl:attribute name="class">
												<xsl:value-of select="concat('name CellWithComment ', @class)"/>
											</xsl:attribute>
											<xsl:value-of select="@name"/>
											<div class="CellComment">
												<xsl:value-of select="@desc" disable-output-escaping="yes"/>
											</div>
										</TH>
									</xsl:when>
									<xsl:otherwise>
										<TH class="name CellWithComment">
											<xsl:value-of select="@name"/>
											<div class="CellComment">
												<xsl:value-of select="@desc" disable-output-escaping="yes"/>
											</div>
										</TH>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:for-each>
						</TR>
					</THEAD>
					<TBODY>
						<xsl:for-each select="$foods">
							<xsl:sort select="my:tolower(my:translate(@name))"/>
							<xsl:variable name="this" select="."/>
							<TR>
								<!-- Name -->
								<xsl:variable name="descriptionKey" select="my:getDescriptionKey($this)"/>
								<xsl:variable name="comment" select="my:translate($descriptionKey)"/>
								<TD class="name CellWithComment">
									<xsl:value-of select="my:translate(@name)"/>
									<div class="CellComment">
										<xsl:text>[</xsl:text><xsl:value-of select="@name"/><xsl:text>]</xsl:text>
										<xsl:if test="not($descriptionKey='No Description') and not ($comment=$descriptionKey)">
										<xsl:text> </xsl:text><xsl:value-of select="str:replace($comment, '\n', '&lt;br/>')" disable-output-escaping="yes"/>
										</xsl:if>
									</div>
								</TD>
								
								<!-- Gain_* -->
								<xsl:for-each select="exslt:node-set($gains)/*">
									<xsl:variable name="gain" select="my:getGain($this, @key)"/>
									<xsl:choose>
										<xsl:when test="@name='Wellness'">
											<TD class="decimal"><xsl:value-of select="format-number($gain, '0.00')"/></TD>
										</xsl:when>
										<xsl:otherwise>
											<TD class="integer"><xsl:value-of select="$gain"/></TD>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:for-each>
								
								<!-- Crafted
								<TD>
									<xsl:choose>
										<xsl:when test="my:isCrafted($this)">
											<xsl:text>Yes</xsl:text>
										</xsl:when>
										<xsl:otherwise>
											<xsl:text>No</xsl:text>
										</xsl:otherwise>
									</xsl:choose>
								</TD>
								-->
								
								<!-- Harvested -->
								<TD>
									<xsl:choose>
										<xsl:when test="my:isHarvested($this)">
											<xsl:text>Yes</xsl:text>
										</xsl:when>
										<xsl:otherwise>
											<xsl:text>No</xsl:text>
										</xsl:otherwise>
									</xsl:choose>
								</TD>
								
								<!-- GreenThumb level -->
								<TD>
									<xsl:variable name="seed" select="$seedRecipes[ingredient[@name=$this/@name]]/@name"/>
									<xsl:choose>
										<xsl:when test="not($seed)">
											<xsl:text>N/A</xsl:text>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="$greenThumb[@name=$seed]/@unlock_level"/>
										</xsl:otherwise>
									</xsl:choose>
								</TD>
								
								<!-- Food/Wellness -->
								<TD class="decimal">
									<xsl:variable name="food" select="my:getGain($this, 'Gain_food')"/>
									<xsl:variable name="water" select="my:getGain($this, 'Gain_water')"/>
									<xsl:variable name="dividend" select="math:max(str:tokenize(concat($food, ' ', $water)))"/>
									<xsl:variable name="wellness" select="my:getGain($this, 'Gain_wellness')"/>
									<xsl:choose>
										<xsl:when test="$wellness>0">
											<xsl:value-of select="format-number($dividend div $wellness, '0.00')"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:text>N/A</xsl:text>
										</xsl:otherwise>
									</xsl:choose>
								</TD>
									
								<!-- Creative Mode -->
								<TD>
									<xsl:value-of select="my:creativeMode($this)"/>
								</TD>
								
								<!-- Craft areas -->
								<xsl:for-each select="exslt:node-set($foodCraftAreas)/*">
									<xsl:variable name="craftAreaName" select="@name"/>
									<xsl:variable name="craftArea" select="@key"/>
									<xsl:variable name="dialogId" select="concat($craftArea, '-', $this/@name)"/>
									<xsl:for-each select="$recipes">
										<TD>
											<xsl:choose>
												<xsl:when test="$craftArea='Hand' and key('recipe', $this/@name)[not(@craft_area)]">
													<xsl:variable name="theseRecipes" select="key('recipe', $this/@name)[not(@craft_area)]"/>
													<a href="#" class="permalink">
														<xsl:attribute name="target-dialog">
															<xsl:value-of select="concat('#', $dialogId)"/>
														</xsl:attribute>
														<xsl:text>Yes</xsl:text>
													</a>
													<div class="dialog">
														<xsl:attribute name="title">
															<xsl:text>Recipes for </xsl:text><xsl:value-of select="my:translate($this/@name)"/><xsl:text> at </xsl:text><xsl:value-of select="$craftAreaName"/>
														</xsl:attribute>
														<xsl:attribute name="id">
															<xsl:value-of select="$dialogId"/> 
														</xsl:attribute>
														<xsl:value-of select="my:recipeList($theseRecipes)" disable-output-escaping="yes"/>
													</div>
												</xsl:when>
												<xsl:when test="key('recipe', $this/@name)[@craft_area=$craftArea]">
													<xsl:variable name="theseRecipes" select="key('recipe', $this/@name)[@craft_area=$craftArea]"/>
													<a href="#" class="permalink">
														<xsl:attribute name="target-dialog">
															<xsl:value-of select="concat('#', $dialogId)"/>
														</xsl:attribute>
														<xsl:text>Yes</xsl:text>
													</a>
													<div class="dialog">
														<xsl:attribute name="title">
															<xsl:text>Recipes for </xsl:text><xsl:value-of select="my:translate($this/@name)"/><xsl:text> at </xsl:text><xsl:value-of select="$craftAreaName"/>
														</xsl:attribute>
														<xsl:attribute name="id">
															<xsl:value-of select="$dialogId"/> 
														</xsl:attribute>
														<xsl:value-of select="my:recipeList($theseRecipes)" disable-output-escaping="yes"/>
													</div>
												</xsl:when>
												<xsl:otherwise>
													<xsl:text>No</xsl:text>
												</xsl:otherwise>
											</xsl:choose>
										</TD>
									</xsl:for-each>
								</xsl:for-each>
							</TR>
						</xsl:for-each>
					</TBODY>
				</TABLE>
				<script>
					$(".dialog")
						.dialog({ autoOpen: false, show:true, hide: true })
						.dialog({ classes: {
							"ui-dialog": "tablesorter-blue-override",
							"ui-dialog-titlebar": "tablesorter-blue-header",
							"ui-dialog-content": "tablesorter-blue-td",
						}
					});
					$('a.permalink').click(function(){
						var $el = $(this);
						$($el.attr('target-dialog')).dialog({
							position: { my: "center top", at: "center bottom+25%", of: $el }
						}).dialog("open");
					});
				</script>
			</BODY>
		</HTML>
	</xsl:template>
</xsl:stylesheet>
