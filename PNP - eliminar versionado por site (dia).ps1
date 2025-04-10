Write-Host "Connecting to SharePoint Online using PnP PowerShell..." -ForegroundColor Yellow
$siteURL = Read-Host "Please enter Site URL"
$maxDays = Read-Host "Please enter the maximum number of days to keep versions"
# Convertir el valor de días a entero y calcular la fecha límite
$maxDays = [int]$maxDays
$cutoffDate = (Get-Date).AddDays(-$maxDays)
Write-Host "Se eliminarán las versiones anteriores a $cutoffDate" -ForegroundColor Yellow
 
# Conectar a SharePoint con autenticación moderna y manejo de errores
try {
    Connect-PnPOnline -Url $siteURL -UseWebLogin -ErrorAction Stop
} catch {
    Write-Host "Error al conectar a SharePoint: $_" -ForegroundColor Red
    exit
}
 
# Array para almacenar los archivos procesados
$filesProcessed = @()
 
# Obtener todas las librerías de documentos del sitio (BaseTemplate 101 y no ocultas)
$libraries = Get-PnPList | Where-Object { $_.BaseTemplate -eq 101 -and $_.Hidden -eq $false }
 
foreach ($library in $libraries) {
    Write-Host "Procesando la librería: $($library.Title)" -ForegroundColor Magenta
    # Obtener todos los elementos que sean archivos
    $files = Get-PnPListItem -List $library.Title -PageSize 1000 | Where-Object { $_.FieldValues.FileRef }
    foreach ($file in $files) {
        # Intentar obtener las versiones del archivo (se envuelve en try para manejar errores en caso de que no tenga versiones)
        try {
            $fileVersions = Get-PnPFileVersion -Url $file.FieldValues.FileRef
        } catch {
            Write-Host "No se pudieron obtener versiones para $($file.FieldValues.FileLeafRef): $_" -ForegroundColor Red
            continue
        }
        # Filtrar las versiones cuya fecha de creación sea anterior a la fecha límite
        $versionsToDelete = $fileVersions | Where-Object { $_.Created -lt $cutoffDate }
        if ($versionsToDelete.Count -gt 0) {
            foreach ($versionToDelete in $versionsToDelete) {
                Write-Host "Eliminando versión $($versionToDelete.VersionLabel) (creada el $($versionToDelete.Created)) del archivo $($file.FieldValues.FileLeafRef) en la librería $($library.Title)..." -ForegroundColor Cyan
                Remove-PnPFileVersion -Url $file.FieldValues.FileRef -Identity $versionToDelete.ID -Force
            }
            # Agregar detalles del archivo procesado a la lista
            $filesProcessed += [PSCustomObject]@{
                SiteUrl         = $siteURL
                Library         = $library.Title
                FileName        = $file.FieldValues.FileLeafRef
                FileUrl         = $file.FieldValues.FileRef
                VersionsRemoved = $versionsToDelete.Count
            }
        }
    }
}
 
# Exportar los archivos procesados a un CSV
$filesProcessed | Export-Csv -Path ".\VersionTrimmer.csv" -NoTypeInformation -Encoding utf8
 
# Desconectar de SharePoint Online
Disconnect-PnPOnline
Write-Host "Finished" -ForegroundColor Green
