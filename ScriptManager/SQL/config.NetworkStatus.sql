USE [ScriptLogs]
GO

/****** Object:  Table [config].[NetworkStatus]    Script Date: 6/14/2025 10:15:42 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [config].[NetworkStatus](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[DeviceName] [nchar](10) NULL,
	[Port] [nchar](10) NULL,
	[Service] [nchar](10) NULL,
	[Notes] [nchar](10) NULL,
	[Active] [nchar](10) NULL
) ON [PRIMARY]
GO

