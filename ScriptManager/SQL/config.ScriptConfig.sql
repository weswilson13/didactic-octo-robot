USE [ScriptLogs]
GO

/****** Object:  Table [config].[ScriptConfig]    Script Date: 6/14/2025 10:14:46 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [config].[ScriptConfig](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Section] [nvarchar](max) NOT NULL,
	[Key] [nvarchar](max) NOT NULL,
	[Value] [nvarchar](max) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

