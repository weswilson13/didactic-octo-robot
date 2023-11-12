# ===============================================
# Script to decline superseeded updates in WSUS.
# ===============================================
# It's recommended to run the script with the -SkipDecline switch to see how many superseded updates are in WSUS and to TAKE A BACKUP OF THE SUSDB before declining the updates.
# Parameters:

# $UpdateServer             = Specify WSUS Server Name
# $UseSSL                   = Specify whether WSUS Server is configured to use SSL
# $Port                     = Specify WSUS Server Port
# $SkipDecline              = Specify this to do a test run and get a summary of how many superseded updates we have
# $DeclineLastLevelOnly     = Specify whether to decline all superseded updates or only last level superseded updates
# $ExclusionPeriod          = Specify the number of days between today and the release date for which the superseded updates must not be declined. Eg, if you want to keep superseded updates published within the last 2 months, specify a value of 60 (days)


# Supersedence chain could have multiple updates. 
# For example, Update1 supersedes Update2. Update2 supersedes Update3. In this scenario, the Last Level in the supersedence chain is Update3. 
# To decline only the last level updates in the supersedence chain, specify the DeclineLastLevelOnly switch

# Usage:
# =======

# To do a test run against WSUS Server without SSL
# Decline-SupersededUpdates.ps1 -UpdateServer SERVERNAME -Port 8530 -SkipDecline

# To do a test run against WSUS Server using SSL
# Decline-SupersededUpdates.ps1 -UpdateServer SERVERNAME -UseSSL -Port 8531 -SkipDecline

# To decline all superseded updates on the WSUS Server using SSL
# Decline-SupersededUpdates.ps1 -UpdateServer SERVERNAME -UseSSL -Port 8531

# To decline only Last Level superseded updates on the WSUS Server using SSL
# Decline-SupersededUpdates.ps1 -UpdateServer SERVERNAME -UseSSL -Port 8531 -DeclineLastLevelOnly

# To decline all superseded updates on the WSUS Server using SSL but keep superseded updates published within the last 2 months (60 days)
# Decline-SupersededUpdates.ps1 -UpdateServer SERVERNAME -UseSSL -Port 8531 -ExclusionPeriod 60


[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string] $UpdateServer,
    
    [Parameter(Mandatory=$False)]
    [switch] $UseSSL,
    
    [Parameter(Mandatory=$True, Position=2)]
    $Port,
    
    [switch] $SkipDecline,
    
    [switch] $DeclineLastLevelOnly,
    
    [Parameter(Mandatory=$False)]
    [int] $ExclusionPeriod = 0
)

$file = "c:\temp\WSUS_Decline_Superseded_{0:MMddyyyy_HHmm}.log" -f (Get-Date) 

Start-Transcript -Path $file


if ($SkipDecline -and $DeclineLastLevelOnly) {
    Write-Output "Using SkipDecline and DeclineLastLevelOnly switches together is not allowed."
    Write-Output ""
    return
}

$outPath = Split-Path $script:MyInvocation.MyCommand.Path
$outSupersededList = Join-Path $outPath "SupersededUpdates.csv"
$outSupersededListBackup = Join-Path $outPath "SupersededUpdatesBackup.csv"
"UpdateID, RevisionNumber, Title, KBArticle, SecurityBulletin, LastLevel" | Out-File $outSupersededList

try {
    
    if ($UseSSL) {
        Write-Output "Connecting to WSUS server $UpdateServer on Port $Port using SSL... " -NoNewLine
    } Else {
        Write-Output "Connecting to WSUS server $UpdateServer on Port $Port... " -NoNewLine
    }
    
    [reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | out-null
    $wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer($UpdateServer, $UseSSL, $Port);
}
catch [System.Exception] 
{
    Write-Output "Failed to connect."
    Write-Output "Error:" $_.Exception.Message
    Write-Output "Please make sure that WSUS Admin Console is installed on this machine"
    Write-Output ""
    $wsus = $null
}

if ($wsus -eq $null) { return } 

Write-Output "Connected."

$UpdateScope = New-Object Microsoft.UpdateServices.Administration.UpdateScope

(get-date).AddMonths(-6)
$UpdateScope.FromArrivalDate = (get-date).AddMonths(-6)
$UpdateScope.ToArrivalDate = (get-date)

$countAllUpdates = 0
$countSupersededAll = 0
$countSupersededLastLevel = 0
$countSupersededExclusionPeriod = 0
$countSupersededLastLevelExclusionPeriod = 0
$countDeclined = 0

Write-Output "Getting a list of all updates... " -NoNewLine

try {
    $allUpdates = $wsus.GetUpdates($UpdateScope)
}

catch [System.Exception]
{
    Write-Output "Failed to get updates."
    Write-Output "Error:" $_.Exception.Message
    Write-Output "If this operation timed out, please decline the superseded updates from the WSUS Console manually."
    Write-Output ""
    return
}

Write-Output "Done"

Write-Output "Parsing the list of updates... " -NoNewLine
foreach($update in $allUpdates) {
    
    $countAllUpdates++
    
    if ($update.IsDeclined) {
        $countDeclined++
    }
    
    if (!$update.IsDeclined -and $update.IsSuperseded) {
        $countSupersededAll++
        
        if (!$update.HasSupersededUpdates) {
            $countSupersededLastLevel++
        }

        if ($update.CreationDate -lt (get-date).AddDays(-$ExclusionPeriod))  {
            $countSupersededExclusionPeriod++
            if (!$update.HasSupersededUpdates) {
                $countSupersededLastLevelExclusionPeriod++
            }
        }        
        
        "$($update.Id.UpdateId.Guid), $($update.Id.RevisionNumber), $($update.Title), $($update.KnowledgeBaseArticles), $($update.SecurityBulletins), $($update.HasSupersededUpdates)" | Out-File $outSupersededList -Append       
        
    }
}

Write-Output "Done."
Write-Output "List of superseded updates: $outSupersededList"

Write-Output ""
Write-Output "Summary:"
Write-Output "========"

Write-Output "All Updates = $countAllUpdates"
$AnyExceptDeclined = $countAllUpdates - $countDeclined
Write-Output "Any except Declined = $AnyExceptDeclined"
Write-Output "All Superseded Updates = $countSupersededAll"
$SuperseededAllOutput = $countSupersededAll - $countSupersededLastLevel
Write-Output "    Superseded Updates (Intermediate) = $SuperseededAllOutput"
Write-Output "    Superseded Updates (Last Level) = $countSupersededLastLevel"
Write-Output "    Superseded Updates (Older than $ExclusionPeriod days) = $countSupersededExclusionPeriod"
Write-Output "    Superseded Updates (Last Level Older than $ExclusionPeriod days) = $countSupersededLastLevelExclusionPeriod"

$i = 0
if (!$SkipDecline) {
    
    Write-Output "SkipDecline flag is set to $SkipDecline. Continuing with declining updates"
    $updatesDeclined = 0
    
    if ($DeclineLastLevelOnly) {
        Write-Output "  DeclineLastLevel is set to True. Only declining last level superseded updates." 
        
        foreach ($update in $allUpdates) {
            
            if (!$update.IsDeclined -and $update.IsSuperseded -and !$update.HasSupersededUpdates) {
              if ($update.CreationDate -lt (get-date).AddDays(-$ExclusionPeriod))  {
                $i++
                $percentComplete = "{0:N2}" -f (($updatesDeclined/$countSupersededLastLevelExclusionPeriod) * 100)
                Write-Progress -Activity "Declining Updates" -Status "Declining update #$i/$countSupersededLastLevelExclusionPeriod - $($update.Id.UpdateId.Guid)" -PercentComplete $percentComplete -CurrentOperation "$($percentComplete)% complete"
                
                try 
                {
                    $update.Decline()                    
                    $updatesDeclined++
                }
                catch [System.Exception]
                {
                    Write-Output "Failed to decline update $($update.Id.UpdateId.Guid). Error:" $_.Exception.Message
                } 
              }             
            }
        }        
    }
    else {
        Write-Output "  DeclineLastLevel is set to False. Declining all superseded updates."
        
        foreach ($update in $allUpdates) {
            
            if (!$update.IsDeclined -and $update.IsSuperseded) {
              if ($update.CreationDate -lt (get-date).AddDays(-$ExclusionPeriod))  {   
                  
                $i++
                $percentComplete = "{0:N2}" -f (($updatesDeclined/$countSupersededAll) * 100)
                Write-Progress -Activity "Declining Updates" -Status "Declining update #$i/$countSupersededAll - $($update.Id.UpdateId.Guid)" -PercentComplete $percentComplete -CurrentOperation "$($percentComplete)% complete"
                try 
                {
                    $update.Decline()
                    $updatesDeclined++
                }
                catch [System.Exception]
                {
                    Write-Output "Failed to decline update $($update.Id.UpdateId.Guid). Error:" $_.Exception.Message
                }
              }              
            }
        }   
        
    }
    
    Write-Output "  Declined $updatesDeclined updates."
    if ($updatesDeclined -ne 0) {
        Copy-Item -Path $outSupersededList -Destination $outSupersededListBackup -Force
        Write-Output "  Backed up list of superseded updates to $outSupersededListBackup"
    }
    
}
else {
    Write-Output "SkipDecline flag is set to $SkipDecline. Skipped declining updates"
}

Write-Output ""
Write-Output "Done"
Write-Output ""

Stop-Transcript