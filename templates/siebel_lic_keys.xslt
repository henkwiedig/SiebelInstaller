<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output encoding="iso-8859-1" method="text"/>
    <xsl:template match="keytype">
      <xsl:if test="text()='All Inclusive'">
            <xsl:value-of select=".."/>
      </xsl:if>
    </xsl:template>
    <xsl:template match="text()" />
</xsl:stylesheet>
