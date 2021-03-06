<#
        .SYNOPSIS
        Install a Nuget Package to the RedGate.Build\packages\ folder.
        .DESCRIPTION
        Install a Nuget Package to the RedGate.Build\packages folder
        and return a DirectoryInfo object for the full path of the folder
        where the package was extracted to.
        .PARAMETER Name
        The name/id of the nuget package to install.
        .PARAMETER Version
        The version of the nuget package to install.
        .PARAMETER Silent
        Suppresses stdout and stderr output when invoking NuGet.
        .OUTPUTS
        A string that is the full path of the folder that the package
        was installed to.
#>
#requires -Version 2
function Install-Package
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $true)]
        [string] $Version,

        [switch] $Silent
    )

    # Looks for an existing package that matches the requested id and version.
    if (Test-Path $PackagesDir) {
        $ExistingPackageDirs = Get-ChildItem -Path $PackagesDir -Directory `
        | Where-Object { $_.Name.StartsWith("$Name.$Version", 'InvariantCultureIgnoreCase') } `
        | Sort-Object -Descending { $_.Name }
        if ($ExistingPackageDirs.Length -gt 0) {
            return $ExistingPackageDirs[0].FullName
        }
    }

    # Install the package (only if not already there). Print any nuget.exe output to the verbose stream
    $Parameters = @(
        'install', $Name,
        '-Version', $Version,
        '-OutputDirectory', $PackagesDir,
        '-PackageSaveMode', 'nuspec'
    )
    if ($Silent.IsPresent) {
        Execute-Command -ScriptBlock {
            $AllOutput = & $NugetExe $Parameters 2>&1
            $StdErrorOutput = $AllOutput | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }
            if ($StdErrorOutput) {
                throw $StdErrorOutput
            }
        }
    } else {
        Write-Verbose "Installing $Name.$Version to $PackagesDir" -Verbose
        Execute-Command -ScriptBlock {
            & $NugetExe $Parameters | Write-Verbose
        }
    }

    # Now search once again for the newly installed package.
    $ExistingPackageDirs = Get-ChildItem -Path $PackagesDir -Directory `
    | Where-Object { $_.Name.StartsWith("$Name.$Version", 'InvariantCultureIgnoreCase') } `
    | Sort-Object -Descending { $_.Name }
    if ($ExistingPackageDirs.Length -eq 0) {
        throw 'Failed to locate the folder of the newly installed package'
    }
    return $ExistingPackageDirs[0].FullName
}
