USE [ScriptLogs]
GO

/****** Object:  Trigger [config].[trgScriptConfig]    Script Date: 6/14/2025 10:13:03 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE OR ALTER TRIGGER [config].[trgScriptConfig] 
   ON  [config].[ScriptConfig] 
   FOR INSERT, DELETE, UPDATE
AS 

DECLARE @now datetime = GETDATE();
DECLARE @username varchar(15) = SUSER_NAME();

IF EXISTS ( SELECT 0 FROM Deleted )
	BEGIN
	   IF EXISTS ( SELECT 0 FROM Inserted ) -- RECORD WAS UPDATED
		   BEGIN
			  INSERT  INTO log.ChangeLog
			  ( LogTime,
				TableName,
				Username,
				Severity,
				Operation,
				Message
			  )
			  SELECT  @now,
			  'ScriptConfig',
			  @username,
			  'INFORMATION',
			  'UPDATE',
			  'ID: ' + CAST(u.[Id] as varchar) + ' | SECTION: ' + u.[Section] + ' | Key: ' + u.[Key] + ' | Value: ' + u.[Value]
			  FROM deleted as u
		   END
		ELSE -- RECORD WAS DELETED
		   BEGIN
			  INSERT  INTO log.ChangeLog
			  ( LogTime,
				TableName,
				Username,
				Severity,
				Operation,
				Message
			  )
			  SELECT  @now,
			  'ScriptConfig',
			  @username,
			  'INFORMATION',
			  'DELETE',
			  'ID: ' + CAST(d.[Id] as varchar) + ' | SECTION: ' + d.[Section] + ' | Key: ' + d.[Key] + ' | Value: ' + d.[Value]
			  FROM deleted as d
		   END
		END
	ELSE -- RECORD WAS INSERTED
	   BEGIN
		  INSERT  INTO log.ChangeLog
			  ( LogTime,
				TableName,
				Username,
				Severity,
				Operation,
				Message
			  )
		  SELECT  @now,
			  'ScriptConfig',
			  @username,
			  'INFORMATION',
			  'INSERT',
			  'ID: ' + CAST(i.[Id] as varchar) + ' | SECTION: ' + i.[Section] + ' | Key: ' + i.[Key] + ' | Value: ' + i.[Value]
		  FROM inserted as i
	   END   
GO

ALTER TABLE [config].[ScriptConfig] ENABLE TRIGGER [trgScriptConfig]
GO

