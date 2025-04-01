# Conectar a SharePoint Online usando PnP PowerShell
Write-Host "Conectando a SharePoint Online usando PnP PowerShell..." -ForegroundColor Yellow

$siteURL = Read-Host "Por favor, ingresa la URL del sitio"
# Define la carpeta o biblioteca que se desea procesar. Modifica esta variable según corresponda.
$folderUrl = "https://nietocorp.sharepoint.com/sites/Riseoflegends/Libreria%202"

# Calcular la fecha límite: versiones con más de 3 meses se eliminarán.
$cutoffDate = (Get-Date).AddMonths(-3)
Write-Host "Se eliminarán las versiones anteriores a $cutoffDate (más de 3 meses de antigüedad)" -ForegroundColor Yellow

# Conectar a SharePoint con autenticación moderna
Connect-PnPOnline -Url $siteURL -UseWebLogin

# Array para almacenar detalles de los archivos procesados
$filesProcessed = @()

# Obtener todos los archivos en la biblioteca o carpeta especificada
$files = Get-PnPListItem -List "Libreria 2" -PageSize 1000 | Where-Object { $_.FieldValues.FileRef -like "*$folderUrl*" }

foreach ($file in $files) {
    # Obtener todas las versiones del archivo
    $fileVersions = Get-PnPFileVersion -Url $file.FieldValues.FileRef
    # Filtrar las versiones cuya fecha de creación sea anterior a la fecha límite
    $versionsToDelete = $fileVersions | Where-Object { $_.Created -lt $cutoffDate }
    if ($versionsToDelete.Count -gt 0) {
        foreach ($version in $versionsToDelete) {
            Write-Host "Eliminando versión $($version.VersionLabel) del archivo $($file.FieldValues.FileLeafRef) (creada el $($version.Created))" -ForegroundColor Cyan
            Remove-PnPFileVersion -Url $file.FieldValues.FileRef -Identity $version.ID -Force
        }
        # Registrar detalles del archivo procesado
        $filesProcessed += [PSCustomObject]@{
            SiteUrl         = $siteURL
            FolderUrl       = $folderUrl
            FileName        = $file.FieldValues.FileLeafRef
            FileUrl         = $file.FieldValues.FileRef
            VersionsRemoved = $versionsToDelete.Count
        }
    }
}

# Exportar el reporte de archivos procesados a un CSV
$filesProcessed | Export-Csv -Path ".\VersionTrimmer_3Months.csv" -NoTypeInformation -Encoding utf8

# Desconectar de SharePoint Online
Disconnect-PnPOnline

Write-Host "Proceso completado" -ForegroundColor Green
 