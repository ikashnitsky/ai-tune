$blobs     = "C:\Users\DstMove\.ollama\models\blobs"
$manifests = "C:\Users\DstMove\.ollama\models\manifests\registry.ollama.ai\library"
$lmTarget  = "C:\Users\DstMove\.lmstudio\models\lmstudio-community"

New-Item -ItemType Directory -Force -Path $lmTarget | Out-Null

Get-ChildItem -Recurse -File $manifests | ForEach-Object {
    try {
        $manifest  = Get-Content $_.FullName -Raw | ConvertFrom-Json
        $modelName = "$($_.Directory.Name)-$($_.BaseName)"
        $modelDir  = Join-Path $lmTarget $modelName
        New-Item -ItemType Directory -Force -Path $modelDir | Out-Null

        $manifest.layers |
            Where-Object { $_.mediaType -like "*model*" } |
            ForEach-Object {
                $blobFile = $_.digest -replace ":", "-"
                $blobPath = Join-Path $blobs $blobFile
                $linkPath = Join-Path $modelDir "$modelName.gguf"

                if ((Test-Path $blobPath) -and -not (Test-Path $linkPath)) {
                    New-Item -ItemType HardLink -Path $linkPath -Target $blobPath | Out-Null
                    Write-Host "Linked: $modelName"
                }
            }
    } catch {
        Write-Warning "Skipped $($_.Name): $_"
    }
}
Write-Host "Done."
