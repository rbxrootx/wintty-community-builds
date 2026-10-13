# Wintty Community Builds

This repository builds free, **unofficial** Windows binaries from the public
[`deblasis/wintty`](https://github.com/deblasis/wintty) source. It is not
affiliated with that project or with Ghostty. The source project is MIT
licensed; its license and third-party notices are included in each package.

## Downloads

Each successful build produces:

- `Wintty-community-<source-sha>-x64-setup.exe`: per-user installer with an
  uninstaller and Start menu shortcut.
- `Wintty-community-<source-sha>-x64.zip`: portable app; extract and run
  `Wintty\Wintty.exe`.
- `SHA256SUMS.txt`: checksums for both downloads.

These builds are unsigned. Windows may show a SmartScreen warning. Check the
source commit and SHA-256 hash before running a download. The app requires
Windows 11 x64 and a DirectX 12 feature-level 12.0 GPU. There is no automatic
in-app update service for these packages; install a newer release manually.

## Automation

The [build workflow](.github/workflows/build-and-release.yml) checks the
upstream `windows` branch every Sunday. If its commit has not been released,
the workflow builds `ghostty.dll`, publishes the WinUI app as self-contained
NativeAOT, creates both packages, and publishes a GitHub prerelease. Each tag
is keyed to the upstream source commit, so repeated checks do not publish
duplicates. You can also run the workflow manually with a source branch, tag,
or commit. Turn off **publish_release** to keep the output as a workflow
artifact only.

The workflow uses Zig 0.16.0, .NET SDK 10.0.401, a Windows runner with Visual
Studio 2026, and Inno Setup 6. It first builds with the committed NuGet lock
files. NativeAOT publishing needs `win-x64` entries missing from the current
upstream lock files, so that step restores them in its disposable checkout.

## Local packaging

After building `zig-out/lib/ghostty.dll` and publishing
`windows/Ghostty/Ghostty.csproj` for `win-x64`, run:

```powershell
./scripts/Package.ps1 `
  -SourceDir C:\path\to\wintty `
  -PublishedDir C:\path\to\published-app `
  -OutputDir .\artifacts `
  -SourceSha (git -C C:\path\to\wintty rev-parse HEAD) `
  -IsccPath 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe'
```

`OutputDir` must be new so an old artifact cannot be mistaken for the current
build. Inno Setup's [command-line compiler](https://jrsoftware.org/ishelp/topic_compilercmdline.htm)
packages the app without changing the upstream source.
