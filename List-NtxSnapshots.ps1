# SCRIPT INFO -------------------
# --- Query all Snapshots on Nutanix ---
# By Chris Jeucken
# v0.9
# -------------------------------
# Run on management server with NutanixCmdlets installed

# VARIABLES ---------------------
# Default variables
$NTNXSnapin = "NutanixCmdletsPSSnapin"

# Set environment specific variables
    $NTNXCluster = "*** PROVIDE NUTANIX CLUSTER FQDN/HOSTNAME/IP ***" # Divide multiple clusters with semicolon (;).
    $NTNXException = "XDSNAP*" # Provide exceptions (if any) for specific snapshots (e.g.: XDSNAP*), divide with semicolon (;), leave empty if no exceptions.
# -------------------------------

# SCRIPT ------------------------
# Convert variables to multi line
    $NTNXCluster = $NTNXCluster.Split(";")
    $NTNXException = $NTNXException.Split(";")

# Get credentials from user
    $NTNXCredentials = Get-Credential -Message "Please provide Nutanix administrator credentials (e.g.: admin@domain.suffix):"

# Importing Nutanix Cmdlets
    $Loaded = Get-PSSnapin -Name $NTNXSnapin -ErrorAction SilentlyContinue | ForEach-Object {$_.Name}
    $Registered = Get-PSSnapin -Name $NTNXSnapin -Registered -ErrorAction SilentlyContinue | ForEach-Object {$_.Name}

    foreach ($Snapin in $Registered) {
        if ($Loaded -notcontains $Snapin) {
            Add-PSSnapin $Snapin
        }
    }

# Connect to Nutanix Clusters
    foreach ($Cluster in $NTNXCluster) {
        try {
            Connect-NTNXCluster -Server $Cluster -Password $NTNXCredentials.Password -UserName $NTNXCredentials.UserName -ErrorAction SilentlyContinue | Out-Null
        } catch {
            Write-Host *** Not able to connect to Nutanix Cluster $Cluster *** -ForegroundColor Red
        }
    }

# Test connection to Nutanix cluster
    if (!(Get-NTNXCluster -ErrorAction SilentlyContinue)) {
        Write-Host *** No functional Nutanix connection available *** -ForegroundColor Red
        exit
    }

# Create results table
    if ($Results) {
        Remove-Variable -Name Results
    }
    $Results = New-Object system.Data.DataTable "All NTNX snapshots"
    $Column1 = New-Object System.Data.DataColumn VM-Name,([string])
    $Column2 = New-Object System.Data.DataColumn Snapshot-Name,([string])
    $Column3 = New-Object System.Data.DataColumn Creation-Time,([string])
    $Results.Columns.Add($Column1)
    $Results.Columns.Add($Column2)
    $Results.Columns.Add($Column3)

# Get all VMs and snapshots
    $AllNTNXVM = Get-NTNXVM -ErrorAction SilentlyContinue
    $AllNTNXSnapshots = Get-NTNXSnapshot -ErrorAction SilentlyContinue

# Handle exceptions (if any)
    if ($NTNXException) {
        foreach ($Exception in $NTNXException) {
            $AllNTNXSnapshots = $AllNTNXSnapshots | Where-Object {$_.snapshotName -notlike $Exception}
        }
    }

# Find VM for each snapshot and export to table
    foreach ($Snapshot in $AllNTNXSnapshots) {
        $VMUuid = $Snapshot.vmUuid
        $VMname = ($AllNTNXVM |  Where-Object {$_.Uuid -eq $VMUuid}).vmName
        $SnapshotName = $Snapshot.snapshotName
        $CreationTimeStamp = ($Snapshot.createdTime)/1000
        $CreationTime = (Get-Date '1/1/1970').AddMilliseconds($CreationTimeStamp)
        $SnapshotCreationTime = $CreationTime.ToLocalTime()

        $Row = $Results.NewRow()
        $Row."VM-Name" = $VMname
        $Row."Snapshot-Name" = $SnapshotName
        $Row."Creation-Time" = $SnapshotCreationTime
        $Results.Rows.Add($Row)
    }

# Disconnect from Nutanix Clusters
    foreach ($Cluster in $NTNXCluster) {
        if (Get-NTNXCluster -ErrorAction SilentlyContinue) {
            Disconnect-NTNXCluster -Server $Cluster
        }
    }

# Present results
    $Results | Format-Table
# -------------------------------