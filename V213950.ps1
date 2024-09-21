try{
    Import-Module \\Optimusprime\Z\STIG\Evaluate-STIG\Evaluate-STIG\Modules\Master_Functions
    Import-Module \\Optimusprime\Z\STIG\Evaluate-STIG\Evaluate-STIG\Modules\Scan-SqlServer2016Instance_Checks
    Import-Module SqlServer

    $attr = @{
        ScanType  = 'Classified'
        Instance  = 'SQ02,9999'
        Database  = 'master'
        AnswerKey = 'DEFAULT'
    }

    $findingDetails = Get-V213950 @attr | Select-Object -ExpandProperty FindingDetails
    # $findingDetails = $findingDetails -split '\r?\n'

    $owners = @()
    (Select-String -InputObject $findingDetails -Pattern 'owner: (?<owner>.+)' -AllMatches).Matches | ForEach-Object {
       $owners += [PSCustomObject]@{Owner=$_.Groups['owner'].Value}
    }
    $owners = $owners | Select-Object * -Unique
    $owners | Out-String | Write-Host

    $modifiers = @()
    (Select-String -InputObject $findingDetails -Pattern 'modifier: (?<modifier>.+)' -AllMatches).Matches | ForEach-Object {
        #$_
        $user, $permission = $_.Groups['modifier'].Value.Split(' (')
        $modifiers +=[PSCustomObject]@{Modifier=$user;Permission=$permission.Trim(')')}
    }
    $modifiers = $modifiers | Select-Object * -Unique
    $modifiers | Out-String | Write-Host
}
Catch {
    $_.Exception
}
