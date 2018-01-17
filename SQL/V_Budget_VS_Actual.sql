USE [AO2017]
GO

/****** Object:  View [dbo].[V_Budget_VS_Actual]    Script Date: 1/16/2018 9:09:27 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[V_Budget_VS_Actual]
AS
SELECT Subquery.project_number [Project Number]
		, Subquery.Project
		, Subquery.Phase
		, Subquery.[Start Date]
		, Subquery.[End Date]
		, Subquery.[Hours Allocated]
		, Subquery.[Hours Used]
		, Subquery.[Hours Allocated] - Subquery.[Hours Used] [Hours Remaining]
		, Subquery.[$ Budget]
		--, Subquery.[$ Used]
		, Subquery.[$ Used] + CASE WHEN (Subquery.[$ Used] - Subquery.[$ Billed]) <= 0 THEN 0 ELSE (Subquery.[$ Used] - Subquery.[$ Billed]) END [$ Used]
		--, CASE WHEN Subquery.[$ Budget] = 0 THEN NULL ELSE Subquery.[$ Used] / Subquery.[$ Budget] END [% Used]
		, (CASE WHEN Subquery.[$ Budget] = 0 THEN NULL ELSE Subquery.[$ Used] + CASE WHEN (Subquery.[$ Used] - Subquery.[$ Billed]) <= 0 THEN 0 ELSE (Subquery.[$ Used] - Subquery.[$ Billed]) END END) / Subquery.[$ Budget] [% Used]
		, Subquery.[$ Budget] - Subquery.[$ Used] [$ Remaining]
		, CASE WHEN Subquery.[$ Budget] = 0 THEN NULL ELSE (Subquery.[$ Budget] - Subquery.[$ Used]) / Subquery.[$ Budget] END [% Remaining]
		, CASE WHEN (Subquery.[$ Used] - Subquery.[$ Billed]) <= 0 THEN NULL ELSE (Subquery.[$ Used] - Subquery.[$ Billed]) END [$ Current]
		, Subquery.[$ Billed]
		, Subquery.[$ Budget] - Subquery.[$ Billed] [$ Bill Remaining]
		, CASE WHEN Subquery.[$ Budget] = 0 THEN NULL ELSE Subquery.[$ Billed] / Subquery.[$ Budget] END [% Billed]
		, Subquery.RFP
		, Subquery.[Project Status]
		, Subquery.[Phase Status]
		, Subquery.Studio
		, Subquery.VP
		, Subquery.[Project Leader]
		, Subquery.[Project Type]
		, CASE WHEN Subquery.Project_Index = 1 THEN Subquery.[Billing Notes] ELSE '' END [Billing Notes]
FROM (
	SELECT
		   project.project_number
		  , Project.project_name Project
		  , Phase.phase_name Phase
		  , Phase.start_date [Start Date]
		  , Phase.end_date [End Date]
		  , Phase.budget_hours [Hours Allocated]
		  , Phase.clc_actual_hours [Hours Used]
		  , Phase.clc_budget_fees_fixed [$ Budget]
		  , Phase.clc_actual_fees_total [$ Used]
		  , Job_Code.[$ Current]
		  , Phase.clc_invoiced_fees_fixed [$ Billed]
		  , CASE WHEN Project.flag_rfp = 1 THEN 'RFP' ELSE NULL END [RFP]
		  , Project.status [Project Status]
		  , CASE WHEN Phase.flag_active = 1 THEN 'Active' ELSE 'Inactive' END [Phase Status]
		  , Studio.user_logon Studio
		  , PCF.field_value [VP]
		  , clc_project_leader_name [Project Leader]
		  , project.clc_project_type_name [Project Type]
		  , ISNULL(Bill.billing_note, '') [Billing Notes]
		  , ROW_NUMBER() OVER(PARTITION BY Project.project_id ORDER BY Project.project_id) Project_Index
	FROM project_phase Phase
	LEFT JOIN project Project
	ON Project.project_id = Phase.project_id
	LEFT JOIN (
		SELECT PCF.project_id
				, PCF.field_value
		FROM project_custom_field PCF
		WHERE PCF.field_value NOT IN ('Erin Fisher','Robert James') ) PCF
	ON Project.project_id = PCF.project_id
	LEFT JOIN user_table Studio
	ON Project.principle_id = Studio.user_id
	LEFT JOIN project_bill Bill
	ON Project.project_id = Bill.project_id 
	LEFT JOIN (
		SELECT Job_Code.project_id
				, SUM(Job_Code.clc_actual_fees) [$ Current]
		FROM project_job_code Job_Code
		GROUP BY Job_Code.project_id ) Job_Code
	ON Project.project_id = Job_Code.project_id
	) Subquery








GO


