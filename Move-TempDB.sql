--Run the following query to find the current location of the TempDB file.
--This query will display the current file location (s) of the TempDB database.: 
USE tempdb; 
GO 
SELECT name, physical_name AS 'Current Location' 
FROM sys.master_files 
WHERE database_id = DB_ID ('tempdb'); 
GO

-- Generate T-SQL to remove tempdb files
SELECT 'DBCC SHRINKFILE (N'''+ f.name + ''', EMPTYFILE);
GO
ALTER DATABASE tempdb  REMOVE FILE [' + f.name + '];
GO'
FROM sys.master_files f
WHERE f.database_id = DB_ID(N'tempdb');
GO

-- Generate T-SQL to move existing tempdb files to another location
SELECT 'ALTER DATABASE tempdb MODIFY FILE (NAME = [' + f.name + '],'
	+ ' FILENAME = ''\\SQLLogs\L$\' + f.name
	+ CASE WHEN f.type = 1 THEN '.ldf' ELSE '.mdf' END
	+ ''');'
FROM sys.master_files f
WHERE f.database_id = DB_ID(N'tempdb');
GO

-- Generate T-SQl to move data and log files
SELECT 'ALTER DATABASE ' + db_name(f.database_id) + ' MODIFY FILE (NAME = [' + f.name + '],'
	+ CASE WHEN f.type = 1 
		THEN ' FILENAME = ''\\SQLLogs\L$\' + f.name + '.ldf' 
		ELSE ' FILENAME = ''\\SQLData\D$\MSSQL\' + f.name + '.mdf' END
	+ ''');'
FROM sys.master_files f
WHERE f.database_id != DB_ID(N'tempdb');
GO