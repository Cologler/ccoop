using namespace System.IO;

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
        [FileInfo] $shimFile
    )

    if (!$shimFile.exists) {
        throw "Target of shim file $shimFile does not exist."
    }

    if ($shimFile -match '\.ps1$') {
        # on powershell 5,
        # get-content does not accept a `FileInfo` object
        # by default, it will convert to $shimFile.Name instead of $shimFile.FullName
        $fileContent = Get-Content $shimFile.FullName
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
