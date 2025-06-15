USE [ScriptLogs]
GO

/****** Object:  Trigger [config].[trgScriptConfig]    Script Date: 6/15/2025 8:46:57 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE OR ALTER   TRIGGER [config].[trgScriptConfig] 
   ON  [config].[ScriptConfig] 
   FOR INSERT, DELETE, UPDATE
AS 

DECLARE @now datetime = GETDATE();
DECLARE @username varchar(50) = SUSER_NAME();

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
			  '{"Old":{"Id":"' + CAST(o.[Id] as varchar) + '","Section":"' + ISNULL(o.[Section],'') + '","Key":"' + ISNULL(o.[Key],'') + '","Value":"' + ISNULL(o.[Value],'') + '"},"New":{"Id":"' + CAST(n.[Id] as varchar) + '","Section":"' + ISNULL(n.[Section],'') + '","Key":"' + ISNULL(n.[Key],'') + '","Value":"' + ISNULL(n.[Value],'') + '"}}'
			  FROM deleted as o inner join inserted as n on o.Id = n.Id
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
			  '{"Id":"' + CAST(d.[Id] as varchar) + '","Section":"' + ISNULL(d.[Section],'') + '","Key":"' + ISNULL(d.[Key],'') + '","Value":"' + ISNULL(d.[Value],'') + '"}'
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
			  '{"Id":"' + CAST(i.[Id] as varchar) + '","Section":"' + ISNULL(i.[Section],'') + '","Key":"' + ISNULL(i.[Key],'') + '","Value":"' + ISNULL(i.[Value],'') + '"}'
		  FROM inserted as i
	   END   
GO

ALTER TABLE [config].[ScriptConfig] ENABLE TRIGGER [trgScriptConfig]
GO


-- This trigger logs changes to the ScriptConfig table in the ChangeLog table.
-- It captures INSERT, UPDATE, and DELETE operations.