<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:template match="/">
		<html>
			<body>
				<ul>
					<xsl:for-each select="//quest[objective/@type='Fetch']">
						<li><xsl:value-of select="@subtitle_key"/> (<xsl:value-of select="@id"/>)
						<ul>
							<xsl:for-each select="objective[@type='Fetch']"><li><xsl:value-of select="@id"/></li></xsl:for-each>
						</ul>
						</li>
					</xsl:for-each>
				</ul>
			</body>
		</html>
	</xsl:template>
</xsl:stylesheet>
