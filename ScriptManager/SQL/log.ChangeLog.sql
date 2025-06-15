USE [ScriptLogs]
GO

/****** Object:  Table [log].[ChangeLog]    Script Date: 6/14/2025 10:15:59 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [log].[ChangeLog](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[LogTime] [datetime] NOT NULL,
	[TableName] [nvarchar](50) NULL,
	[Application] [nvarchar](50) NULL,
	[Username] [nvarchar](50) NOT NULL,
	[Severity] [nvarchar](25) NOT NULL,
	[Operation] [nchar](10) NULL,
	[Message] [nvarchar](255) NOT NULL,
 CONSTRAINT [PK_ChangeLog] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'General change tracking' , @level0type=N'SCHEMA',@level0name=N'log', @level1type=N'TABLE',@level1name=N'ChangeLog'
GO

