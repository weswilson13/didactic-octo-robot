using Module ImportExcel
using Module SqlServer
using Namespace System.Data.SqlClient    

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [String]$ServerInstance
    ,
    [Parameter(Mandatory=$true)]
    [String]$Database
    ,
    [Parameter(Mandatory=$true)]
    [String]$PathToExcel
    ,
    [Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
    [String[]]$WorksheetName
)

Begin {
#region create the database connection objects
    $sqlConnection = [SqlConnection]::new()
    $sqlConnection.ConnectionString = "Server=$ServerInstance; Database=$Database; Integrated Security=True;"
    $sqlConnection.Open()

    $sqlCmd = [SqlCommand]::new()
    $sqlCmd.Connection = $sqlConnection
#endregion

#region drop the tmpTable if it exists
    $sqlCmd.CommandText = "Drop Table if exists ##tmpTable"
    Write-Verbose $sqlCmd.CommandText
    $sqlCmd.ExecuteNonQuery() | Out-Null
#endregion

#region create tmpTable from the existing table then truncate to prepare for the new data
    $sqlCmd.CommandText = "SELECT * INTO ##tmpTable FROM [HumanResources].[vEmployeeDepartment]; TRUNCATE TABLE ##tmpTable;"
    Write-Verbose $sqlCmd.CommandText
    $sqlCmd.ExecuteNonQuery() | Out-Null
#endregion
}

Process {
#region insert the new data into the tmpTable
    $SQL = ConvertFrom-ExcelToSQLInsert -Path $PathToExcel -TableName "##tmpTable" -WorksheetName $WorksheetName -UseMsSqlSyntax -StartRow 2 -DataOnly -SingleQuoteStyle "''" -ConvertEmptyStringsToNull
    $SQL.foreach({
        #$sqlCmd.CommandText = "SET IDENTITY_INSERT ##tmpTable ON; $_"
        Write-Host $_
        $sqlCmd.CommandText = $_
        Write-Verbose $sqlCmd.CommandText
        $sqlCmd.ExecuteNonQuery() | Out-Null 
    })
#endregion
}

End {
# #region remove rows of empty data from tmpTable
#     $sqlCmd.CommandText =  "DELETE FROM ##tmpTable WHERE BusinessEntityID=0"
#     $sqlCmd.ExecuteNonQuery() | Out-Null 
# #endregion

#region merge the tmpTable (source) with the original table (target)
    $sqlCmd.CommandText =   "MERGE esqlProductTarget T
                            USING #tmpTable S
                            ON (S.ProductID = T.ProductID)
                            WHEN MATCHED 
                                THEN UPDATE
                                SET    T.Name = S.Name,
                                        T.ProductNumber = S.ProductNumber,
                                        T.Color = S.Color
                            WHEN NOT MATCHED BY TARGET
                            THEN INSERT (ProductID, Name, ProductNumber, Color)
                                VALUES (S.ProductID, S.Name, S.ProductNumber, S.Color)
                            WHEN NOT MATCHED BY SOURCE
                            THEN DELETES
                            OUTPUT S.ProductID, `$action into @MergeLog;"
    Write-Verbose $sqlCmd.CommandText
    $sqlCmd.ExecuteNonQuery() | Out-Null 
#endregion

start-sleep 30

#region drop the tmpTable
    $sqlCmd.CommandText = "Drop Table if exists ##tmpTable"
    Write-Verbose $sqlCmd.CommandText
    $sqlCmd.ExecuteNonQuery() | Out-Null
#endregion

#region cleanup 
    $sqlConnection.Close()
    $sqlConnection.Dispose()
    $sqlCmd.Dispose()
#endregion
}