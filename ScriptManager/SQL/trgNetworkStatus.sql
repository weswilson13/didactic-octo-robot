USE [ScriptLogs]
GO

/****** Object:  Trigger [config].[trgNetworkStatus]    Script Date: 6/14/2025 10:49:49 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE OR ALTER   TRIGGER [config].[trgNetworkStatus] 
   ON  [config].[NetworkStatus] 
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
			  'NetworkStatus',
			  @username,
			  'INFORMATION',
			  'UPDATE',
			  '{"Old":{"Id":"' + CAST(o.[Id] as varchar) + '","DeviceName":"' + ISNULL(o.[DeviceName],'') + '","Port":"' + ISNULL(o.[Port],'') + '","Service":"' + ISNULL(o.[Service],'') + '","Notes":"' + ISNULL(o.[Notes],'') + '","Active":"' + ISNULL(o.[Active],'') + '"},"New":{"Id":"' + CAST(n.[Id] as varchar) + '","DeviceName":"' + ISNULL(n.[DeviceName],'') + '","Port":"' + ISNULL(n.[Port],'') + '","Service":"' + ISNULL(n.[Service],'') + '","Notes":"' + ISNULL(n.[Notes],'') + '","Active":"' + ISNULL(n.[Active],'') + '"}}'
			  FROM deleted as o inner join inserted as n on o.Id = n.ID
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
			  'NetworkStatus',
			  @username,
			  'INFORMATION',
			  'DELETE',
			  '{"Id":"' + CAST(d.[Id] as varchar) + '","DeviceName":"' + ISNULL(d.[DeviceName],'') + '","Port":"' + ISNULL(d.[Port],'') + '","Service":"' + ISNULL(d.[Service],'') + '","Notes":"' + ISNULL(d.[Notes],'') + '","Active":"' + ISNULL(d.[Active],'') + '"}'
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
			  'NetworkStatus',
			  @username,
			  'INFORMATION',
			  'INSERT',
			  '{"Id":"' + CAST(i.[Id] as varchar) + '","DeviceName":"' + ISNULL(i.[DeviceName],'') + '","Port":"' + ISNULL(i.[Port],'') + '","Service":"' + ISNULL(i.[Service],'') + '","Notes":"' + ISNULL(i.[Notes],'') + '","Active":"' + ISNULL(i.[Active],'') + '"}'
		  FROM inserted as i
	   END
GO

ALTER TABLE [config].[NetworkStatus] ENABLE TRIGGER [trgNetworkStatus]
GO