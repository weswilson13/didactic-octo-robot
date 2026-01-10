$data = @"
2.4.1 - Batteries

Objective: Verify that all batteries are functioning within acceptable parameters.
Batteries should be tested under load conditions to ensure reliability.

a. This is the first line of the battery section.
It continues here on the next line.
b. This is the second line of the battery section (Page
1, Line 2).
c. This is the third line of the battery section.
"@

$newLine = $csv = @()

$data = $data -split("`n")

$firstLine = $data | Select-Object -First 1

$tgo = [regex]::Match($firstLine, '^(\d+\.?)+').Value.Trim()

$tgoTitle = $firstLine.Replace($tgo,'').Trim()

$linesToSkip = 0
foreach ($line in $data) {
    if ($line -notmatch '^\D\.') {
        $linesToSkip = $linesToSkip + 1
    } else {
        break
    }
}

$list = $data | Select-Object -Skip ($linesToSkip - 1) | Where-Object {$_ -ne ''}

$i = 0
do {
    $line = $list[$i]
    if ($line -match '^[a-z]\.' -or $i -eq $list.Length) {
        if ($newline) {
            $letter, $description = ($newLine -join ' ').Split('. ',2).Trim()
            $csv += [PSCustomObject]@{
                TGO_Title   = $tgoTitle
                TGO         = $tgo + $tgoLetter
                Description = $description
            }
            if ($i -eq $list.Length) {
                break
            }
        }
        $newLine = @()
    } 
    
    $newLine += $line.Trim()
} until ($i++ -eq $list.Length) 

$csv