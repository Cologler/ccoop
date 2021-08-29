# Usage: scoop help <command>
# Summary: Show help for a command
param($cmd)

. "$psscriptroot\..\lib\core.ps1"
. "$psscriptroot\..\lib\commands.ps1"
. "$psscriptroot\..\lib\help.ps1"

reset_aliases

$commandsInfoMap = Convert-ScoopCommandsInfoArrayToHashtable (
    Get-ScoopCommandsInfoArray -ResolveTarget -ExternalFirst
)

function Get-ScoopSummaries {
    $commands = @{}

    $commandsInfoMap.Values | ForEach-Object {
        $summary = summary (Get-Content $_.TargetFile.FullName -Raw)
        if (!$summary) {
            $summary = ''
        }

        if ($_.IsExternal) {
            $summary = "(E) $summary"
        }

        $key = "$($_.Name) "
        if (!$commands.ContainsKey($key)) {
            $commands.Add($key, $summary)
        }
    }

    $commands.GetEnumerator() | Sort-Object name | Format-Table -hidetablehead -autosize -wrap
}

function Get-ScoopHelp($CommandInfo) {
    $file = Get-Content $CommandInfo.TargetFile.FullName -Raw

    $usage = usage $file
    $summary = summary $file
    $help = scoop_help $file

    if ($usage) {
        "$usage`n"
    }
    if ($help) {
        $help
    }
}

$commands = commands

if (-not $cmd) {
    Write-Output 'Usage: scoop <command> [<args>]'
    Write-Output ''
    Write-Output 'Some useful commands are:'

    Get-ScoopSummaries | Out-Default

    Write-Output "Type 'scoop help <command>' to get help for a specific command."

}
elseif ($commandsInfoMap.ContainsKey($cmd)) {
    Get-ScoopHelp $commandsInfoMap[$cmd] | Out-Default
}
else {
    "scoop help: no such command '$cmd'"; exit 1
}

exit 0

