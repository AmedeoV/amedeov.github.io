param(
    [string]$IP = "169.254.137.185",
    [string]$System,
    [string]$SysDisplay
)

$bDir = "\\$IP\share\roms\$System"
$outDir = "d:\Projects\amedeov.github.io\images\games\$System"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$content = Get-Content "d:\Projects\amedeov.github.io\src\pi4-game-library.html" -Raw
$gm = [regex]::Matches($content, ('\{"System":"' + $SysDisplay + '","Name":"([^"]+)"\}'))
$gameNames = $gm | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

$imgLookup = @{}
$vidLookup = @{}

foreach ($f in @(Get-ChildItem "$bDir\images" -File -EA SilentlyContinue)) {
    if ($f.Name -match '-image\.') {
        $prefix = $f.Name -replace '\s*[\(\[].*$', '' -replace '-image\..*$', ''
        if (-not $imgLookup.ContainsKey($prefix)) { $imgLookup[$prefix] = $f.FullName }
    }
}
foreach ($f in @(Get-ChildItem "$bDir\videos" -File -EA SilentlyContinue)) {
    if ($f.Name -match '-video\.') {
        $prefix = $f.Name -replace '\s*[\(\[].*$', '' -replace '-video\..*$', ''
        if (-not $vidLookup.ContainsKey($prefix)) { $vidLookup[$prefix] = $f.FullName }
    }
}

Write-Output "Lookup: $($imgLookup.Count) imgs, $($vidLookup.Count) vids"

$matched = 0
$copied = 0
foreach ($name in $gameNames) {
    if ($imgLookup.ContainsKey($name)) {
        $slug = ($name -replace '[^a-zA-Z0-9]+', '-').ToLower().Trim('-')
        if (-not (Test-Path "$outDir\$slug.png")) {
            try { Copy-Item $imgLookup[$name] "$outDir\$slug.png" -Force -EA Stop; $copied++ }
            catch { Write-Warning "Failed img: $name - $_" }
        }
        if ($vidLookup.ContainsKey($name) -and -not (Test-Path "$outDir\$slug.mp4")) {
            try { Copy-Item $vidLookup[$name] "$outDir\$slug.mp4" -Force -EA Stop; $copied++ }
            catch { Write-Warning "Failed vid: $name - $_" }
        }
        $matched++
    }
}
Write-Output "$System done: matched $matched / $($gameNames.Count), copied $copied new files"
