# ensure only run once:
if (Get-Variable -Name "scoop:run:$($MyInvocation.MyCommand.Path)" -ErrorAction SilentlyContinue) {
    exit
} else {
    Set-Variable -Name "scoop:run:$($MyInvocation.MyCommand.Path)" -Value $true
}

# start:
. "$PSScriptRoot\core"

function Get-ScoopShimTarget {
    param (
        [parameter(Mandatory=$true)]
        [string] $shimFile
    )

    if (!(Test-Path -Path $shimFile -PathType Leaf)) {
        throw "Shim file $shimFile does not exist."
    }

    if ($shimFile -match '\.ps1$') {
        $fileContent = Get-Content $shimFile
        $line = $fileContent | Where-Object { $_.StartsWith('$path = join-path "$psscriptroot"') }
        if ($line) {
            $relpath = Invoke-Expression $line.Substring('$path = join-path "$psscriptroot"'.Length)
            $abspath = Join-Path $(shimdir $false) $relpath -Resolve
            return Get-Item $abspath
        }
        throw "Shim file $shimFile does not contain a valid target."

    } else {
        throw
    }
}
