$ollamaManifests = "$env:USERPROFILE\.ollama\models\manifests\registry.ollama.ai"
$ollamaBlobs     = "$env:USERPROFILE\.ollama\models\blobs"
$lmStudioModels  = "$env:USERPROFILE\.lmstudio\models\ollama"

New-Item -ItemType Directory -Force -Path $lmStudioModels | Out-Null

Get-ChildItem -Recurse -File $ollamaManifests | ForEach-Object {
    $manifest = Get-Content $_.FullName | ConvertFrom-Json
    $modelName = "$($_.Directory.Name)-$($_.Name)" -replace ":", "-"
    $modelDir  = Join-Path $lmStudioModels $modelName
    New-Item -ItemType Directory -Force -Path $modelDir | Out-Null

    $manifest.layers | Where-Object { $_.mediaType -like "*gguf*" } | ForEach-Object {
        $blobHash = $_.digest -replace ":", "-"
        $blobPath = Join-Path $ollamaBlobs $blobHash
        $linkPath = Join-Path $modelDir "$modelName.gguf"

        if ((Test-Path $blobPath) -and -not (Test-Path $linkPath)) {
            New-Item -ItemType HardLink -Path $linkPath -Target $blobPath | Out-Null
            Write-Host "Linked: $modelName"
        }
    })
}
Write-Host "Done. Point LM Studio at: $lmStudioModels"
