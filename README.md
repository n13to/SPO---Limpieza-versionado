# 🚀 Limpieza de Versiones en SharePoint Online con PnP PowerShell 🧹

```markdown
Este script en PowerShell permite eliminar versiones antiguas de archivos en una biblioteca o carpeta específica de SharePoint Online. 📌 Existen dos variantes del script que se diferencian únicamente en la función utilizada para calcular la antigüedad de las versiones a eliminar: `AddMonths` (para filtrar por meses) y `AddDays` (para filtrar por días). 📆
```

## ⚙️ Requisitos ✅

- Tener instalado [PnP PowerShell](https://pnp.github.io/powershell/).
- Contar con permisos suficientes en SharePoint para eliminar versiones de archivos (Admin. Sharepoint + Admin de la coleccion de sitios).
- Powershell 7.5

## 🛠️ Funcionamiento del Script 

### 1. 🔗 Conexión a SharePoint Online 

```powershell
Write-Host "Conectando a SharePoint Online usando PnP PowerShell..." -ForegroundColor Yellow
$siteURL = Read-Host "Por favor, ingresa la URL del sitio"
Connect-PnPOnline -Url $siteURL -UseWebLogin
```

El usuario ingresa la URL del sitio de SharePoint y se conecta usando autenticación moderna. 

### 2. 📂 Definir la biblioteca o carpeta a limpiar 

```powershell
$folderUrl = "https://nietocorp.sharepoint.com/sites/Riseoflegends/Libreria%202"
```

Esta variable contiene la URL de la carpeta o biblioteca donde se ejecutará la limpieza. 

### 3. 📆 Definir la fecha de corte para eliminar versiones 

```powershell
$cutoffDate = (Get-Date).AddDays(-3)
Write-Host "Se eliminarán las versiones anteriores a $cutoffDate (más de 3 meses de antigüedad)" -ForegroundColor Yellow
```

Aquí se establece que solo se eliminarán versiones creadas antes de la fecha límite. ❗

Si se desea cambiar el criterio de tiempo, se puede modificar la línea de `AddDays(-3)` a `AddMonths(-3)` para trabajar con meses en lugar de días. 

### 4. 📜 Obtener archivos en la biblioteca y filtrar versiones antiguas 

```powershell
$files = Get-PnPListItem -List "Libreria 2" -PageSize 1000 | Where-Object { $_.FieldValues.FileRef -like "*$folderUrl*" }

foreach ($file in $files) {
    $fileVersions = Get-PnPFileVersion -Url $file.FieldValues.FileRef
    $versionsToDelete = $fileVersions | Where-Object { $_.Created -lt $cutoffDate }
```

Se listan los archivos en la carpeta especificada y se filtran sus versiones cuya fecha de creación sea anterior al `cutoffDate`. 

### 5. 🗑️ Eliminar versiones antiguas 

```powershell
if ($versionsToDelete.Count -gt 0) {
    foreach ($version in $versionsToDelete) {
        Write-Host "Eliminando versión $($version.VersionLabel) del archivo $($file.FieldValues.FileLeafRef) (creada el $($version.Created))" -ForegroundColor Cyan
        Remove-PnPFileVersion -Url $file.FieldValues.FileRef -Identity $version.ID -Force
    }
```

Si hay versiones a eliminar, se eliminan y se muestra un mensaje en la consola con los detalles. 

### 6. 📝 Registro de archivos procesados 

```powershell
$filesProcessed += [PSCustomObject]@{
    SiteUrl         = $siteURL
    FolderUrl       = $folderUrl
    FileName        = $file.FieldValues.FileLeafRef
    FileUrl         = $file.FieldValues.FileRef
    VersionsRemoved = $versionsToDelete.Count
}
```

Se almacena un registro con los detalles de los archivos procesados, incluyendo cuántas versiones fueron eliminadas. 

### 7. 📊 Exportar el reporte a CSV 

```powershell
$filesProcessed | Export-Csv -Path ".\VersionTrimmer_3Months.csv" -NoTypeInformation -Encoding utf8
```

Se exporta la información a un archivo CSV para su posterior análisis. 

### 8. 🔌 Desconexión de SharePoint Online 

```powershell
Disconnect-PnPOnline
Write-Host "Proceso completado" -ForegroundColor Green
```

Al finalizar, se cierra la conexión con SharePoint Online. 

## 🛠️ Personalización 

Para cambiar el período de eliminación:

- Para eliminar versiones más antiguas de **3 meses**, modificar:
  ```powershell
  $cutoffDate = (Get-Date).AddMonths(-3)
  ```
- Para eliminar versiones más antiguas de **90 días**, modificar:
  ```powershell
  $cutoffDate = (Get-Date).AddDays(-90)
  ```

## 🤝 Contribución ✨

Si deseas mejorar el script o añadir nuevas funcionalidades, eres bienvenido a contribuir en el repositorio. Puedes crear un **Pull Request** o abrir un **Issue** para sugerencias y mejoras. 🚀🔥

## 📜 Licencia 

Este script está bajo la licencia MIT. Puedes usarlo y modificarlo libremente bajo los términos de esta licencia.&#x20;



