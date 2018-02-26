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
	
	<xsl:variable name="localization" select="document('Localization.xml')"/>
	<xsl:variable name="blocks" select="document('blocks.xml')/blocks/block/property[@name='LootList']"/>
	<xsl:variable name="entities" select="document('entityclasses.xml')/entity_classes/entity_class/property[@name='LootListOnDeath']"/>

	<xsl:template match="/lootcontainers">
		<HTML>
			<HEAD>
				<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/1.10.16/css/jquery.dataTables.min.css"/>
				<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/buttons/1.5.1/css/buttons.dataTables.min.css"/>
				<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/fixedcolumns/3.2.4/css/fixedColumns.dataTables.min.css"/>
				<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/scroller/1.4.4/css/scroller.dataTables.min.css"/>
				<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/select/1.2.5/css/select.dataTables.min.css"/>
				<STYLE>
					caption: { 
						text-align: left; 
					}
					
					th {
						width: auto;
					}

					thead th { 
						text-align: center; 
					}

					tfoot th { 
						text-align: left; 
					}
					
					td.long {
						font-size: x-small;
					}
						
				</STYLE>
				<script
					src="https://code.jquery.com/jquery-1.12.4.min.js"
					integrity="sha256-ZosEbRLbNQzLpnKIkEdrPv7lOy9C27hHQ+Xp8a4MxAQ="
					crossorigin="anonymous">
				</script>
				
				<script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/jszip/2.5.0/jszip.min.js"/>
				<script type="text/javascript" src="https://cdn.datatables.net/1.10.16/js/jquery.dataTables.min.js"/>
				<script type="text/javascript" src="https://cdn.datatables.net/buttons/1.5.1/js/dataTables.buttons.min.js"/>
				<script type="text/javascript" src="https://cdn.datatables.net/buttons/1.5.1/js/buttons.colVis.min.js"/>
				<script type="text/javascript" src="https://cdn.datatables.net/buttons/1.5.1/js/buttons.html5.min.js"/>

				<script type="text/javascript" src="https://cdn.datatables.net/fixedcolumns/3.2.4/js/dataTables.fixedColumns.min.js"/>
				<script type="text/javascript" src="https://cdn.datatables.net/scroller/1.4.4/js/dataTables.scroller.min.js"/>
				<script type="text/javascript" src="https://cdn.datatables.net/select/1.2.5/js/dataTables.select.min.js"/>	
				<xsl:variable name="apos">'</xsl:variable>
				<xsl:variable name="aposEscaped">\'</xsl:variable>
				<xsl:variable name="lookup" select="my:allGroups(/lootcontainers/lootgroup, /..)"/>
				<xsl:variable name="result" select="my:allContainers(/lootcontainers/lootcontainer, /.., $lookup)"/>
				<xsl:element name="script">
					<xsl:text>
						var blocks = [];
						var entities = [];
						var percentageRendered = $.fn.dataTable.render.number( ',', '.', 4, '', ' %' );
						$(function() {
							var containers = [];
							var count;
					</xsl:text>
					<xsl:for-each select="$result/container">
						<xsl:variable name="id" select="@id"/>
						<xsl:text>count = 0;&#10;</xsl:text>
						<xsl:text>containers[</xsl:text>
						<xsl:value-of select="$id"/>
						<xsl:text>] = [];</xsl:text>
						<xsl:text>blocks[</xsl:text>
						<xsl:value-of select="$id"/>
						<xsl:text>] = '</xsl:text>
						<xsl:value-of select="str:replace(my:blocksFor($id), $apos, $aposEscaped)"/>
						<xsl:text>';</xsl:text>
						<xsl:text>entities[</xsl:text>
						<xsl:value-of select="$id"/>
						<xsl:text>] = '</xsl:text>
						<xsl:value-of select="str:replace(my:entitiesFor($id), $apos, $aposEscaped)"/>
						<xsl:text>';</xsl:text>
						<xsl:for-each select="item">
							<xsl:text>containers[</xsl:text>
							<xsl:value-of select="$id"/>
							<xsl:text>][count++]=['</xsl:text>
							<xsl:value-of select="str:replace(@desc, $apos, $aposEscaped)"/>
							<xsl:text>', </xsl:text>
							<xsl:value-of select="@chance"/>
							<xsl:text>, '</xsl:text>
							<xsl:value-of select="@source"/>
							<xsl:text>'];&#10;</xsl:text>
						</xsl:for-each>
					</xsl:for-each>
					<xsl:text>
							var data = [];
							containers.forEach(function (container, id) {
								var probabilities = new Map();
								var sources = new Map();
								container.forEach(function (itemData) {
									var item = itemData[0];
									var probability = itemData[1];
									var source = itemData[2];
									
									if (!probabilities.has(itemData[0])) {
										probabilities.set(item, 0);
										sources.set(item, new Set());
									}
									
									probabilities.set(item, probabilities.get(item) + probability);
									sources.set(item, sources.get(item).add(source));
								});
								probabilities.forEach(function (probability, item) {
									data.push([item, id, probability, Array.from(sources.get(item)).join(', ')]);
								});
							});
						
						
							$('table tfoot th').each( function (i) {
								var title = $('table thead th').eq( $(this).index() ).text();
								$(this).html( '&lt;input type="text" placeholder="Search '+title+'" data-index="'+i+'" />' );
							});

							var table = $('table').DataTable({
								buttons: [ 
									{
										text: 'Reset',
										action: function ( e, dt, node, config ) {
											$('input').val('');
											dt.columns().search('');
											dt
												.search('')
												.order([[ 1, 'asc' ], [ 2, 'desc' ], [0, 'asc'], [3, 'asc']])
												.draw();
										}
									},
									{
										extend: 'colvis',
										text: 'Columns',
										columns: ':not(.key)',
										autoClose: true,
										postfixButtons: [
												{
													extend: 'columnVisibility',
													text: 'Show All',
													visibility: true,
													columns: ':not(.key)'
												},
										],
									},
									{
										extend: 'collection',
										text: 'Export',
										autoClose: true,
										buttons: [ 'copy', 'csv', 'excel', ],
									},
								],
								columnDefs: [
									{ className: "dt-body-right", targets: 'number' },
									{ className: "dt-body-left name", targets: 'name' },
									{ className: "dt-body-left long", visible: false, targets: 'long' },
									{ 
										targets: 'percentage',
										render: function (data, type, row, meta) {
											return percentageRendered.display(data * 100);
										},
									},
									{
										targets: 'blocks',
										data: null,
										render: function (data, type, row, meta) {
											return blocks[row[1]];
										},
									},
									{
										targets: 'entities',
										data: null,
										render: function (data, type, row, meta) {
											return entities[row[1]];
										},
									},
								],
								data: data,
								deferRender: true,
								dom: 'BfrtSi',
								fixedColumns:   {
									leftColumns: 3
								},
								order: [[ 1, 'asc' ], [ 2, 'desc' ], [0, 'asc'], [3, 'asc']],
								paging: true,
								processing: true,
								scrollCollapse: true,
								scroller: true,
								scrollX: true,
								scrollY: "80vh",
								select: true,
								stateSave: true,
							});

							// Filter event handler
							$( table.table().container() ).on( 'keyup', 'tfoot input', function () {
								table
									.column( $(this).data('index') )
									.search( this.value )
									.draw();
							});
						});
					</xsl:text>
				</xsl:element>
				<TITLE>Loot Chance of At Least One of</TITLE>
			</HEAD>
			<BODY>
				<TABLE id="main" class="compact cell-border nowrap stripe">
					<THEAD>
						<TR>
							<TH class="name">Item</TH>
							<TH class="number">Container</TH>
							<TH class="number percentage sorter-digit">Chance</TH>
							<TH class="long">Source</TH>
							<TH class="long blocks">Blocks</TH>
							<TH class="long entities">Entities</TH>
						</TR>
					</THEAD>
					<TFOOT>
						<TR>
							<TH>Item</TH>
							<TH>Container</TH>
							<TH>Chance</TH>
							<TH>Source</TH>
							<TH>Blocks</TH>
							<TH>Entities</TH>
						</TR>
					</TFOOT>
					<TBODY>
					</TBODY>
				</TABLE>
			</BODY>
		</HTML>
	</xsl:template>
</xsl:stylesheet>
