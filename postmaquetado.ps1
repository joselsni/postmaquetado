param(
    [pscustomobject]$ProfileData,
    [string]$ProfileName,
    [switch]$Bootstrap
)

# ======================================
# Logs
# ======================================
$WorkingDir = "C:\ProgramData\ITX"
$LogsDir    = "$WorkingDir\Logs"
$LogFile    = "$LogsDir\Inditex.cloud.log"

function Write-Log($msg) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "[$timestamp] $msg"
}

Write-Log "===== POSTMAQUETADO (LOGIN $env:USERNAME) ====="

# ======================================
# MARCA DE EJECUCIÓN POR USUARIO
# ======================================
$KeyPath  = "HKCU:\Software\Inditex"
$FlagName = "PostMaquetadoDone"

if (-not (Test-Path $KeyPath)) {
    New-Item -Path $KeyPath -Force | Out-Null
}

$alreadyDone = (Get-ItemProperty -Path $KeyPath -Name $FlagName -ErrorAction SilentlyContinue).$FlagName
if ($alreadyDone -eq 1) {
    Write-Log "Este usuario ya ejecutó postmaquetado. Saliendo."
    exit 0
}

# ======================================
# CARGAR ProfileData si NO vino por parámetro
# (para usuarios nuevos / logons posteriores)
# ======================================
if (-not $ProfileData) {
    $CacheJson = "C:\ProgramData\ITX\Cache\ProfileData.json"
    if (Test-Path $CacheJson) {
        try {
            $jsonText = Get-Content -Path $CacheJson -Raw -ErrorAction Stop
            $ProfileData = $jsonText | ConvertFrom-Json -Depth 20
            Write-Log "ProfileData cargado desde snapshot local: $CacheJson"
        }
        catch {
            Write-Log "ERROR cargando snapshot local ($CacheJson): $_"
            exit 1
        }
    } else {
        Write-Log "No hay ProfileData por parámetro ni snapshot local. Saliendo."
        exit 1
    }
}

## FUNCIONES ##

function Map-NetworkShares($shares) {
    foreach ($s in $shares) {
        $Drive = $s.Drive
        $Path  = $s.Path

        if (Test-Path "$Drive:\") {
            Write-Log "Unidad $Drive: ya existía. Desmontando para refrescar."
            Remove-PSDrive -Name $Drive -Force -ErrorAction SilentlyContinue
        }

        Write-Log "Mapeando unidad $Drive: -> $Path"
        New-PSDrive -Name $Drive -PSProvider FileSystem -Root $Path -Persist -ErrorAction SilentlyContinue
    }
}

function Install-Printers($printers) {
    Write-Log "Eliminando impresoras existentes del usuario..."
    $installed = Get-Printer | Select-Object -ExpandProperty Name -ErrorAction SilentlyContinue

    foreach ($p in $installed) {
        Remove-Printer -Name $p -ErrorAction SilentlyContinue
        Write-Log "Eliminada: $p"
    }

    foreach ($printer in $printers) {
        Write-Log "Instalando impresora: $printer"
        Start-Process "rundll32.exe" `
            -ArgumentList "printui.dll,PrintUIEntry /in /n `"$printer`"" `
            -Wait
    }
}

function Install-GUIs($guis) {
    foreach ($gui in $guis) {
        Write-Log "Instalando GUI: $gui"
        Start-Process "javaws" -ArgumentList "-uninstall `"$gui`"" -Wait -ErrorAction SilentlyContinue

        $launcher = "C:\Program Files\AmigaLauncher\amglauncher.exe"
        Start-Process $launcher -ArgumentList "-install -silent `"$gui`"" -Wait -ErrorAction SilentlyContinue
    }
}


# APLICAR CONFIGURACIÓN 

Map-NetworkShares $ProfileData.shares
Install-Printers   $ProfileData.printers
Install-GUIs       $ProfileData.guis

# Marcar como completado para este usuario
Set-ItemProperty -Path $KeyPath -Name $FlagName -Value 1

Write-Log "Postmaquetado aplicado y marcado como completado."
Write-Log "===== FIN POSTMAQUETADO ====="
exit 0