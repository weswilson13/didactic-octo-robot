$adobeObject = @{
    InstalledSoftware=@{
        DisplayName = 'Adobe InDesign 2023 64 bit'
    }
}

$adobeRepository = "\\path\software\Adobe"

$update=$true
$UninstallExisting = $true

$product,$year,$architecture=$null

if ($update) {
    # do stuff

    if ($UninstallExisting) { # an older major version needs uninstalled
        $product,$year,$architecture = [regex]::Match($adobeObject.InstalledSoftware.DisplayName, 'Adobe (?<product>\w+) (?<year>\d+)(?<arch>(?<= *)(\(?(32|64) bit)\)?)?').Groups['product','year','arch'].Value
        
        # use the Get-InstallerPaths function to retrieve MSI Path
        $currentInstallerPaths = Get-InstallerPaths -Product $product -Year $year -Architecture $architecture

        Copy-Item $currentInstallerPaths.InstallerPaths.MsiPath "$destinationPathUNC\installer.msi"

        Add-Member -InputObject $adobeObject -NotePropertyMembers @{UninstallerMSI="$destinationPathLocal\installer.msi"}
    }
}