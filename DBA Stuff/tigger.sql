-- ================================================
-- Template generated from Template Explorer using:
-- Create Trigger (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- See additional Create Trigger templates for more
-- examples of different Trigger statements.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE OR ALTER TRIGGER HumanResources.testTrigger 
   ON  HumanResources.Employee 
   FOR INSERT,DELETE,UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT * FROM inserted;
	SELECT * FROM deleted;

    -- Insert statements for trigger here
	DECLARE @tableName nvarchar(50);
	DECLARE @columnName nvarchar(50);
	DECLARE @dataType nvarchar(20);
	DECLARE @oldValue nvarchar(50);
	DECLARE @newValue nvarchar(50);
	DECLARE @modBefore nvarchar(max);
	DECLARE @modAfter nvarchar(max);
	DECLARE @sql nvarchar(max);
	DECLARE @ParmDefinition AS NVARCHAR (500);
	DECLARE @delimiter nvarchar(5) = ', ';

	SELECT @tablename = OBJECT_NAME(parent_object_id) 
    FROM sys.objects 
    WHERE sys.objects.name = OBJECT_NAME(@@PROCID);

	PRINT 'Active Table Name: ' + @tableName;
	PRINT ''

	IF CURSOR_STATUS('global','ColumnCursor')>=-1
	BEGIN
	 DEALLOCATE ColumnCursor
	END

	DECLARE ColumnCursor CURSOR FOR
		SELECT COLUMN_NAME
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = '' + @tableName + ''
	
	IF EXISTS (SELECT 0 FROM deleted) 
	BEGIN 
		IF EXISTS (SELECT 0 FROM inserted) -- An update happened
		PRINT 'An update operation occurred'
		PRINT ''
		BEGIN
			--IF EXISTS (SELECT 1 FROM ##del) DROP TABLE #del;
			--IF EXISTS (SELECT 1 FROM ##ins) DROP TABLE #ins;

			SELECT * INTO ##del FROM deleted;
			SELECT * INTO ##ins FROM inserted;

			OPEN ColumnCursor;

			FETCH NEXT FROM ColumnCursor
				INTO @columnName;

			WHILE @@FETCH_STATUS = 0
			BEGIN
				--PRINT @columnName
				SET @sql = N'SELECT @oldValueOUT = CONVERT(nvarchar(50),' + QUOTENAME(@columnName) + ') FROM ##del'
				SET @ParmDefinition = N'@oldValueOUT nvarchar(50) OUTPUT';
				EXECUTE sp_executesql
					@sql,
					@ParmDefinition,
					@oldValueOUT = @oldValue OUTPUT;

				SET @sql = N'SELECT @newValueOUT = CONVERT(nvarchar(50),' + QUOTENAME(@columnName) + ') FROM ##ins'
				SET @ParmDefinition = N'@newValueOUT nvarchar(50) OUTPUT';
				EXECUTE sp_executesql
					@sql,
					@ParmDefinition,
					@newValueOUT = @newValue OUTPUT;

				--Print 'Old Value: ' + @oldValue + ' | New Value: ' + @newValue;
				IF @oldValue <> @newValue
				BEGIN
					PRINT @columnName + N' was updated';
					SET @modBefore = TRIM(@delimiter FROM CAST(CONCAT(@modBefore, @delimiter, @columnName, N': ', @oldValue) as nvarchar(max)));
					SET @modAfter = TRIM(@delimiter FROM CAST(CONCAT(@modAfter, @delimiter, @columnName, N': ', @newValue) as nvarchar(max)));
				END

				FETCH NEXT FROM ColumnCursor
					INTO @columnName;
			END

			CLOSE ColumnCursor;
			DEALLOCATE ColumnCursor;

			DROP TABLE ##del;
			DROP TABLE ##ins;

			SET @modBefore = N'{' + @modBefore + N'}'
			SET @modAfter = N'{' + @modAfter + N'}'

			PRINT 'Done';
			PRINT N'MODBEFORE: ' + @modBefore;
			PRINT N'MODAFTER: ' + @modAfter;
		END
	END
END
GO

ALTER TABLE HUMANRESOURCES.Employee 
ENABLE TRIGGER testTrigger