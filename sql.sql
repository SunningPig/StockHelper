USE [master]
GO
/****** Object:  Database [StockHelper]    Script Date: 2016/11/30 18:08:49 ******/
CREATE DATABASE [StockHelper]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'StockHelper', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.YUANJIACHENG\MSSQL\DATA\StockHelper.mdf' , SIZE = 2072576KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'StockHelper_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.YUANJIACHENG\MSSQL\DATA\StockHelper_log.ldf' , SIZE = 5605504KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [StockHelper] SET COMPATIBILITY_LEVEL = 100
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [StockHelper].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [StockHelper] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [StockHelper] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [StockHelper] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [StockHelper] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [StockHelper] SET ARITHABORT OFF 
GO
ALTER DATABASE [StockHelper] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [StockHelper] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [StockHelper] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [StockHelper] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [StockHelper] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [StockHelper] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [StockHelper] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [StockHelper] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [StockHelper] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [StockHelper] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [StockHelper] SET  DISABLE_BROKER 
GO
ALTER DATABASE [StockHelper] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [StockHelper] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [StockHelper] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [StockHelper] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [StockHelper] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [StockHelper] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [StockHelper] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [StockHelper] SET RECOVERY FULL 
GO
ALTER DATABASE [StockHelper] SET  MULTI_USER 
GO
ALTER DATABASE [StockHelper] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [StockHelper] SET DB_CHAINING OFF 
GO
ALTER DATABASE [StockHelper] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [StockHelper] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
USE [StockHelper]
GO
/****** Object:  User [StockHelper]    Script Date: 2016/11/30 18:08:49 ******/
CREATE USER [StockHelper] FOR LOGIN [StockHelper] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [StockHelper]
GO
ALTER ROLE [db_accessadmin] ADD MEMBER [StockHelper]
GO
ALTER ROLE [db_securityadmin] ADD MEMBER [StockHelper]
GO
ALTER ROLE [db_ddladmin] ADD MEMBER [StockHelper]
GO
ALTER ROLE [db_backupoperator] ADD MEMBER [StockHelper]
GO
ALTER ROLE [db_datareader] ADD MEMBER [StockHelper]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [StockHelper]
GO
ALTER ROLE [db_denydatareader] ADD MEMBER [StockHelper]
GO
ALTER ROLE [db_denydatawriter] ADD MEMBER [StockHelper]
GO
/****** Object:  UserDefinedTableType [dbo].[StockHistoryData]    Script Date: 2016/11/30 18:08:49 ******/
CREATE TYPE [dbo].[StockHistoryData] AS TABLE(
	[StockHistoryDataID] [uniqueidentifier] NULL,
	[StockCode] [nvarchar](10) NULL,
	[StockHistoryDate] [nvarchar](50) NULL,
	[SOpen] [decimal](18, 2) NULL,
	[SHigh] [decimal](18, 2) NULL,
	[SLow] [decimal](18, 2) NULL,
	[SClose] [decimal](18, 2) NULL,
	[SVolume] [bigint] NULL
)
GO
/****** Object:  UserDefinedTableType [dbo].[StockMatchedIndex]    Script Date: 2016/11/30 18:08:49 ******/
CREATE TYPE [dbo].[StockMatchedIndex] AS TABLE(
	[StockMatchedIndexID] [uniqueidentifier] NULL,
	[StockIndexID] [int] NULL,
	[StockCode] [nvarchar](6) NULL,
	[Date] [date] NULL
)
GO
/****** Object:  StoredProcedure [dbo].[up_DataMaintain]    Script Date: 2016/11/30 18:08:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		袁加诚
-- Create date: 2016年11月17日16:15:01
-- Description:	数据维护
-- =============================================
CREATE PROCEDURE [dbo].[up_DataMaintain]
	-- Add the parameters for the stored procedure here
	@Date date
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	begin tran DataDistinct
	--StockHistoryData 去重
	delete from StockHistoryData where StockHistoryDataID 
	not in(
			select max(StockHistoryDataID) from StockHistoryData where StockHistoryDate=@Date
			group by StockCode
			) and StockHistoryDate=@Date
	if @@ERROR<>0 goto error
	--StockMatchedindex 去重
	delete from StockMatchedIndex where StockMatchedIndexID
	not in(
			select max(StockMatchedIndexID) from StockMatchedIndex where Date=@Date
			group by StockCode,StockIndexID
		) and Date=@Date
	--清除非交易日数据（行情下载时无法区分停牌和非交易日，要在这里清除）
	if not exists(select 1 from StockHistoryData where StockHistoryDate=@Date and SVolume !=0)
	begin
	delete from StockHistoryData where StockHistoryDate=@Date
	end
	if @@ERROR<>0 goto error
	commit tran DataDistinct
	select 1
	error:
	if @@ERROR<>0
	begin
		rollback tran DataDistinct
		select -201
	end
	
END

GO
/****** Object:  StoredProcedure [dbo].[up_InsertStockHistoryData]    Script Date: 2016/11/30 18:08:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		袁加诚
-- Create date: 2016年9月19日19:54:42
-- Description:	下载更新股票历史数据表
-- =============================================
CREATE PROCEDURE [dbo].[up_InsertStockHistoryData]
	@StockHistoryData StockHistoryData readonly,
	@DownDate date=null
AS
BEGIN
	SET NOCOUNT ON;
	begin tran InsertStockHistoryData
		--日常数据下载
		if(@DownDate is not null)
			begin
				declare @StockCode nvarchar(10)
				select @StockCode= StockCode from @StockHistoryData
				if exists(
				 select 1 from @StockHistoryData as s1
				  inner join(select top 1 * from StockHistoryData where StockCode=@StockCode order by StockHistoryDate desc) as s2
				  on s1.SClose=s2.SClose and s1.SHigh=s2.SHigh and s1.SLow=s2.SLow and s1.SOpen=s2.SOpen and s1.SVolume=s2.SVolume
				  where s1.SVolume!=0)
				  begin
					select 1
					return
				  end
				insert into DownDataStatus
				(
					DownDataStatusID,
					StockCode,
					DownDate,
					[Status]
				)
				select NEWID(),d.StockCode,@DownDate,1
				from @StockHistoryData as d
				left outer join StockHistoryData as d1 
				on d1.StockHistoryDate=CONVERT(date, d.StockHistoryDate) and d1.StockCode=d.StockCode
				where d1.StockHistoryDataID is null
				if @@ERROR<>0 goto error
			end
		--数据表 插入
		insert into StockHistoryData
		(
			StockHistoryDataID,
			StockHistoryDate,
			SClose,
			SHigh,
			SLow,
			SOpen,
			SVolume,
			StockCode
		)
		select NEWID(),CONVERT(date, isnull(d.StockHistoryDate,getdate())),d.SClose,d.SHigh,d.SLow,d.SOpen,d.SVolume,d.StockCode
		from @StockHistoryData as d 
		if @@ERROR<>0 goto error
	commit tran InsertStockHistoryData
	select 1
	error:
	if @@ERROR<>0
	begin
		rollback tran InsertStockHistoryData
		select -201
	end
	
END

GO
/****** Object:  StoredProcedure [dbo].[up_insertStockMatchedIndex]    Script Date: 2016/11/30 18:08:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		袁加诚
-- Create date: 2016年10月17日10:35:38
-- Description:	新增修改股票指标匹配表
-- =============================================
CREATE PROCEDURE [dbo].[up_insertStockMatchedIndex] 
	@StockMatchedIndex StockMatchedIndex readonly
AS
BEGIN
	SET NOCOUNT ON;
	begin tran insertStockMatchedIndex

	insert StockMatchedIndex
	(
	  StockMatchedIndexID,
	  StockIndexID,
	  StockCode,
	  [Date]
	)
	select smi1.StockMatchedIndexID,smi1.StockIndexID,smi1.StockCode,smi1.[Date]  from @StockMatchedIndex as smi1 
	commit tran insertStockMatchedIndex
	select 1
	error:
	if @@ERROR<>0
	begin
		rollback tran insertStockMatchedIndex
		select -201
	end
END


GO
/****** Object:  StoredProcedure [dbo].[up_InsertUpdateStockList]    Script Date: 2016/11/30 18:08:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		袁加诚
-- Create date: 2016年9月17日16:07:24
-- Description:	下载更新股票列表表
-- =============================================
CREATE PROCEDURE [dbo].[up_InsertUpdateStockList]
	@StockCode nvarchar(6),
	@StockName nvarchar(20)
AS
BEGIN
	SET NOCOUNT ON;
	begin tran insertUpdateStockList
	if exists(select 1 from StockList where StockCode=@StockCode)
	begin
		update StockList set StockName=@StockName where StockCode=@StockCode
		if @@ERROR<>0 goto error
	end
	else
	begin
		insert into StockList (StockCode,StockName) values(@StockCode,@StockName)
		if @@ERROR<>0 goto error
	end
	commit tran insertUpdateStockList
	select 1
	error:
	if @@ERROR<>0
	begin
		rollback tran insertUpdateStockList
		select -201
	end
END

GO
/****** Object:  UserDefinedFunction [dbo].[f_GetStockIndexTemplateStockCode]    Script Date: 2016/11/30 18:08:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[f_GetStockIndexTemplateStockCode]
(	
	@StockIndexIDList nvarchar(500),
	@Date date
)
RETURNS @tb TABLE (StockCode nvarchar(20))
AS
begin
declare @cols as table(col nvarchar(10))
declare @colCount int
insert into @cols(col)
select col from dbo.f_split(@StockIndexIDList,',')
select @colCount= COUNT(*) from @cols
insert into @tb(StockCode)
select smi.StockCode from StockMatchedIndex as smi where smi.StockIndexID in (select col from @cols) and smi.Date=@Date
group by smi.StockCode having count(smi.StockCode)>=@colCount

RETURN 
end;


GO
/****** Object:  UserDefinedFunction [dbo].[f_split]    Script Date: 2016/11/30 18:08:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[f_split](@c varchar(2000),@split varchar(2)) 
returns @t table(col varchar(20)) 
as 
    begin 
    
      while(charindex(@split,@c)<>0) 
        begin 
          insert @t(col) values (substring(@c,1,charindex(@split,@c)-1)) 
          set @c = stuff(@c,1,charindex(@split,@c),'') 
        end 
      insert @t(col) values (@c) 
      return 
    end 

GO
/****** Object:  Table [dbo].[DownDataStatus]    Script Date: 2016/11/30 18:08:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DownDataStatus](
	[DownDataStatusID] [uniqueidentifier] NOT NULL,
	[StockCode] [nvarchar](10) NULL,
	[DownDate] [date] NULL,
	[Status] [bit] NULL,
 CONSTRAINT [PK_DownDataStauts] PRIMARY KEY NONCLUSTERED 
(
	[DownDataStatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[StockHistoryData]    Script Date: 2016/11/30 18:08:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StockHistoryData](
	[StockHistoryDataID] [uniqueidentifier] NOT NULL,
	[StockHistoryDate] [date] NOT NULL,
	[StockCode] [nvarchar](10) NULL,
	[SOpen] [decimal](18, 2) NULL,
	[SClose] [decimal](18, 2) NULL,
	[SHigh] [decimal](18, 2) NULL,
	[SLow] [decimal](18, 2) NULL,
	[SVolume] [bigint] NULL,
 CONSTRAINT [PK_StockHistoryData] PRIMARY KEY NONCLUSTERED 
(
	[StockHistoryDataID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[StockIndex]    Script Date: 2016/11/30 18:08:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StockIndex](
	[StockIndexID] [int] NOT NULL,
	[StockIndexName] [nvarchar](100) NULL,
 CONSTRAINT [PK_StockIndex] PRIMARY KEY CLUSTERED 
(
	[StockIndexID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[StockIndexTemplate]    Script Date: 2016/11/30 18:08:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StockIndexTemplate](
	[StockIndexTemplateID] [uniqueidentifier] NOT NULL,
	[StockIndexTemplateName] [nvarchar](20) NULL,
	[StockIndexIDList] [nvarchar](500) NULL,
 CONSTRAINT [PK_StockIndexTemplate] PRIMARY KEY CLUSTERED 
(
	[StockIndexTemplateID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[StockList]    Script Date: 2016/11/30 18:08:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StockList](
	[StockCode] [nvarchar](10) NOT NULL,
	[StockName] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK_StockList] PRIMARY KEY CLUSTERED 
(
	[StockCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[StockMatchedIndex]    Script Date: 2016/11/30 18:08:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StockMatchedIndex](
	[StockMatchedIndexID] [uniqueidentifier] NOT NULL,
	[StockIndexID] [int] NOT NULL,
	[StockCode] [nvarchar](10) NOT NULL,
	[Date] [date] NOT NULL,
 CONSTRAINT [PK_StockMatchedIndex\] PRIMARY KEY NONCLUSTERED 
(
	[StockMatchedIndexID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  View [dbo].[uv_StockHistoryData]    Script Date: 2016/11/30 18:08:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[uv_StockHistoryData]
AS
SELECT     dbo.StockHistoryData.StockHistoryDataID, dbo.StockHistoryData.StockHistoryDate, dbo.StockHistoryData.StockCode, dbo.StockHistoryData.SOpen, dbo.StockHistoryData.SClose, 
                      dbo.StockHistoryData.SHigh, dbo.StockHistoryData.SLow, dbo.StockHistoryData.SVolume, dbo.StockList.StockName
FROM         dbo.StockHistoryData INNER JOIN
                      dbo.StockList ON dbo.StockHistoryData.StockCode = dbo.StockList.StockCode

GO
/****** Object:  View [dbo].[uv_StockIndexDailyWeight]    Script Date: 2016/11/30 18:08:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[uv_StockIndexDailyWeight]
AS
SELECT   dbo.StockIndexDailyWeight.StockIndexDailyWeightID, dbo.StockIndexDailyWeight.StockIndexHistoryDate, 
                dbo.StockIndexDailyWeight.StockIndexID, dbo.StockIndexDailyWeight.StockIndexWeightValue, 
                dbo.StockIndex.StockIndexName, dbo.StockIndexDailyWeight.MatchedStockIndexCount
FROM      dbo.StockIndexDailyWeight INNER JOIN
                dbo.StockIndex ON dbo.StockIndexDailyWeight.StockIndexID = dbo.StockIndex.StockIndexID

GO
/****** Object:  Index [IX_DownDataStauts]    Script Date: 2016/11/30 18:08:49 ******/
CREATE CLUSTERED INDEX [IX_DownDataStauts] ON [dbo].[DownDataStatus]
(
	[DownDate] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_StockHistoryData]    Script Date: 2016/11/30 18:08:49 ******/
CREATE CLUSTERED INDEX [IX_StockHistoryData] ON [dbo].[StockHistoryData]
(
	[StockHistoryDate] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_StockMatchedIndex\]    Script Date: 2016/11/30 18:08:49 ******/
CREATE CLUSTERED INDEX [IX_StockMatchedIndex\] ON [dbo].[StockMatchedIndex]
(
	[Date] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "StockHistoryData"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 126
               Right = 221
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "StockList"
            Begin Extent = 
               Top = 6
               Left = 259
               Bottom = 96
               Right = 401
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'uv_StockHistoryData'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'uv_StockHistoryData'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "StockIndexDailyWeight"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 146
               Right = 273
            End
            DisplayFlags = 280
            TopColumn = 1
         End
         Begin Table = "StockIndex"
            Begin Extent = 
               Top = 6
               Left = 311
               Bottom = 108
               Right = 499
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'uv_StockIndexDailyWeight'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'uv_StockIndexDailyWeight'
GO
USE [master]
GO
ALTER DATABASE [StockHelper] SET  READ_WRITE 
GO
