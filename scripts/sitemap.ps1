$SITEMAP_WRITER = New-Object System.XMl.XmlTextWriter('public/sitemap.xml', $NULL)
$SITEMAP_WRITER.Formatting = 'Indented'

$SITEMAP_WRITER.WriteStartDocument()
$SITEMAP_WRITER.WriteComment('This is automatically generated by /scripts/sitemap.ps1, do not edit directly.')
$SITEMAP_WRITER.WriteStartElement('urlset')
$SITEMAP_WRITER.WriteAttributeString('xmlns', 'http://www.sitemaps.org/schemas/sitemap/0.9')

# Index page
$SITEMAP_WRITER.WriteStartElement('url')
$SITEMAP_WRITER.WriteElementString('loc', "https://munisign.org/")
$SITEMAP_WRITER.WriteElementString('changefreq', 'monthly')
$SITEMAP_WRITER.WriteElementString('priority', '1.0')
$SITEMAP_WRITER.WriteEndElement()

# Each stop ID.
$STOP_IDS = @"
    SELECT DISTINCT stop_code
    FROM "public/data/stop_times.csv"
    ORDER BY stop_code
"@
q -H '-d,' -O -C read $STOP_IDS | ConvertFrom-Csv | Foreach-Object {
    $SITEMAP_WRITER.WriteStartElement('url')
    $SITEMAP_WRITER.WriteElementString('loc', "https://munisign.org/$($_.stop_code)")
    $SITEMAP_WRITER.WriteElementString('changefreq', 'monthly')
    $SITEMAP_WRITER.WriteElementString('priority', '0.1')
    $SITEMAP_WRITER.WriteEndElement()
}

$SITEMAP_WRITER.WriteEndElement()
$SITEMAP_WRITER.Close()