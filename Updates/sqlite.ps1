using assembly ..\nugetPackages\System.Data.SQLite.dll

$tables = 'Software','Printers'
# create the db
[System.Data.SQLite.SQLiteConnection]::new("versions.db")

# connect to the db
$db = New-Object System.Data.SQLite.SQLiteConnection("Data Source=versions.db")

# open the db
$db.Open()

foreach ($table in $tables) { # create the table if it doesn't exist
    
    $tableCommand = switch ($table) {
        'software' { 
            "CREATE TABLE IF NOT " +
            "EXISTS Software (" +
                "ID INTEGER PRIMARY KEY, " +
                "Product NVARCHAR(50) NULL, " +
                "APIVersion NVARCHAR(10) NULL, " +
                "FileVersion NVARCHAR(10) NULL" +
            ")"
        }
        'printers' {
            "CREATE TABLE IF NOT " +
            "EXISTS Printers (" +
                "ID INTEGER PRIMARY KEY, " +
                "Product NVARCHAR(50) NULL, " +
                "PrinterSeries NVARCHAR(500) NULL, " +
                "Version NVARCHAR(500) NULL" +
            ")"
        }
    }

    $createTableCommand = New-Object System.Data.SQLite.SQLiteCommand($tableCommand, $db)
    $createTableCommand.ExecuteReader()
}

# populate the table
$data = get-content .\versions.txt
foreach ($line in $data) {
    $obj = ConvertFrom-Json -InputObject $line
    $query = switch ($obj.Product) {
        'Printer' {
            "INSERT INTO Printers (Product, PrinterSeries, Version) " +
            "VALUES ('{0}','{1}','{2}')" -f $obj.Product, $obj.PrinterSeries, $obj.Version    
        }
        default {
            "INSERT INTO Software (Product, APIVersion, FileVersion) " +
            "VALUES ('{0}','{1}','{2}')" -f $obj.Product, $obj.APIVersion, $obj.FileVersion
        }
    }

    $insertCommand = New-Object System.Data.SQLite.SQLiteCommand($query,$db)
    $insertCommand.ExecuteNonQuery()
}

