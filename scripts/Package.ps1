[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $SourceDir,
    [Parameter(Mandatory)] [string] $PublishedDir,
    [Parameter(Mandatory)] [string] $OutputDir,
    [Parameter(Mandatory)] [string] $SourceSha,
    [Parameter(Mandatory)] [string] $IsccPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ($SourceSha -notmatch '^[0-9a-fA-F]{40}$') { throw 'SourceSha must be a full Git commit SHA.' }
$source = (Resolve-Path -LiteralPath $SourceDir).Path
$published = (Resolve-Path -LiteralPath $PublishedDir).Path
$iscc = (Resolve-Path -LiteralPath $IsccPath).Path
$builder = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
if (Test-Path -LiteralPath $OutputDir) { throw "OutputDir already exists: $OutputDir" }
foreach ($required in @('Wintty.exe', 'native\ghostty.dll', 'Assets\wintty.ico')) {
    if (-not (Test-Path -LiteralPath (Join-Path $published $required))) {
        throw "Published app is missing $required"
    }
}
foreach ($required in @('LICENSE', 'THIRD_PARTY_NOTICES.md')) {
    if (-not (Test-Path -LiteralPath (Join-Path $source $required))) {
        throw "Source is missing $required"
    }
}

$output = (New-Item -ItemType Directory -Path $OutputDir).FullName
$stage = (New-Item -ItemType Directory -Path (Join-Path $output 'stage\Wintty') -Force).FullName
$copyOutput = & robocopy $published $stage /E /XF *.pdb /NFL /NDL /NJH /NJS
if ($LASTEXITCODE -ge 8) { throw "robocopy failed with exit code $LASTEXITCODE`: $copyOutput" }
Copy-Item -LiteralPath (Join-Path $source 'LICENSE') -Destination $stage
Copy-Item -LiteralPath (Join-Path $source 'THIRD_PARTY_NOTICES.md') -Destination $stage
$shortSha = $SourceSha.Substring(0, 12).ToLowerInvariant()
$buildVersion = (Get-Date).ToUniversalTime().ToString('yyyy.M.d')
$builtUtc = (Get-Date).ToUniversalTime().ToString('u')
$buildInfo = @"
Wintty Community Build (unofficial)
Source: https://github.com/deblasis/wintty
Source commit: $SourceSha
Built (UTC): $builtUtc
Builder: https://github.com/$env:GITHUB_REPOSITORY

This is an unsigned source build. It is not affiliated with deblasis/wintty.
Requires Windows 11 x64 and a DirectX 12 feature-level 12.0 GPU.
There is no automatic update service; install a newer community release manually.
License and third-party notices are included in this directory.
"@
Set-Content -LiteralPath (Join-Path $stage 'BUILD_INFO.txt') -Value $buildInfo -Encoding utf8

$zipName = "Wintty-community-$shortSha-x64.zip"
$zipPath = Join-Path $output $zipName
Compress-Archive -LiteralPath $stage -DestinationPath $zipPath -CompressionLevel Optimal

$iss = Join-Path $builder 'installer\WinttyCommunity.iss'
& $iscc "-dStageDir=$stage" "-dOutputDir=$output" "-dSourceSha=$shortSha" "-dBuildVersion=$buildVersion" $iss
if ($LASTEXITCODE -ne 0) { throw "Inno Setup compilation failed with exit code $LASTEXITCODE" }
$setupName = "Wintty-community-$shortSha-x64-setup.exe"
$setupPath = Join-Path $output $setupName
if (-not (Test-Path -LiteralPath $setupPath)) { throw "Installer was not produced: $setupPath" }

$checksums = foreach ($file in @($zipPath, $setupPath)) {
    $hash = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash  $(Split-Path $file -Leaf)"
}
Set-Content -LiteralPath (Join-Path $output 'SHA256SUMS.txt') -Value $checksums -Encoding ascii
$notes = @"
## Unofficial Wintty source build

Built from [deblasis/wintty@$shortSha](https://github.com/deblasis/wintty/commit/$SourceSha).

- Windows 11 x64 and a DirectX 12 feature-level 12.0 GPU are required.
- The installer and portable ZIP contain a self-contained NativeAOT app, the Wintty license, third-party notices, and `BUILD_INFO.txt`.
- These binaries are unsigned and are not affiliated with the Wintty project. Verify them using `SHA256SUMS.txt`.
- This build does not include automatic updates. Install a newer release manually.
"@
Set-Content -LiteralPath (Join-Path $output 'RELEASE_NOTES.md') -Value $notes -Encoding utf8
Write-Host "Portable archive: $zipPath"
Write-Host "Installer: $setupPath"
Write-Host "Checksums: $(Join-Path $output 'SHA256SUMS.txt')"
