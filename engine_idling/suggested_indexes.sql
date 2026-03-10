-- episode_duration_fequency_date
/*
Missing Index Details from compiled_episode_drilldown.sql
The Query Processor estimates that implementing the following index could improve the query cost by 82.8309%.
*/

/*
USE [frp]
GO
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
ON [dbo].[fact_engine_idling_episode] ([toc_id],[episode_start_time])
INCLUDE ([episode_duration_minutes])
GO
*/

-- episode_duration_fequency_period
/*
Missing Index Details from compiled_episode_duration_frequency.sql
The Query Processor estimates that implementing the following index could improve the query cost by 96.8786%.
*/

/*
USE [frp]
GO
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
ON [dbo].[fact_engine_idling_episode] ([period_sort_id],[toc_id])
INCLUDE ([episode_duration_minutes])
GO
*/


-- episode_drilldown_date
/*
Missing Index Details from compiled_episode_drilldown_date.sql
The Query Processor estimates that implementing the following index could improve the query cost by 61.548%.
*/

/*
USE [frp]
GO
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
ON [dbo].[fact_engine_idling_episode] ([toc_id],[episode_start_time],[episode_duration_seconds])
INCLUDE ([class_id],[unit_id],[vehicle_id],[gps_lat],[gps_lon],[location_025km])
GO
*/

-- episode_drilldown_period
/*
Missing Index Details from compiled_episode_drilldown_period.sql
The Query Processor estimates that implementing the following index could improve the query cost by 54.8541%.
*/

/*
USE [frp]
GO
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
ON [dbo].[fact_engine_idling_episode] ([period_sort_id],[toc_id],[episode_duration_seconds])
INCLUDE ([class_id],[unit_id],[vehicle_id],[episode_start_time],[gps_lat],[gps_lon],[location_025km])
GO
*/

-- kpis_period
/*
Missing Index Details from compiled_kpis_period.sql
The Query Processor estimates that implementing the following index could improve the query cost by 32.8822%.
*/

/*
USE [frp]
GO
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
ON [dbo].[fact_engine_idling_episode] ([toc_id])
INCLUDE ([episode_start_time],[episode_duration_minutes],[period_sort_id])
GO
*/
/*
Missing Index Details from compiled_kpis_period.sql
The Query Processor estimates that implementing the following index could improve the query cost by 32.0404%.
*/

/*
USE [frp]
GO
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
ON [dbo].[fact_engine_idling_episode] ([toc_id])
INCLUDE ([episode_start_time],[period_sort_id])
GO
*/


--kpis_date
/*
Missing Index Details from compiled_kpis_date.sql
The Query Processor estimates that implementing the following index could improve the query cost by 36.3261%.
*/

/*
USE [frp]
GO
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
ON [dbo].[fact_engine_idling_episode] ([toc_id])
INCLUDE ([episode_start_time],[episode_duration_minutes])
GO
*/

/*
Missing Index Details from compiled_kpis_date.sql
The Query Processor estimates that implementing the following index could improve the query cost by 35.4021%.
*/

/*
USE [frp]
GO
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
ON [dbo].[fact_engine_idling_episode] ([toc_id])
INCLUDE ([episode_start_time])
GO
*/


--top_five_period
/*
Missing Index Details from compiled_top_five_period.sql
The Query Processor estimates that implementing the following index could improve the query cost by 88.5939%.
*/

/*
USE [frp]
GO
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
ON [dbo].[fact_engine_idling_episode] ([period_sort_id],[toc_id],[unit_id])
INCLUDE ([episode_duration_minutes])
GO
*/


--top_five_date
/*
Missing Index Details from compiled_top_five_date.sql
The Query Processor estimates that implementing the following index could improve the query cost by 90.8248%.
*/

/*
USE [frp]
GO
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
ON [dbo].[fact_engine_idling_episode] ([toc_id],[unit_id],[episode_start_time])
INCLUDE ([episode_duration_minutes])
GO
*/
