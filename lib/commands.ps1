# ensure only run once:
if (Get-Variable -Name "scoop:run:$($MyInvocation.MyCommand.Path)" -ErrorAction SilentlyContinue) {
    exit
} else {
    Set-Variable -Name "scoop:run:$($MyInvocation.MyCommand.Path)" -Value $true
}

# start:
. "$PSScriptRoot\shim"

function Get-ScoopCommandName {
    param (
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo] $file
    )

    return $file.BaseName.Substring('scoop-'.Length);
}

function Get-ScoopCommandsInfoArray {
    param (
        # include
        [Switch] $IncludeBuiltins,
        [Switch] $IncludeExternal,

        # optional peoperties
        [Switch] $ResolveTarget,

        # options
        [switch] $ExternalFirst
    )

    if (!$IncludeBuiltins -and !$IncludeExternal) {
        $IncludeBuiltins = $true
        $IncludeExternal = $true
    }

    $filter = 'scoop-*.ps1'

    if ($IncludeBuiltins) {
        $builtins = Get-ChildItem (relpath '..\libexec') -Filter $filter | ForEach-Object {
            return @{
                File = $_
                IsBuiltin = $true
            }
        }
    } else {
        $builtins = @()
    }

    if ($IncludeExternal) {
        $external = Get-ChildItem "$scoopdir\shims" -Filter $filter | ForEach-Object {
            return @{
                File = $_
                IsExternal = $true
            }
        }
    } else {
        $external = @()
    }

    if ($ExternalFirst) {
        $all = $external + $builtins
    } else {
        $all = $builtins + $external
    }

    return $all | foreach-object {
        # parse name before resolve
        $_.Name = Get-ScoopCommandName $_.File

        if ($ResolveTarget) {
            if ($_.IsBuiltin) {
                $_.TargetFile = $_.file
            }
            elseif ($_.IsExternal) {
                $_.TargetFile = Get-ScoopShimTarget $_.File
            }
        }

        return $_
    }
}

function Convert-ScoopCommandsInfoArrayToHashtable {
    param (
        [ValidateNotNullOrEmpty()]
        [hashtable[]]
        $array
    )

    $rv = @{}
    $array | ForEach-Object {
        $name = $_.name
        if (!$rv.ContainsKey($name)) {
            $rv.Add($name, $_)
        }
    }
    return $rv
}

function Invoke-ScoopCommand {
    param (
        [Parameter(Mandatory=$true)]
        [Hashtable] $CommandInfo,
        [string[]] $Arguments
    )

    & $CommandInfo.File.FullName @arguments
}

function command_files {
    (Get-ChildItem (relpath '..\libexec')) `
        + (Get-ChildItem "$scoopdir\shims") `
        | Where-Object { $_.name -match 'scoop-.*?\.ps1$' }
}

function commands {
    command_files | ForEach-Object { command_name $_ }
}

function command_name($filename) {
    $filename.name | Select-String 'scoop-(.*?)\.ps1$' | ForEach-Object { $_.matches[0].groups[1].value }
}

function command_path($cmd) {
    $cmd_path = relpath "..\libexec\scoop-$cmd.ps1"

    # built in commands
    if (!(Test-Path $cmd_path)) {
        # get path from shim
        $shim_path = "$scoopdir\shims\scoop-$cmd.ps1"
        $line = ((Get-Content $shim_path) | Where-Object { $_.startswith('$path') })
        if($line) {
            Invoke-Expression -command "$line"
            $cmd_path = $path
        }
        else { $cmd_path = $shim_path }
    }

    $cmd_path
}
