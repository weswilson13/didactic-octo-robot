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
CREATE OR ALTER TRIGGER config.trgNetworkStatus 
   ON  config.NetworkStatus 
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
			  'NetworkStatus',
			  @username,
			  'INFORMATION',
			  'UPDATE',
			  'ID: ' + CAST(u.[Id] as varchar) + ' | Devicename: ' + u.[DeviceName] + ' | Port: ' + u.[Port] + ' | Service: ' + u.[Service] + ' | Notes: ' + u.[Notes] + ' | Active: ' + u.[Active]
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
			  'ID: ' + CAST(d.[Id] as varchar) + ' | Devicename: ' + d.[DeviceName] + ' | Port: ' + d.[Port] + ' | Service: ' + d.[Service] + ' | Notes: ' + d.[Notes] + ' | Active: ' + d.[Active]
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
			  'ID: ' + CAST(i.[Id] as varchar) + ' | Devicename: ' + i.[DeviceName] + ' | Port: ' + i.[Port] + ' | Service: ' + i.[Service] + ' | Notes: ' + i.[Notes] + ' | Active: ' + i.[Active]
		  FROM inserted as i
	   END   
GO
