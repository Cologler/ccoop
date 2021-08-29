# ensure only run once:
if (Get-Variable -Name "scoop:run:$($MyInvocation.MyCommand.Path)" -ErrorAction SilentlyContinue) {
    exit
} else {
    Set-Variable -Name "scoop:run:$($MyInvocation.MyCommand.Path)" -Value $true
}

# start:

function Get-ScoopCommandName {
    param (
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo] $file
    )

    return $file.BaseName.Substring('scoop-'.Length);
}

function Get-ScoopCommandFiles {
    param (
        [Switch] $Resolve
    )

    $filter = 'scoop-*.ps1'
    $rv = @{}
    $builtins = Get-ChildItem (relpath '..\libexec') -Filter $filter
    $external = Get-ChildItem "$scoopdir\shims" -Filter $filter | ForEach-Object {
        if ($Resolve) {
            $fileContent = Get-Content $_.FullName
            $line = $fileContent | Where-Object { $_.StartsWith('$path = join-path "$psscriptroot"') }
            if ($line) {
                $relpath = Invoke-Expression $line.Substring('$path = join-path "$psscriptroot"'.Length)
                $abspath = Join-Path $(shimdir $false) $relpath -Resolve
                return Get-Item $abspath
            }
        }
        return $_
    }
    $builtins + $external | ForEach-Object {
        $name = Get-ScoopCommandName $_
        if (!$rv.ContainsKey($name)) {
            $rv.Add($name, $_)
        }
    }
    return $rv
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

function exec($cmd, $arguments) {
    $cmd_path = command_path $cmd

    & $cmd_path @arguments
}
