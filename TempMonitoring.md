Here’s a clean, practical PowerShell script you can drop into production and adapt as needed. It polls a Vertiv Geist Watchdog via SNMP, collects 10 minutes of temperature samples, determines whether the temperature is above 95°F **and rising**, and then triggers whatever action you define.

I’ll also explain the logic so you can tune it to your environment.

---

# ✅ **PowerShell Script: Monitor Vertiv Geist Watchdog Temperature via SNMP**

```powershell
# ================================
# Configuration
# ================================
$HostIP        = "192.168.1.50"          # IP of Geist Watchdog
$Community     = "public"                # SNMP community string
$TempOID       = "1.3.6.1.4.1.21239.5.1.2.1.9.1"   # Example OID for Temperature (F)
$SampleSeconds = 30                      # Poll every 30 seconds
$DurationMin   = 10                      # Collect 10 minutes of data
$ThresholdF    = 95                      # Temperature threshold

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

    # Query SNMP temperature
    $snmp = snmpget -r:$HostIP -c:$Community -v:2c $TempOID 2>$null

    if ($snmp) {
        # Extract numeric value
        $temp = ($snmp -split " " | Select-Object -Last 1) -as [double]

        $timestamp = Get-Date
        $Samples += [PSCustomObject]@{
            Time = $timestamp
            TempF = $temp
        }

        Write-Host "$timestamp  Temp: $temp F"
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

    # ----------------------------
    # PLACE YOUR ACTIONS HERE
    # ----------------------------

    # Example: Send email alert
    # Send-MailMessage -To "alerts@company.com" -From "watchdog@company.com" `
    #     -Subject "CRITICAL: Watchdog Temperature Rising" `
    #     -Body "Temperature reached $Last F and is rising." `
    #     -SmtpServer "smtp.company.com"

    # Example: Trigger shutdown script
    # & "C:\Scripts\ShutdownServers.ps1"

    # Example: Log to event log
    # Write-EventLog -LogName Application -Source "WatchdogMonitor" `
    #     -EntryType Error -EventId 9001 `
    #     -Message "Temperature reached $Last F and rising."

} else {
    Write-Host "Temperature is safe or stable. No action taken."
}
```

---

# ✅ **How This Works**

### **1. SNMP Polling**
The script uses `snmpget` (from Net-SNMP tools) to query the Watchdog’s temperature OID.

You may need to install Net-SNMP on Windows:
```
choco install net-snmp
```

### **2. Collects 10 minutes of samples**
- Polls every 30 seconds (configurable)
- Stores timestamp + temperature

### **3. Determines if temperature is rising**
Compares the first and last sample:
- Rising if:  
  \(\text{LastTemp} > \text{FirstTemp}\)

### **4. Takes action only if BOTH are true**
✅ Temperature > 95°F  
✅ Temperature is rising

This prevents false alarms from short spikes.

---

# ✅ Want enhancements?

I can add:
- Graphing the temperature trend  
- Logging to a CSV or SQL database  
- Multiple sensor support (Watchdog 15/100/1200)  
- SNMP walk to auto-detect OIDs  
- A Windows service version that runs continuously  

Just tell me what direction you want to take it.

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

Here you go — a clean, reliable PowerShell version that uses **pure .NET `SqlConnection`** instead of `Invoke‑Sqlcmd`. This is the preferred approach when you want zero dependencies and maximum control.

I’ll give you:

✅ A ready‑to‑run script  
✅ A safe, parameterized SQL insert (prevents injection)  
✅ A reusable SQL logging function  

---

# ✅ **PowerShell Script Using .NET SqlConnection**

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
$SqlServer   = "SQLSERVER01"
$SqlDatabase = "EnvironmentMonitoring"
$SqlUser     = "monitoruser"      # or use integrated security
$SqlPass     = "StrongPassword123"

# Build connection string
$ConnString = "Server=$SqlServer;Database=$SqlDatabase;User ID=$SqlUser;Password=$SqlPass;TrustServerCertificate=True;"

# ================================
# SQL Logging Function
# ================================
function Write-TemperatureToSql {
    param(
        [datetime]$Timestamp,
        [double]$TempF,
        [string]$SourceIP
    )

    $query = @"
INSERT INTO WatchdogTemperatureLog (Timestamp, TemperatureF, SourceIP)
VALUES (@ts, @temp, @ip);
"@

    $connection = New-Object System.Data.SqlClient.SqlConnection $ConnString
    $command = $connection.CreateCommand()
    $command.CommandText = $query

    # Parameters
    $command.Parameters.Add("@ts",   [System.Data.SqlDbType]::DateTime)  | out-null
    $command.Parameters.Add("@temp", [System.Data.SqlDbType]::Float)     | out-null
    $command.Parameters.Add("@ip",   [System.Data.SqlDbType]::VarChar,50)| out-null

    $command.Parameters["@ts"].Value   = $Timestamp
    $command.Parameters["@temp"].Value = $TempF
    $command.Parameters["@ip"].Value   = $SourceIP

    try {
        $connection.Open()
        $command.ExecuteNonQuery() | Out-Null
    }
    catch {
        Write-Warning "SQL logging failed: $_"
    }
    finally {
        $connection.Close()
    }
}

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

        # Log to SQL
        Write-TemperatureToSql -Timestamp $timestamp -TempF $temp -SourceIP $HostIP
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

# ✅ **Why this version is production‑ready**

- Uses **parameterized SQL** (prevents injection, handles special characters)
- Uses **ADO.NET**, which is built into Windows and PowerShell
- Clean separation of concerns (SNMP polling vs. SQL logging)
- Easy to expand with more sensors or additional SQL fields

---

# ✅ Want me to add anything?

I can extend this with:

- A separate SQL table for alerts  
- A rolling average or rate‑of‑change calculation  
- Logging humidity or additional sensors  
- A continuous daemon/service version  
- A dashboard query to visualize the data  

Just tell me what direction you want to take it.

Here’s the cleanest version of your script using **.NET `SqlConnection` with Integrated Security**, meaning it uses the Windows credentials of the account running the script — no username or password stored anywhere.

I’ll show you the updated connection string and the full SQL logging function so you can drop it straight into your existing script.

---

# ✅ **Updated Connection String (Integrated Security)**

```powershell
$ConnString = "Server=$SqlServer;Database=$SqlDatabase;Integrated Security=True;TrustServerCertificate=True;"
```

That’s all you need — SQL Server will authenticate the Windows account running the script.

---

# ✅ **Full .NET SQL Logging Function (Integrated Security)**

```powershell
function Write-TemperatureToSql {
    param(
        [datetime]$Timestamp,
        [double]$TempF,
        [string]$SourceIP
    )

    $query = @"
INSERT INTO WatchdogTemperatureLog (Timestamp, TemperatureF, SourceIP)
VALUES (@ts, @temp, @ip);
"@

    $connection = New-Object System.Data.SqlClient.SqlConnection $ConnString
    $command = $connection.CreateCommand()
    $command.CommandText = $query

    # Parameters
    $command.Parameters.Add("@ts",   [System.Data.SqlDbType]::DateTime)  | Out-Null
    $command.Parameters.Add("@temp", [System.Data.SqlDbType]::Float)     | Out-Null
    $command.Parameters.Add("@ip",   [System.Data.SqlDbType]::VarChar,50)| Out-Null

    $command.Parameters["@ts"].Value   = $Timestamp
    $command.Parameters["@temp"].Value = $TempF
    $command.Parameters["@ip"].Value   = $SourceIP

    try {
        $connection.Open()
        $command.ExecuteNonQuery() | Out-Null
    }
    catch {
        Write-Warning "SQL logging failed: $_"
    }
    finally {
        $connection.Close()
    }
}
```

---

# ✅ **Where This Fits in Your Script**

Replace your previous SQL settings with:

```powershell
$SqlServer   = "SQLSERVER01"
$SqlDatabase = "EnvironmentMonitoring"

$ConnString = "Server=$SqlServer;Database=$SqlDatabase;Integrated Security=True;TrustServerCertificate=True;"
```

Everything else in your script stays the same.

---

# ✅ **Requirements for Integrated Security to Work**

Make sure the Windows account running the script:

- Has **network access** to the SQL Server  
- Has **INSERT permissions** on the `WatchdogTemperatureLog` table  
- SQL Server is configured to allow **Windows Authentication**  

If you want, I can generate a SQL script to create the login and permissions.

---

If you'd like, I can also help you turn this into a **Windows service**, add **retry logic**, or log **humidity and additional sensors** from the Watchdog.

Here’s a polished, production‑ready upgrade to your monitoring script. I’m adding:

✅ **Rolling average** (configurable window)  
✅ **Rate‑of‑change** (°F per minute)  
✅ **Separate SQL table for alerts**  
✅ **Alert insertion using the same .NET SqlConnection pattern**  

Everything stays clean, dependency‑free, and easy to extend.

---

# ✅ SQL: Required Tables

### **1. Temperature Log Table (already created earlier)**

```sql
CREATE TABLE WatchdogTemperatureLog (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Timestamp DATETIME NOT NULL,
    TemperatureF FLOAT NOT NULL,
    SourceIP VARCHAR(50) NOT NULL
);
```

### **2. Alerts Table (new)**

```sql
CREATE TABLE WatchdogAlerts (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Timestamp DATETIME NOT NULL,
    TemperatureF FLOAT NOT NULL,
    RollingAvg FLOAT NOT NULL,
    RateOfChange FLOAT NOT NULL,
    Message VARCHAR(255) NOT NULL,
    SourceIP VARCHAR(50) NOT NULL
);
```

---

# ✅ Updated PowerShell Script  
**Includes rolling average, rate‑of‑change, and alert logging**

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
$RollingWindow = 5   # number of samples for rolling average

# SQL settings
$SqlServer   = "SQLSERVER01"
$SqlDatabase = "EnvironmentMonitoring"

$ConnString = "Server=$SqlServer;Database=$SqlDatabase;Integrated Security=True;TrustServerCertificate=True;"

# ================================
# SQL Logging Functions
# ================================
function Write-TemperatureToSql {
    param(
        [datetime]$Timestamp,
        [double]$TempF,
        [string]$SourceIP
    )

    $query = @"
INSERT INTO WatchdogTemperatureLog (Timestamp, TemperatureF, SourceIP)
VALUES (@ts, @temp, @ip);
"@

    $connection = New-Object System.Data.SqlClient.SqlConnection $ConnString
    $command = $connection.CreateCommand()
    $command.CommandText = $query

    $command.Parameters.Add("@ts",   [System.Data.SqlDbType]::DateTime)  | Out-Null
    $command.Parameters.Add("@temp", [System.Data.SqlDbType]::Float)     | Out-Null
    $command.Parameters.Add("@ip",   [System.Data.SqlDbType]::VarChar,50)| Out-Null

    $command.Parameters["@ts"].Value   = $Timestamp
    $command.Parameters["@temp"].Value = $TempF
    $command.Parameters["@ip"].Value   = $SourceIP

    try { $connection.Open(); $command.ExecuteNonQuery() | Out-Null }
    catch { Write-Warning "SQL logging failed: $_" }
    finally { $connection.Close() }
}

function Write-AlertToSql {
    param(
        [datetime]$Timestamp,
        [double]$TempF,
        [double]$RollingAvg,
        [double]$RateOfChange,
        [string]$Message,
        [string]$SourceIP
    )

    $query = @"
INSERT INTO WatchdogAlerts (Timestamp, TemperatureF, RollingAvg, RateOfChange, Message, SourceIP)
VALUES (@ts, @temp, @avg, @roc, @msg, @ip);
"@

    $connection = New-Object System.Data.SqlClient.SqlConnection $ConnString
    $command = $connection.CreateCommand()
    $command.CommandText = $query

    $command.Parameters.Add("@ts",   [System.Data.SqlDbType]::DateTime)  | Out-Null
    $command.Parameters.Add("@temp", [System.Data.SqlDbType]::Float)     | Out-Null
    $command.Parameters.Add("@avg",  [System.Data.SqlDbType]::Float)     | Out-Null
    $command.Parameters.Add("@roc",  [System.Data.SqlDbType]::Float)     | Out-Null
    $command.Parameters.Add("@msg",  [System.Data.SqlDbType]::VarChar,255)| Out-Null
    $command.Parameters.Add("@ip",   [System.Data.SqlDbType]::VarChar,50)| Out-Null

    $command.Parameters["@ts"].Value   = $Timestamp
    $command.Parameters["@temp"].Value = $TempF
    $command.Parameters["@avg"].Value  = $RollingAvg
    $command.Parameters["@roc"].Value  = $RateOfChange
    $command.Parameters["@msg"].Value  = $Message
    $command.Parameters["@ip"].Value   = $SourceIP

    try { $connection.Open(); $command.ExecuteNonQuery() | Out-Null }
    catch { Write-Warning "SQL alert logging failed: $_" }
    finally { $connection.Close() }
}

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

        $Samples += [PSCustomObject]@{
            Time  = $timestamp
            TempF = $temp
        }

        Write-TemperatureToSql -Timestamp $timestamp -TempF $temp -SourceIP $HostIP

        # Rolling average (last N samples)
        $RecentTemps = $Samples | Select-Object -Last $RollingWindow
        $RollingAvg = ($RecentTemps.TempF | Measure-Object -Average).Average

        # Rate of change (°F per minute)
        if ($Samples.Count -gt 1) {
            $Prev = $Samples[-2]
            $DeltaTemp = $temp - $Prev.TempF
            $DeltaMinutes = ($timestamp - $Prev.Time).TotalMinutes
            $RateOfChange = $DeltaTemp / $DeltaMinutes
        } else {
            $RateOfChange = 0
        }

        Write-Host "$timestamp Temp: $temp F | Avg: $([math]::Round($RollingAvg,2)) | ROC: $([math]::Round($RateOfChange,2)) F/min"

        # Alert condition
        if ($temp -gt $ThresholdF -and $RateOfChange -gt 0) {
            $msg = "Temperature above $ThresholdF F and rising"
            Write-Warning $msg

            Write-AlertToSql -Timestamp $timestamp `
                             -TempF $temp `
                             -RollingAvg $RollingAvg `
                             -RateOfChange $RateOfChange `
                             -Message $msg `
                             -SourceIP $HostIP
        }
    }
    else {
        Write-Warning "SNMP query failed at $(Get-Date)"
    }

    Start-Sleep -Seconds $SampleSeconds
}
```

---

# ✅ What You Now Have

### ✅ Rolling Average  
Uses the last **N samples** (default 5) to smooth out noise.

### ✅ Rate of Change  
Calculates °F per minute between the last two samples.

### ✅ Alert Table  
Stores:

- Timestamp  
- Temperature  
- Rolling average  
- Rate of change  
- Human‑readable message  
- Source IP  

### ✅ Alert Trigger  
Fires when:

- Temperature > 95°F  
- Rate of change > 0 (rising)  

You can easily expand this to include humidity, multiple sensors, or more complex logic.

---

If you want, I can help you:

- Turn this into a **continuous service**  
- Add **email/SMS alerts**  
- Add **SQL stored procedures**  
- Build a **Grafana dashboard** over the SQL data  

Just tell me where you want to take it next.