USE [AO2017]
GO

/****** Object:  View [dbo].[V_Project_Phase]    Script Date: 1/16/2018 8:59:06 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Project_Phase] AS
SELECT
	Project_Phase.project_phase_id
		, Project_Phase.phase_name
		, Project_Phase.project_id 
		, Studio.user_logon Studio_View
		, Project_Phase.flag_active
		, Project_Phase.budget_hours
		, Project_Phase.clc_actual_hours
		, Project_Phase.clc_budget_fees_fixed
		, Project_Phase.clc_actual_fees_total
		, Project_Phase.start_date
		, Project_Phase.end_date
		, Dates.Year Year_View
		, Dates.MonthName Month_View
		, Dates.Actualdate
		, Project_Phase.Daily_Hours_Average
		, Project_Phase.Daily_Dollars_Average
FROM(
	SELECT
		Project_Phase_By_Date.project_phase_id
		, Project_Phase_By_Date.phase_name
		, Project_Phase_By_Date.project_id 
		, Project_Phase_By_Date.flag_active
		, Project_Phase_By_Date.budget_hours
		, Project_Phase_By_Date.clc_actual_hours
		, Project_Phase_By_Date.clc_budget_fees_fixed
		, Project_Phase_By_Date.clc_actual_fees_total
		, Project_Phase_By_Date.start_date
		, Project_Phase_By_Date.end_date
		, (Project_Phase_By_Date.budget_hours - Project_Phase_By_Date.clc_actual_hours) hours_remaining
		, Project_Phase_By_Date.days_remaining
		, SUM(Project_Phase_By_Date.Workday_Flag) Net_Workdays_Remaining
		, CASE WHEN SUM(Project_Phase_By_Date.Workday_Flag) = 0 THEN 0 
			   ELSE (Project_Phase_By_Date.budget_hours - Project_Phase_By_Date.clc_actual_hours) / SUM(Project_Phase_By_Date.Workday_Flag) 
		  END Daily_Hours_Average
		, CASE WHEN SUM(Project_Phase_By_Date.Workday_Flag) = 0 THEN 0 
			   ELSE (Project_Phase_By_Date.clc_budget_fees_fixed - Project_Phase_By_Date.clc_actual_fees_total) / SUM(Project_Phase_By_Date.Workday_Flag) 
		  END Daily_Dollars_Average
	FROM (
		SELECT 
			Projects.project_phase_id
			, Projects.phase_name
			, Projects.project_id 
			, Projects.budget_hours
			, Projects.flag_active
			, ISNULL(Projects.clc_actual_hours,0) clc_actual_hours
			, ISNULL(Projects.clc_budget_fees_fixed, 0) clc_budget_fees_fixed
			, ISNULL(Projects.clc_actual_fees_total,0) clc_actual_fees_total
			, ISNULL(Projects.Start_Date, CAST(GETDATE() AS DATE)) start_date
			, Projects.end_date
			, DATEDIFF(DAY,ISNULL(Projects.Start_Date, CAST(GETDATE() AS DATE)),Projects.end_date) total_days
			, CASE WHEN projects.start_date >= getdate() 
					THEN DATEDIFF(DAY,ISNULL(Projects.Start_Date, CAST(GETDATE() AS DATE)),Projects.end_date)
				   ELSE DATEDIFF(DAY,getdate(),Projects.end_date) 
			  END days_remaining
			, Dates.Actualdate
			, Dates.Week_Beginning_Date
			, CASE WHEN Holidays.holiday_date IS NULL AND Dates.DayNumOfWeek NOT IN (1,7)
					THEN 1
				   ELSE 0
			  END Workday_Flag
		FROM Project_Phase Projects
		LEFT JOIN dbo.Dim_Time Dates
		ON Dates.Actualdate BETWEEN ISNULL(Projects.Start_Date, CAST(GETDATE() AS DATE)) AND Projects.end_date 
		LEFT JOIN dbo.Holidays Holidays
		ON Dates.Actualdate = Holidays.Holiday_Date 
		WHERE Dates.Actualdate BETWEEN ISNULL(Projects.start_date, CAST(GETDATE() AS DATE)) AND Projects.end_date
			AND CAST(GETDATE() AS DATE) <= Projects.end_date
			AND CAST(GETDATE() AS DATE) <= Dates.Actualdate) Project_Phase_By_Date
	GROUP BY Project_Phase_By_Date.project_phase_id
		, Project_Phase_By_Date.phase_name
		, Project_Phase_By_Date.project_id 
		, Project_Phase_By_Date.flag_active
		, Project_Phase_By_Date.budget_hours
		, Project_Phase_By_Date.clc_actual_hours
		, Project_Phase_By_Date.clc_budget_fees_fixed
		, Project_Phase_By_Date.clc_actual_fees_total
		, Project_Phase_By_Date.start_date
		, Project_Phase_By_Date.end_date
		, Project_Phase_By_Date.days_remaining
		) Project_Phase
LEFT JOIN dbo.Dim_Time Dates
ON Dates.Actualdate BETWEEN Project_Phase.start_date AND Project_Phase.end_date
LEFT JOIN dbo.Holidays Holidays
ON Dates.Actualdate = Holidays.Holiday_Date
LEFT JOIN project Project
ON Project_Phase.project_id = Project.project_id
LEFT JOIN user_table Studio
ON Project.principle_id = Studio.user_id
WHERE Holidays.holiday_date IS NULL AND Dates.DayNumOfWeek NOT IN (1,7)
	AND Dates.Actualdate >= CAST(GETDATE() AS DATE)
	AND Project.status <> 'RFP-Lost'
	AND ( CASE 
			WHEN (CAST(Project_Phase.start_date AS DATE) > CAST(GETDATE() AS DATE) OR Project.status IN ('RFP-Open','RFP-Awarded'))
				THEN 'Active' 
			ELSE Project.status 
		  END = 'Active'		  
		)
	AND CASE 
			WHEN (CAST(Project_Phase.start_date AS DATE) > CAST(GETDATE() AS DATE) OR Project.status IN ('RFP-Open','RFP-Awarded'))
				THEN 1 
			ELSE Project_Phase.flag_active 
		END = 1

GO


