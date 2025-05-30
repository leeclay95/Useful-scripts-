# PowerShell Interactive Tool for Tenable Dashboard XML Manipulation
# Applies find/replace ONLY to selected dashboard/components, with match count and confirmation

# Decode and show definitions (FULL output, preview)

$decodedDefs = @{}
foreach ($name in $selectedNames) {
    $comp = $components | Where-Object { $_.name -eq $name }
    $b64 = $comp.definition
    $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($b64))
    $decodedDefs[$name] = $decoded
    Write-Host "`nDecoded definition for ${name}:"
    Write-Host $decoded
}

# Find and Replace (only for selected)
$find = Read-Host "`nEnter the text to find (exact match)"

$replace = Read-Host "Enter the replacement text"

$totalMatches = 0
$matchDetails = @{}

foreach ($name in $selectedNames) {
    $text = $decodedDefs[$name]
    $matches = [regex]::Matches($text, [regex]::Escape($find))
    $numMatches = $matches.Count
    $matchDetails[$name] = $numMatches
    $totalMatches += $numMatches
}

Write-Host "`n==== MATCH COUNT ===="
foreach ($name in $selectedNames) {
    Write-Host "${name}: $($matchDetails[$name]) match(es) found."
}
Write-Host "Total matches across selected: $totalMatches"
Write-Host "====================="

if ($totalMatches -eq 0) {
    Write-Host "No matches found. Exiting."
    exit 0
}

$proceed = Read-Host "`nProceed to replace ALL matches in selected dashboards/components? (yes/no)"
if ($proceed -ne "yes") {
    Write-Host "No changes made."
    exit 0
}

$changes = @()

foreach ($name in $selectedNames) {
    $orig = $decodedDefs[$name]
    $mod = $orig -replace [regex]::Escape($find), $replace
    if ($orig -ne $mod) {
        $changes += [PSCustomObject]@{
            Name   = $name
            Before = $orig
            After  = $mod
        }
    }
    # Save the modified definition (base64 re-encode) to the XML
    ($components | Where-Object { $_.name -eq $name }).definition = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($mod))
}

# Show changes for preview
foreach ($change in $changes) {
    Write-Host "`nChange detected in: $($change.Name)"
    Write-Host "Before:"
    Write-Host $change.Before
    Write-Host "After:"
    Write-Host $change.After
}

# Confirm and save
$confirm = Read-Host "`nType 'yes' to save changes and re-encode XML, or anything else to abort"

if ($confirm -eq "yes") {
    $outPath = "$xmlPath.modified.xml"
    $xml.Save($outPath)
    Write-Host "`nSaved modified XML as: $outPath"
} else {
    Write-Host "No changes saved."
}


