#Requires -Version 5

# remote install:
#   Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')

if (($PSVersionTable.PSVersion.Major) -lt 5) {
    Write-Output "PowerShell 5 or later is required to run Scoop."
    Write-Output "Upgrade PowerShell: https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell"
    break
}

# show notification to change execution policy:
$allowedExecutionPolicy = @('Unrestricted', 'RemoteSigned', 'ByPass')
if ((Get-ExecutionPolicy).ToString() -notin $allowedExecutionPolicy) {
    Write-Output "PowerShell requires an execution policy in [$($allowedExecutionPolicy -join ", ")] to run Scoop."
    Write-Output "For example, to set the execution policy to 'RemoteSigned' please run :"
    Write-Output "'Set-ExecutionPolicy RemoteSigned -scope CurrentUser'"
    break
}

if ([System.Enum]::GetNames([System.Net.SecurityProtocolType]) -notcontains 'Tls12') {
    Write-Output "Scoop requires at least .NET Framework 4.5"
    Write-Output "Please download and install it first:"
    Write-Output "https://www.microsoft.com/net/download"
    break
}

$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'stop' # quit if anything goes wrong

$ScoopName = 'Ccoop'
$ScoopRemoteCoreLibUrl = 'https://raw.githubusercontent.com/Cologler/ccoop/master/lib/core.ps1'
$ScoopRemoteRepoZipUrl = 'https://github.com/Cologler/ccoop/archive/master.zip'
$ScoopMainBucketName   = 'main'
$ScoopMainBucketUrl    = 'https://github.com/ScoopInstaller/Main/archive/master.zip'

function Add-MainBucketAtomic {
    $bucketsDir             = Join-Path $scoopdir 'buckets'
    $mainBucketDir          = Join-Path $bucketsDir $ScoopMainBucketName
    $mainBucketTempZipFile  = Join-Path $bucketsDir ($ScoopMainBucketName + '$temp.zip')
    $mainBucketTempDir      = Join-Path $bucketsDir ($ScoopMainBucketName + '$temp')

    if (Test-Path $mainBucketDir) {
        if (!(Test-Path $mainBucketTempZipFile)) {
            # installed
            return;
        } else {
            Remove-Item $mainBucketTempZipFile
        }
    }

    # download main bucket
    Write-Output 'Downloading main bucket...'
    if (Test-Path $mainBucketTempZipFile) {
        Remove-Item $mainBucketTempZipFile
    }
    dl $ScoopMainBucketUrl $mainBucketTempZipFile

    Write-Output 'Extracting...'
    if (Test-Path $mainBucketTempDir) {
        Remove-Item $mainBucketTempDir -Recurse -Force
    }
    [IO.Compression.ZipFile]::ExtractToDirectory($mainBucketTempZipFile, $mainBucketTempDir)

    New-Item $mainBucketDir -Type Directory -Force | Out-Null
    Copy-Item "$mainBucketTempDir\*-master\*" $mainBucketDir -Recurse -Force

    Remove-Item $mainBucketTempDir, $mainBucketTempZipFile -Recurse -Force
}

try {

    # get core functions
    Write-Output 'Initializing...'
    Invoke-Expression (new-object net.webclient).downloadstring($ScoopRemoteCoreLibUrl)

    # prep
    if (installed $ScoopName) {
        write-host "$ScoopName is already installed. Run '$($ScoopName.ToLower()) update' to get the latest version." -f red
        # don't abort if invoked with iex that would close the PS session
        if ($myinvocation.mycommand.commandtype -eq 'Script') { return } else { exit 1 }
    }
    $scoopCurrentDir = ensure (versiondir $ScoopName 'current')

    # download scoop zip
    $zipfile = "$scoopCurrentDir\$ScoopName.zip"
    Write-Output "Downloading $ScoopName..."
    dl $ScoopRemoteRepoZipUrl $zipfile

    Write-Output 'Extracting...'
    Add-Type -Assembly "System.IO.Compression.FileSystem"
    [IO.Compression.ZipFile]::ExtractToDirectory($zipfile, "$scoopCurrentDir\_tmp")
    Copy-Item "$scoopCurrentDir\_tmp\*master\*" $scoopCurrentDir -Recurse -Force
    Remove-Item "$scoopCurrentDir\_tmp", $zipfile -Recurse -Force

    Write-Output 'Creating shim...'
    New-ScoopShimToScoop

    # download main bucket
    Add-MainBucketAtomic

    ensure_robocopy_in_path
    ensure_scoop_in_path

    scoop config lastupdate ([System.DateTime]::Now.ToString('o'))
    success 'Scoop was installed successfully!'

    Write-Output "Type 'scoop help' for instructions."
}
finally {
    $ErrorActionPreference = $oldErrorActionPreference # Reset $ErrorActionPreference to original value
}
