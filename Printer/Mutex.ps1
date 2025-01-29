begin {
    $string = @()
    $logFile = ".\Printer\test.txt"

    for ($i =1; $i -lt 500; $i++) {
        $string += "$([datetime]::Now.Microsecond),$($env:USERNAME), This is a test message. It is test number $i"
    }

    # create the mutex
    $mutex = [System.Threading.Mutex]::new($false, "MutexName")
}

process {
    $string | foreach-object -ThrottleLimit 10 -Parallel {

        $logFile = $using:logFile
        $mutex = $using:mutex
       
        $null = $mutex.WaitOne()    

        # simulate random finish time
        start-sleep (Get-Random -Minimum 0 -Maximum 1)

        # write to log
        $PSItem | Out-File $logFile -Append
        
        # release the mutex for the next write
        $mutex.ReleaseMutex()
    }
}