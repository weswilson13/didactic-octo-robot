Clear-host

$webRequest = Invoke-WebRequest -uri http://ftp.ext.hp.com//pub/networking/software/pfirmware/pfirmware.glf -UseBasicParsing
$content = $webRequest.RawContent

$printerTypes = "8500_fn1,609_fs5,M551_fs3,M577_fs5,M578_fs5,M652_653_fs5,M506,612_fs5,6800,M776,5700"

$firmware = "$env:USERPROFILE\OneDrive\OneDrive - PrimeNet\SoftwareVersions\firmware.txt"
$currentFirmware = Get-Content $firmware

$printerTypes = $printerTypes.Split(",")
$content = $content.Split("`n")
$path = @()
$filepaths = @()

foreach ($line in $content) {
    if ($line.Contains("Path")) {
        $path += $line
    }
}

foreach ($line in $path) {
    foreach ($printer in $printerTypes) {
        if ($line.Contains($printer)) {
            $out = ($line.Replace("Path", "")).replace("=", "")
            $out = $out.Trim()
            #$out
            $file = ($out.Split("/"))[7]
            if (-not ($currentFirmware.Contains($file))) {
                Write-Host "The following Firmware is new, please download $out"
                $filepaths += $out                                
            }
        
        }
    }
}

if ($filepaths) {
    if ((Read-Host "Do you want to download these files now? (y/n)")[0].ToString().ToLower() -eq 'y') {
        foreach ($filepath in $filepaths) {
            try {
                $filename = $filepath.split("/")[-1]
                $filename
                Invoke-WebRequest -Uri $filepath -OutFile "$env:UserProfile\Downloads\$filename" #"C:\Users\$env:USERNAME\OneDrive\OneDrive - Naval Nuclear Laboratory\ToNNPP\$filename"
            }
            catch {
                $error[0]
            }
        }
        Write-Host "Files saved at $env:UserProfile\Downloads\"
    } 
}

Write-Host "Done Processing"
