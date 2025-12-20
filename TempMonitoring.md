Absolutely — let’s extend your monitoring script so it logs every temperature sample into a SQL database. I’ll give you a clean, production‑ready pattern that works with **SQL Server**, using `Invoke-Sqlcmd` or `.NET SqlConnection` depending on what you prefer.

Below is the version using **Invoke‑Sqlcmd**, which is the simplest if the SQL Server PowerShell module is installed.

---

# ✅ **Updated Script with SQL Logging**

This version logs **every sample** into a table called `WatchdogTemperatureLog`.

### ✅ **SQL Table Schema (run once)**

```sql
CREATE TABLE WatchdogTemperatureLog (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Timestamp DATETIME NOT NULL,
    TemperatureF FLOAT NOT NULL,
    SourceIP VARCHAR(50) NOT NULL
);
```

---

# ✅ **PowerShell Script with SQL Logging**

```powershell
# ================================
# Configuration
# ================================
$HostIP        = "192.168.1.50"
$Community     = "public"
$TempOID       = "1.3.6.1.4.1.21239.5.1.2.1.9.1"
$SampleSeconds = 30
$DurationMin   = 10
$ThresholdF    = 95

# SQL settings
$SqlServer     = "SQLSERVER01"
$SqlDatabase   = "EnvironmentMonitoring"

# ================================
# Storage
# ================================
$Samples = @()
$TotalSamples = ($DurationMin * 60) / $SampleSeconds

Write-Host "Collecting $DurationMin minutes of temperature data from $HostIP..."

# ================================
# Sampling Loop
# ================================
for ($i = 1; $i -le $TotalSamples; $i++) {

    $snmp = snmpget -r:$HostIP -c:$Community -v:2c $TempOID 2>$null

    if ($snmp) {
        $temp = ($snmp -split " " | Select-Object -Last 1) -as [double]
        $timestamp = Get-Date

        # Store in memory
        $Samples += [PSCustomObject]@{
            Time  = $timestamp
            TempF = $temp
        }

        Write-Host "$timestamp  Temp: $temp F"

        # ================================
        # SQL Logging
        # ================================
        $query = @"
INSERT INTO WatchdogTemperatureLog (Timestamp, TemperatureF, SourceIP)
VALUES ('$timestamp', $temp, '$HostIP');
"@

        try {
            Invoke-Sqlcmd -ServerInstance $SqlServer -Database $SqlDatabase -Query $query
        }
        catch {
            Write-Warning "Failed to log to SQL: $_"
        }
    }
    else {
        Write-Warning "SNMP query failed at $(Get-Date)"
    }

    Start-Sleep -Seconds $SampleSeconds
}

# ================================
# Analysis
# ================================
$First = $Samples[0].TempF
$Last  = $Samples[-1].TempF

$IsRising = $Last -gt $First
$IsAboveThreshold = $Last -gt $ThresholdF

Write-Host "`n--- Temperature Summary ---"
Write-Host "Start Temp: $First F"
Write-Host "End Temp:   $Last F"
Write-Host "Rising:     $IsRising"
Write-Host "Above 95F:  $IsAboveThreshold"
Write-Host "-----------------------------`n"

# ================================
# Action Logic
# ================================
if ($IsAboveThreshold -and $IsRising) {

    Write-Warning "Temperature is above $ThresholdF F AND rising. Taking action..."

    # Add your actions here
}
else {
    Write-Host "Temperature is safe or stable. No action taken."
}

```

---

# ✅ **Alternative: Using .NET SqlConnection (no modules required)**

If you want a version that works even on minimal PowerShell installs, I can generate that too — it uses raw ADO.NET and is extremely reliable.

---

# ✅ Want enhancements?

I can add:

- Logging trend summaries to SQL  
- A separate table for alerts  
- A SQL stored procedure instead of inline SQL  
- A continuous service‑style loop instead of a 10‑minute batch  
- Email/SMS alerting tied to SQL data  

Just tell me how far you want to take this.