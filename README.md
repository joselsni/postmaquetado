# postmaquetado

Script de PowerShell para aplicar la postmaquetación de un perfil de usuario.

## Uso

Ejecuta el script desde PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\postmaquetado.ps1
```

El script carga los datos de perfil desde `C:\ProgramData\ITX\Cache\ProfileData.json` si no se les pasa un objeto `ProfileData` por parámetro.

## Ejemplos

### 1. Ejecutar con el snapshot local

```powershell
powershell -ExecutionPolicy Bypass -File .\postmaquetado.ps1
```

### 2. Ejecutar con un objeto de perfil cargado en memoria

```powershell
$ProfileData = Get-Content .\ProfileData.json | ConvertFrom-Json
./postmaquetado.ps1 -ProfileData $ProfileData
```

## Requisitos

- PowerShell 5.1 o superior
- Acceso a `C:\ProgramData\ITX\Cache\ProfileData.json` cuando se usa el flujo por snapshot
- Permisos para crear unidades de red, instalar impresoras y ejecutar el launcher de GUI

## Notas

- El script deja un marcador en el registro `HKCU:\Software\Inditex` para no volver a ejecutarse por usuario.
- El log se guarda en `C:\ProgramData\ITX\Logs\Inditex.cloud.log`.

## Contribuir

1. Haz un fork del repositorio.
2. Crea una rama con tu cambio.
3. Abre un Pull Request.
