<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                xmlns:exslt="http://exslt.org/common" 
				xmlns:math="http://exslt.org/math"
				xmlns:func="http://exslt.org/functions"
				xmlns:dyn="http://exslt.org/dynamic"
				xmlns:str="http://exslt.org/strings"
				xmlns:my="http://www.w3.org/2001/XMLSchema"
                version="1.0" extension-element-prefixes="exslt math dyn func str">
	<xsl:param name="language" select="'English'"/>
	<xsl:output omit-xml-declaration="no" indent="yes"/>
	<xsl:strip-space elements="*"/>
	
	<xsl:variable name="dummy-startup-messages">
		<xsl:message>Parameter 'language' set to '<xsl:value-of select="$language"/>'</xsl:message>
	</xsl:variable>
	
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

	<func:function name="my:isNumber">
		<xsl:param name="text"/>
		<func:result select="number($text)=$text"/>
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
	
	<func:function name="my:getOrDefault">
		<xsl:param name="string"/>
		<xsl:param name="default"/>
		<xsl:choose>
			<xsl:when test="string-length($string)=0">
				<func:result select="$default"/>
			</xsl:when>
			<xsl:when test="$string='all'">
				<func:result select="1"/>
			</xsl:when>
			<xsl:otherwise>
				<func:result select="$string"/>
			</xsl:otherwise>
		</xsl:choose>
	</func:function>
	
	<func:function name="my:combinedChance">
		<xsl:param name="min"/>
		<xsl:param name="max"/>
		<xsl:param name="chance"/>
		<xsl:choose>
			<xsl:when test="$min=$max">
				<func:result select="math:power($chance, $min)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="partial" select="math:power($chance, $min)"/>
				<func:result select="$partial + my:combinedChance($min + 1, $max, $chance)"/>
			</xsl:otherwise>
		</xsl:choose>
	</func:function>
	
	<func:function name="my:chance">
		<xsl:param name="baseChance"/>
		<xsl:param name="prob"/>
		<xsl:param name="min"/>
		<xsl:param name="max"/>
		<xsl:param name="count"/>
		<xsl:param name="isAll"/>
		<xsl:choose>
			<xsl:when test="$isAll">
				<func:result select="1"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="not(my:isNumber($min) and my:isNumber($max) and my:isNumber($prob) and my:isNumber($count) and my:isNumber($baseChance))">
					<xsl:message terminate="yes">
						Error: NaN instead of number
						Base: <xsl:value-of select="$baseChance"/>
						Prob: <xsl:value-of select="$prob"/>
						Min: <xsl:value-of select="$min"/>
						Max: <xsl:value-of select="$max"/>
						Count: <xsl:value-of select="$count"/>
						isAll: <xsl:value-of select="$isAll"/>
						Curr Node: <xsl:value-of select="my:printNode(.)"/>
					</xsl:message>
				</xsl:if>
				<xsl:variable name="chanceInGroup" select="$baseChance * $prob div $count"/>
				<xsl:variable name="noEventChance" select="1 - $chanceInGroup"/>
				<xsl:variable name="combinedChance" select="my:combinedChance($min, $max, $noEventChance)"/>
				<xsl:variable name="averagedChance" select="$combinedChance div ($max - $min + 1)"/>
				<xsl:variable name="positiveChance" select="1 - $averagedChance"/>
				<func:result select="$positiveChance"/>
			</xsl:otherwise>
		</xsl:choose>
	</func:function>

	<func:function name="my:prob">
		<xsl:param name="item"/>
		<xsl:choose>
			<xsl:when test="$item/@prob">
				<func:result select="$item/@prob"/>
			</xsl:when>
			<xsl:otherwise>
				<func:result select="1"/>
			</xsl:otherwise>
		</xsl:choose>
	</func:function>
	
	<func:function name="my:count">
		<xsl:param name="items"/>
		<xsl:param name="current" select="0"/>
		<xsl:param name="index" select="1"/>
		<xsl:variable name="currProb" select="my:prob($items[$index])"/>
		<xsl:choose>
			<xsl:when test="count($items)=0">
				<func:result select="0"/>
			</xsl:when>
			<xsl:when test="$index = count($items)">
				<func:result select="$currProb + $current"/>
			</xsl:when>
			<xsl:otherwise>
				<func:result select="my:count($items, $currProb + $current, $index + 1)"/>
			</xsl:otherwise>
		</xsl:choose>
	</func:function>
	
	<xsl:variable name="localization" select="document('Localization.xml')"/>

	<xsl:template match="/lootcontainers">
		<HTML>
			<HEAD>
				<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.12.1/themes/cupertino/jquery-ui.min.css" type="text/css"/>
				<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.29.4/css/theme.blue.css" type="text/css"/>
				<STYLE>
					.tablesorter {
						width: auto;
					}
					
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
					
					th {
						width: 80%;
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
					
					dl {
					  display: grid;
					  grid-template-columns: max-content auto;
					}

					dt {
					  grid-column-start: 1;
					}

					dd {
					  grid-column-start: 2;
					}
				
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
						sortList : [[1,1], [0,0]],
						widgets : ['zebra', 'stickyHeaders'],
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
						<xsl:apply-templates match="lootcontainer"/>
				<script>
					$('.row').each(function() {
					  var thisId = $(this).find('.id').text();
					  var sumVal = parseFloat($(this).find('.val').text());

					  var $rowsToGroup = $(this).nextAll('tr').filter(function() {
						return $(this).find('.id').text() === thisId;
					  });

					  $rowsToGroup.each(function() {
						sumVal += parseFloat($(this).find('.val').text());
						$(this).remove();
					  });

					  $(this).find('.val').text(sumVal.toFixed(4));
					});
				</script>
			</BODY>
		</HTML>
	</xsl:template>
	
	<xsl:template match="lootcontainer">
		<xsl:variable name="countString" select="my:getOrDefault(@count, '1')"/>
		<xsl:variable name="count" select="str:tokenize($countString, ',')"/>
		<xsl:variable name="min" select="math:min($count)"/>
		<xsl:variable name="max" select="math:max($count)"/>
		<xsl:variable name="items" select="item"/>
		<TABLE class="tablesorter hover-highlight focus-highlight">
			<CAPTION>Container <xsl:value-of select="@id"/> (<xsl:value-of select="$countString"/>)</CAPTION>
			<THEAD>
				<TR>
					<TH class="name">Item</TH>
					<TH class="name">Chance</TH>
				</TR>
			</THEAD>
			<TBODY>
				<xsl:variable name="itemCount" select="my:count($items)"/>
				<xsl:for-each select="$items">
					<xsl:call-template name="row">
						<xsl:with-param name="min" select="$min"/>
						<xsl:with-param name="max" select="$max"/>
						<xsl:with-param name="itemCount" select="$itemCount"/>
						<xsl:with-param name="isAll" select="$countString='all'"/>
						<xsl:with-param name="baseChance" select="1"/>
					</xsl:call-template>
				</xsl:for-each>
			</TBODY>
		</TABLE>
	</xsl:template>
	
	<xsl:template name="row">
		<xsl:param name="min"/>
		<xsl:param name="max"/>
		<xsl:param name="itemCount"/>
		<xsl:param name="isAll"/>
		<xsl:param name="baseChance"/>
		<!-- FIXME: lootprobtemplate must be taken into account -->
		<xsl:variable name="chance" select="my:chance($baseChance, my:prob(.), $min, $max, $itemCount, $isAll)"/>
		<xsl:choose>
			<xsl:when test="@name">
				<TR class="row">
					<TD class="name id"><xsl:value-of select="my:translate(@name)"/></TD>
					<TD class="decimal val"><xsl:value-of select="format-number($chance, '0.0000')"/></TD>
				</TR>
			</xsl:when>
			<xsl:otherwise>
				<xsl:message>Group <xsl:value-of select="@group"/></xsl:message>
				<!-- FIXME: Both item's count and lootgroup count should be taken into consideration -->
				<xsl:variable name="group" select="/lootcontainers/lootgroup[@name=current()/@group][1]"/>
				<xsl:variable name="countString" select="my:getOrDefault($group/@count, '1')"/>
				<xsl:variable name="count" select="str:tokenize($countString, ',')"/>
				<xsl:variable name="groupMin" select="math:min($count)"/>
				<xsl:variable name="groupMax" select="math:max($count)"/>
				<xsl:variable name="groupItems" select="$group/item"/>
				<xsl:variable name="groupItemCount" select="my:count($groupItems)"/>
				<xsl:for-each select="$groupItems">
					<xsl:call-template name="row">
						<xsl:with-param name="min" select="$groupMin"/>
						<xsl:with-param name="max" select="$groupMax"/>
						<xsl:with-param name="itemCount" select="$groupItemCount"/>
						<xsl:with-param name="isAll" select="$countString='all'"/>
						<xsl:with-param name="baseChance" select="$chance"/>
					</xsl:call-template>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>