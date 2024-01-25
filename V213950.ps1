try{
    Import-Module \\raspberrypi4-1\nas01\STIG\Evaluate-STIG\Evaluate-STIG\Modules\Master_Functions
    Import-Module \\raspberrypi4-1\nas01\STIG\Evaluate-STIG\Evaluate-STIG\Modules\Scan-SqlServer2016Instance_Checks
    Import-Module SqlServer

    $attr = @{
        ScanType  = 'Classified'
        Instance  = 'SQ02,9999'
        Database  = 'master'
        AnswerKey = 'DEFAULT'
    }

    $findingDetails = Get-V213950 @attr | Select-Object -ExpandProperty FindingDetails
    # $findingDetails = $findingDetails -split '\r?\n'

    $owners = New-Object -TypeName psobject
    (Select-String -InputObject $findingDetails -Pattern 'owner: (?<owner>.+)' -AllMatches).Matches | ForEach-Object {
        Add-Member -InputObject $owners -NotePropertyMembers @{User=$_.Groups['owner'].Value;Role='Owner'}
    }
    $owners = $owners | Select-Object -Unique
    $owners

    $modifiers = New-Object -TypeName psobject
    (Select-String -InputObject $findingDetails -Pattern 'modifier: (?<modifier>.+)' -AllMatches).Matches | ForEach-Object {
        $user, $permission = $_.Groups['modifier'].Value.Split(' (')
        Add-Member -InputObject $modifiers -NotePropertyMembers @{User=$user; Role='Modifier';Permission=$permission.Trim(')')} -Force
    }
    $modifiers = $modifiers | Select-Object -Unique
    $modifiers
}
Catch {
    $_.Exception
}
