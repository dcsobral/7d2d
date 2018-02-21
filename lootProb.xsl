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
	<xsl:output omit-xml-declaration="no" indent="no"/>
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
	
	<func:function name="my:listOf">
		<xsl:param name="nodes"/>
		<func:result>
			<xsl:for-each select="$nodes">
				<xsl:value-of select="my:translate(@name)"/>
				<xsl:if test="position()!=last()">
					<xsl:text>, </xsl:text>
				</xsl:if>
			</xsl:for-each>
		</func:result>
	</func:function>
	
	<func:function name="my:blocksFor">
		<xsl:param name="id"/>
		<xsl:variable name="filteredBlocks" select="$blocks[@value=$id]/.."/>
		<xsl:variable name="result" select="my:listOf($filteredBlocks)"/>
		<func:result select="$result"/>
	</func:function>
	
	<func:function name="my:entitiesFor">
		<xsl:param name="id"/>
		<xsl:variable name="result" select="my:listOf($entities[@value=$id]/..)"/>
		<func:result select="$result"/>
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
	
	<func:function name="my:source">
		<xsl:param name="group"/>
		<xsl:variable name="source" select="concat(name($group), ' ', $group/@*[1])"/>
		<func:result select="$source"/>
	</func:function>
	
	<func:function name="my:allContainers">
		<xsl:param name="containers"/>
		<xsl:param name="accumulator"/>
		<xsl:param name="lookup"/>
		<xsl:param name="index" select="1"/>
		<xsl:variable name="container" select="$containers[$index]"/>
		<xsl:variable name="next" select="$index+1"/>
		<xsl:variable name="partial" select="exslt:node-set(my:containerProbabilities($container, 1, $lookup))"/>
		<xsl:variable name="nextAcc" select="$accumulator|$partial"/>
		<xsl:choose>
			<xsl:when test="$index=count($containers)">
				<func:result select="$nextAcc"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="result" select="my:allContainers($containers, $nextAcc, $lookup, $next)"/>
				<func:result select="$result"/>
			</xsl:otherwise>
		</xsl:choose>
		
	</func:function>
	
	<func:function name="my:allGroups">
		<xsl:param name="groups"/>
		<xsl:param name="accumulator"/>
		<xsl:param name="index" select="1"/>
		<xsl:variable name="group" select="$groups[$index]"/>
		<xsl:variable name="next" select="$index+1"/>
		<xsl:variable name="partial" select="exslt:node-set(my:groupProbabilities($group, 1, $accumulator))"/>
		<xsl:variable name="nextAcc" select="$accumulator|$partial"/>
		<xsl:choose>
			<xsl:when test="$index=count($groups)">
				<func:result select="$nextAcc"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="result" select="my:allGroups($groups, $nextAcc, $next)"/>
				<func:result select="$result"/>
			</xsl:otherwise>
		</xsl:choose>
	</func:function>

	<func:function name="my:containerProbabilities">
		<xsl:param name="container"/>
		<xsl:param name="baseChance"/>
		<xsl:param name="lookup"/>
		<func:result>
			<container id="{$container/@id}">
				<xsl:copy-of select="exslt:node-set(my:setProbabilities($container, $baseChance, $lookup))"/>
			</container>
		</func:result>
	</func:function>
	
	<func:function name="my:groupProbabilities">
		<xsl:param name="group"/>
		<xsl:param name="baseChance"/>
		<xsl:param name="lookup"/>
		<func:result>
			<group name="{$group/@name}">
				<xsl:copy-of select="exslt:node-set(my:setProbabilities($group, $baseChance, $lookup))"/>
			</group>
		</func:result>
	</func:function>
	
	<func:function name="my:setProbabilities">
		<xsl:param name="group"/>
		<xsl:param name="baseChance"/>
		<xsl:param name="lookup"/>
		<xsl:variable name="countString" select="my:getOrDefault($group/@count, '1')"/>
		<xsl:variable name="count" select="str:tokenize($countString, ',')"/>
		<xsl:variable name="min" select="math:min($count)"/>
		<xsl:variable name="max" select="math:max($count)"/>
		<xsl:variable name="items" select="$group/item"/>
		<xsl:variable name="itemCount" select="my:count($items)"/>
		<xsl:variable name="isAll" select="$countString='all'"/>
		<xsl:variable name="source" select="my:source($group)"/>
		<func:result>
			<xsl:for-each select="$items">
				<!-- FIXME: lootprobtemplate must be taken into account -->
				<xsl:variable name="chance" select="my:chance($baseChance, my:prob(.), $min, $max, $itemCount, $isAll)"/>
				<xsl:choose>
					<xsl:when test="@name">
						<item name="{@name}" desc="{my:translate(@name)}" chance="{$chance}" source="{$source}"/>
					</xsl:when>
					<xsl:when test="@group">
						<xsl:variable name="nestedGroup" select="exslt:node-set(my:nestedGroup(@group, $chance, $lookup))"/>
						<xsl:copy-of select="$nestedGroup"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:message terminate="yes">
							Unknown node type: <xsl:value-of select="my:printNode(.)"/>
							Location: <xsl:value-of select="$source"/>
						</xsl:message>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</func:result>
	</func:function>

	<func:function name="my:nestedGroup">
		<xsl:param name="groupName"/>
		<xsl:param name="chance"/>
		<xsl:param name="lookup"/>
		<xsl:variable name="group" select="$lookup/group[@name=$groupName]"/>
		<func:result>
			<xsl:for-each select="$group/*">
				<xsl:copy>
					<xsl:attribute name="name">
						<xsl:value-of select="@name"/>
					</xsl:attribute>
					<xsl:attribute name="desc">
						<xsl:value-of select="@desc"/>
					</xsl:attribute>
					<xsl:attribute name="chance">
						<xsl:value-of select="$chance * @chance"/>
					</xsl:attribute>
					<xsl:attribute name="source">
						<xsl:value-of select="@source"/>
					</xsl:attribute>
				</xsl:copy>
			</xsl:for-each>
		</func:result>
	</func:function>
	
	<func:function name="my:summarize">
		<xsl:param name="container"/>
		<func:result select="$container"/>
	</func:function>
	
	<xsl:variable name="localization" select="document('Localization.xml')"/>
	<xsl:variable name="blocks" select="document('blocks.xml')/blocks/block/property[@name='LootList']"/>
	<xsl:variable name="entities" select="document('entityclasses.xml')/entity_classes/entity_class/property[@name='LootListOnDeath']"/>

	<xsl:template match="/lootcontainers">
		<HTML>
			<HEAD>
				<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.12.1/themes/cupertino/jquery-ui.min.css" type="text/css"/>
				<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.29.5/css/theme.blue.css" type="text/css"/>
				<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.29.5/css/jquery.tablesorter.pager.min.css" type="text/css"/>
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
						width: auto;
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
				
				<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.29.5/js/jquery.tablesorter.min.js"/>
				<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.29.5/js/extras/jquery.tablesorter.pager.min.js"/>
				<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.29.5/js/jquery.tablesorter.widgets.min.js"/>
				
				<script>
					$(function() {

					  // Extend the themes to change any of the default class names
					  $.extend($.tablesorter.themes.jui, {
						table        : 'ui-widget ui-widget-content ui-corner-all',
						caption      : 'ui-widget-header ui-corner-all ui-state-default',
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
					  
					  var pagerOptions = {
						container: $(".pager"),
						// output string - default is '{page}/{totalPages}';
						// possible variables: {size}, {page}, {totalPages}, {filteredPages}, {startRow}, {endRow}, {filteredRows} and {totalRows}
						// also {page:input} and {startRow:input} will add a modifiable input in place of the value
						output: '{startRow} - {endRow} / {filteredRows} ({totalRows})',
						fixedHeight: true,
						// remove rows from the table to speed up the sort of large tables.
						// setting this to false, only hides the non-visible rows; needed if you plan to add/remove rows with the pager enabled.
						removeRows: false,
						size: 40,
						cssGoto: '.gotoPage',
						savePages: true,
						storageKey:'tablesorter-lootprob',
					  };

					  $("table").tablesorter({
						theme : 'blue',
						headerTemplate : '{content} {icon}',
						resort: false,
						// sortList: [ [2,0], [4,1], [0, 0] ],
						widgets : ['saveSort', 'filter', 'zebra', 'stickyHeaders'],
						widgetOptions : {
						  filter_saveFilters : true,
						  zebra   : ["even", "odd"],
						},
					  }).tablesorterPager(pagerOptions);
					  
					    $('button').click(function(){
							$.tablesorter.storage( $('table'), 'tablesorter-pager', '' );   // clear page/size
							$.tablesorter.storage( $('table'), 'tablesorter-filters', '' ); // clear filters
							$('table')
								.trigger('filterResetSaved')                  // clear saved filters
								.trigger('saveSortReset')                     // clear saved sort
								.trigger('filterReset')                       // reset current filters
								.trigger("sortReset")                         // reset current table sort
								.trigger('pageAndSize', [1, 30])              // set page to 1 and size to 30
								.trigger('update', [[[2,0], [4,1], [0, 0]]]); // reset sort order
							return false;
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
				</script>
			</HEAD>
			<BODY>
				<xsl:variable name="lookup" select="my:allGroups(/lootcontainers/lootgroup, /..)"/>
				<xsl:variable name="result" select="my:allContainers(/lootcontainers/lootcontainer, /.., $lookup)"/>
				<DIV class="pager">
					<img src="https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.29.5/css/images/first.png" class="first"/> 
					<img src="https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.29.5/css/images/prev.png" class="prev"/> 
					<span class="pagedisplay"></span> <!-- this can be any element, including an input --> 
					<img src="https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.29.5/css/images/next.png" class="next"/> 
					<img src="https://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.29.5/css/images/last.png" class="last"/> 
					<select class="pagesize" title="Select page size"> 
						<option value="10">10</option> 
						<option value="20">20</option> 
						<option selected="selected" value="30">30</option> 
						<option value="40">40</option> 
						<option value="100">100</option> 
						<option value="200">200</option> 
					</select>
					<select class="gotoPage" title="Select page number"></select>
					<button type="button reset">Reset</button>
					<span id="loading">Loading <span id="numItems">0</span> entries: <progress id="progress" value="0" max="100"/></span>
				</DIV>
				<TABLE class="tablesorter hover-highlight focus-highlight">
					<CAPTION>Loot Chance of At Least One of</CAPTION>
					<THEAD>
						<TR>
							<TH class="name">Item</TH>
							<TH class="name">Source</TH>
							<TH class="name">Container</TH>
							<TH class="name">Blocks and Entities</TH>
							<TH class="name sorter-digit">Chance</TH>
						</TR>
					</THEAD>
					<TBODY>
					</TBODY>
				</TABLE>
				<xsl:element name="script">
					<xsl:variable name="apos">'</xsl:variable>
					<xsl:variable name="aposEscaped">\'</xsl:variable>
					<xsl:text>var data = [];&#10;</xsl:text>
					<xsl:text>var count = 0;&#10;</xsl:text>
					<xsl:for-each select="$result/container">
						<xsl:variable name="id" select="@id"/>
						<xsl:variable name="summary" select="my:summarize(.)"/>
						<xsl:for-each select="$summary/item">
							<xsl:text>data[count++]='</xsl:text>
							<xsl:element name="TR">
								<xsl:attribute name="class"><xsl:text>row</xsl:text></xsl:attribute>
								<xsl:element name="TD">
									<xsl:value-of select="str:replace(@desc, $apos, $aposEscaped)"/>
								</xsl:element>
								<xsl:element name="TD">
									<xsl:value-of select="@source"/>
								</xsl:element>
								<xsl:element name="TD">
									<xsl:attribute name="class">integer</xsl:attribute>
									<xsl:value-of select="$id"/>
								</xsl:element>
								<xsl:element name="TD">
									<xsl:value-of select="str:replace(my:blocksFor($id), $apos, $aposEscaped)"/>
									<xsl:text> / </xsl:text>
									<xsl:value-of select="str:replace(my:entitiesFor($id), $apos, $aposEscaped)"/>
								</xsl:element>
								<xsl:element name="TD">
									<xsl:attribute name="class"><xsl:text>decimal</xsl:text></xsl:attribute>
									<xsl:value-of select="format-number(@chance * 100, '0.000000')"/>
									<xsl:text> %</xsl:text>
								</xsl:element>
							</xsl:element>
							<xsl:text>';&#10;</xsl:text>
						</xsl:for-each>
					</xsl:for-each>
					<xsl:text>
					function performTask(items, numToProcess, processItem) {
						$('#progress').attr('max', data.length);
						$('#numItems').text(data.length);
						var pos = 0;
						var $table = $( 'table' );
						var $tbody = $table.find('tbody');
						var currFilters = $.tablesorter.getFilters( $table );
						$table.trigger('filterReset');
						function iteration() {
							var j = Math.min(pos + numToProcess, items.length);
							for (var i = pos; i &lt; j; i++) {
								var $row = $(items[i]);
								$tbody.append($row).trigger( 'addRows', [ $row ] );
							}
							pos += numToProcess;
							if (pos &lt; items.length) {
								if ($.tablesorter.getFilters($table))
									$table.trigger('filterReset');
								$('#progress').val(pos);
								setTimeout(iteration, 1);
							} else {
								$.tablesorter.setFilters($table, currFilters);
								$table.trigger('update', [true]);
								$('#loading').hide();
							}
						}
						iteration();
					}
					performTask(data, 10);
					</xsl:text>
				</xsl:element>
			</BODY>
		</HTML>
	</xsl:template>
	
</xsl:stylesheet>

