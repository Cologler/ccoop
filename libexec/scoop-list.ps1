# Usage: scoop list [query] [--name] [--json]
# Summary: List installed apps
# Help:
#    Lists all installed apps, or the apps matching the supplied query.
#
# Options:
#   --name                Output only app names
#   --json                Output with json format

. "$psscriptroot\..\lib\core.ps1"
. "$psscriptroot\..\lib\versions.ps1"
. "$psscriptroot\..\lib\manifest.ps1"
. "$psscriptroot\..\lib\buckets.ps1"
. "$psscriptroot\..\lib\getopt.ps1"

$opt, $query, $err = getopt $args '' @('name', 'json')
if ($err) {
    "scoop virustotal: $err";
    exit 1
}
if ($query.Length -gt 1) {
    "only accept one query."
    exit 1
} else {
    $query = $query[0]
}

reset_aliases
$def_arch = default_architecture

$local = installed_apps $false | ForEach-Object { @{ name = $_ } }
$global = installed_apps $true | ForEach-Object { @{ name = $_; global = $true } }

$apps = $local + $global |
    Where-Object { !$query -or ($_.name -match $query) } |
    ForEach-Object {
        $app = @{}
        $app.name = $_.name
        if ($_.global) {
            $app.global = $true
        }
        $app.version = current_version $_.name $app.global
        $install_info = install_info $app.name $app.version $app.global
        if (!$install_info) {
            $app.installFailed = $true
        }
        else {
            if ($install_info.hold) {
                $app.hold = $install_info.hold
            }
            if ($install_info.bucket) {
                $app.bucket = $install_info.bucket;
            } elseif ($install_info.url) {
                $app.url = $install_info.url;
            }
            if ($install_info.architecture) {
                $app.architecture = $install_info.architecture;
            }
        }

        return $app
    }

if ($opt.json) {
    $apps | ConvertTo-Json
}
elseif ($opt.name) {
    $apps | ForEach-Object { $_.name }
}
else {
    # default mode of scoop
    if ($apps) {
        Write-Host "Installed apps$(if($query) { `" matching '$query'`"}): `n"
        $apps | Sort-Object { $_.name } | ForEach-Object {
            $app = $_.name
            $global = $_.global
            $ver = $_.version

            Write-Host "  $app " -NoNewline
            Write-Host -f DarkCyan $_.version -NoNewline

            if ($_.global) {
                Write-Host -f DarkGreen ' *global*' -NoNewline
            }

            if ($_.installFailed) {
                Write-Host ' *failed*' -ForegroundColor DarkRed -NoNewline
            }

            if ($_.hold) {
                Write-Host ' *hold*' -ForegroundColor DarkRed -NoNewline
            }

            if ($_.bucket) {
                Write-Host -f Yellow " [$($_.bucket)]" -NoNewline
            }
            elseif ($_.url) {
                Write-Host -f Yellow " [$($_.url)]" -NoNewline
            }

            if ($_.architecture -and $def_arch -ne $_.architecture) {
                Write-Host -f DarkRed " {$($_.architecture)}" -NoNewline
            }

            Write-Host ''
        }
        Write-Host ''
        exit 0

    } else {
        Write-Host "There aren't any apps installed."
        exit 1
    }
}
