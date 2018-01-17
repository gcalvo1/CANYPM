USE [AO2017]
GO

/****** Object:  View [dbo].[V_Phase_Correct_Calcs]    Script Date: 1/16/2018 9:10:02 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Phase_Correct_Calcs]
AS
SELECT 
	PHASEID project_phase_id
	, PROJID project_id
	, PROJTYPE project_type
	, LEADER project_leader
	, HOURSALLOC hours_alloc
	, HOURSBILLED hours_billed
	, HOURSBILLEDADD hours_billed_add
	, HOURSCURRENT hours_current
	, HOURSCURRENTADD hours_current_add
	, (HOURSALLOC - HOURSBILLED - HOURSCURRENT) AS hours_remain
	, (HOURSALLOC - (HOURSBILLED + HOURSBILLEDADD) - (HOURSCURRENT + HOURSCURRENTADD)) AS hours_remain_with_add
	, BUDGETDOLLARS budget_dollars
	, USEDDOLLARS used_dollars
	, BILLEDDOLLARS billed_dollars
	, BILLEDDOLLARSADD billed_dollars_add
	, CURRENTDOLLARS current_dollars
	, CURRENTDOLLARSADD current_dollars_add
	,CASE 
		WHEN ISNULL(BUDGETDOLLARS, 0) = 0
			THEN 0
		ELSE (BUDGETDOLLARS - BILLEDDOLLARS - CURRENTDOLLARS)
		END AS remain_dollars
	,CASE 
		WHEN ISNULL(BUDGETDOLLARS, 0) = 0
			THEN 0
		ELSE (BUDGETDOLLARS - (BILLEDDOLLARS + BILLEDDOLLARSADD) - (CURRENTDOLLARS + CURRENTDOLLARSADD))
		END AS remain_dollars_with_add
	,(
		CASE 
			WHEN BUDGETDOLLARS > 0
				THEN (BILLEDDOLLARS / BUDGETDOLLARS * 100)
			ELSE 0
			END
		) AS inv_percent
FROM (
	SELECT CONVERT(VARCHAR(100), p.project_id) AS PROJID
		,vlv.description AS PROJTYPE
		,pp.project_phase_id AS PHASEID
		,COALESCE(pp.budget_hours, 0) AS HOURSALLOC
		,Isnull(Q11.HB, 0) AS HOURSBILLED
		,ISNULL(Q12.HC, 0) AS HOURSCURRENT
		,CASE 
			WHEN COALESCE(flag_hourly_fee, 0) = 1
				THEN COALESCE(budget_fees_hourly, 0)
			ELSE COALESCE(budget_fees_fixed, 0)
			END AS BUDGETDOLLARS
		,ISNULL(Q13.UD, 0) AS USEDDOLLARS
		,ISNULL(Q14.IA, 0) AS BILLEDDOLLARS
		,isnull(Q15.ADS, 0) AS BILLEDDOLLARSADD
		,ISNULL(Q12.CD, 0) AS CURRENTDOLLARS
		,ISNULL(Q16.CDADD, 0) AS CURRENTDOLLARSADD
		,ISNULL(Q16.HCADD, 0) AS HOURSCURRENTADD
		,ISNULL(Q17.HBADD, 0) AS HOURSBILLEDADD
		,p.clc_project_leader_name AS LEADER
	FROM project_phase pp
	INNER JOIN project p ON pp.project_id = p.project_id
	LEFT JOIN value_lists_values vlv ON p.project_type_id = vlv.vl_values_id
	LEFT JOIN (
		SELECT SUM(TEHrs) AS HB
			,phase_id
		FROM (
			SELECT SUM(TE.Hours) AS TEHrs
				,Phase_ID
			FROM project_phase pp1
			INNER JOIN Time_Expense te ON pp1.project_Phase_ID = te.phase_id
			INNER JOIN project_job_code pjc ON te.job_code_id = pjc.project_job_code_id
				AND pjc.project_id = te.project_id
			WHERE te.slip_type_id = 1
				AND te.phase_id IS NOT NULL
				AND te.invoice_id IS NOT NULL
				AND te.invoice_id <> '00000000-0000-0000-0000-000000000000'
				AND pjc.flag_cap = 1
				AND te.completion_image <> '../AO_Images/slip_draft.png'
			GROUP BY Phase_ID
			
			UNION ALL
			
			SELECT SUM(TE1.Hours) AS TEHrs
				,ppid AS phase_id
			FROM time_expense te1
			INNER JOIN (
				SELECT p5.project_phase_id
					,pp2.project_phase_id AS ppid
				FROM project_phase p5
				INNER JOIN project_phase pp2 ON p5.parent_id = pp2.project_phase_id
				) PP3 ON te1.phase_id = PP3.project_phase_id
			INNER JOIN project_job_code pjc ON te1.job_code_id = pjc.project_job_code_id
				AND pjc.project_id = te1.project_id
			WHERE te1.slip_type_id = 1
				AND te1.phase_id IS NOT NULL
				AND te1.invoice_id IS NOT NULL
				AND te1.invoice_id <> '00000000-0000-0000-0000-000000000000'
				AND pjc.flag_cap = 1
				AND te1.completion_image <> '../AO_Images/slip_draft.png'
			GROUP BY ppid
			) Q1
		GROUP BY phase_id
		) Q11 ON Q11.Phase_id = pp.project_phase_id
	LEFT JOIN (
		SELECT SUM(TEHrs) AS HBADD
			,phase_id
		FROM (
			SELECT SUM(TE.Hours) AS TEHrs
				,Phase_ID
			FROM project_phase pp1
			INNER JOIN Time_Expense te ON pp1.project_Phase_ID = te.phase_id
			INNER JOIN project_job_code pjc ON te.job_code_id = pjc.project_job_code_id
				AND pjc.project_id = te.project_id
			WHERE te.slip_type_id = 1
				AND te.phase_id IS NOT NULL
				AND te.invoice_id IS NOT NULL
				AND te.invoice_id <> '00000000-0000-0000-0000-000000000000'
				AND pjc.flag_cap <> 1
				AND te.completion_image <> '../AO_Images/slip_draft.png'
			GROUP BY Phase_ID
			
			UNION ALL
			
			SELECT SUM(TE1.Hours) AS TEHrs
				,ppid AS phase_id
			FROM time_expense te1
			INNER JOIN (
				SELECT p5.project_phase_id
					,pp2.project_phase_id AS ppid
				FROM project_phase p5
				INNER JOIN project_phase pp2 ON p5.parent_id = pp2.project_phase_id
				) PP3 ON te1.phase_id = PP3.project_phase_id
			INNER JOIN project_job_code pjc ON te1.job_code_id = pjc.project_job_code_id
				AND pjc.project_id = te1.project_id
			WHERE te1.slip_type_id = 1
				AND te1.phase_id IS NOT NULL
				AND te1.invoice_id IS NOT NULL
				AND te1.invoice_id <> '00000000-0000-0000-0000-000000000000'
				AND pjc.flag_cap <> 1
				AND te1.completion_image <> '../AO_Images/slip_draft.png'
			GROUP BY ppid
			) Q1
		GROUP BY phase_id
		) Q17 ON Q17.Phase_id = pp.project_phase_id
	LEFT JOIN (
		SELECT SUm(TEtot) AS CD
			,SUM(TEHrs) AS HC
			,phase_id
		FROM (
			SELECT SUM(TE.total) AS TEtot
				,SUM(TE.Hours) AS TEHrs
				,Phase_ID
			FROM project_phase pp1
			INNER JOIN Time_Expense te ON pp1.project_Phase_ID = te.phase_id
			INNER JOIN project_job_code PJC ON te.job_code_id = PJC.project_job_code_id
			WHERE te.slip_type_id = 1
				AND PJC.flag_cap = 1
				AND te.phase_id IS NOT NULL
				AND (
					te.invoice_id IS NULL
					OR te.invoice_id = '00000000-0000-0000-0000-000000000000'
					)
			GROUP BY Phase_ID
			
			UNION ALL
			
			SELECT SUM(TE1.total) AS TEtot
				,SUM(TE1.Hours) AS TEHrs
				,ppid AS phase_id
			FROM time_expense te1
			INNER JOIN (
				SELECT p5.project_phase_id
					,pp2.project_phase_id AS ppid
				FROM project_phase p5
				INNER JOIN project_phase pp2 ON p5.parent_id = pp2.project_phase_id
				) PP3 ON te1.phase_id = PP3.project_phase_id
			INNER JOIN project_job_code PJC ON te1.job_code_id = PJC.project_job_code_id
			WHERE te1.slip_type_id = 1
				AND PJC.flag_cap = 1
				AND te1.phase_id IS NOT NULL
				AND (
					te1.invoice_id IS NULL
					OR te1.invoice_id = '00000000-0000-0000-0000-000000000000'
					)
			GROUP BY ppid
			) Q1
		GROUP BY phase_id
		) Q12 ON Q12.phase_id = pp.project_phase_id
	LEFT JOIN (
		SELECT SUm(TEtot) AS CDADD
			,SUM(TEHrs) AS HCADD
			,phase_id
		FROM (
			SELECT SUM(TE.total) AS TEtot
				,SUM(TE.Hours) AS TEHrs
				,Phase_ID
			FROM project_phase pp1
			INNER JOIN Time_Expense te ON pp1.project_Phase_ID = te.phase_id
			INNER JOIN project_job_code PJC ON te.job_code_id = PJC.project_job_code_id
			WHERE te.slip_type_id = 1
				AND PJC.flag_cap <> 1
				AND te.phase_id IS NOT NULL
				AND (
					te.invoice_id IS NULL
					OR te.invoice_id = '00000000-0000-0000-0000-000000000000'
					)
			GROUP BY Phase_ID
			
			UNION ALL
			
			SELECT SUM(TE1.total) AS TEtot
				,SUM(TE1.Hours) AS TEHrs
				,ppid AS phase_id
			FROM time_expense te1
			INNER JOIN (
				SELECT p5.project_phase_id
					,pp2.project_phase_id AS ppid
				FROM project_phase p5
				INNER JOIN project_phase pp2 ON p5.parent_id = pp2.project_phase_id
				) PP3 ON te1.phase_id = PP3.project_phase_id
			INNER JOIN project_job_code PJC ON te1.job_code_id = PJC.project_job_code_id
			WHERE te1.slip_type_id = 1
				AND PJC.flag_cap <> 1
				AND te1.phase_id IS NOT NULL
				AND (
					te1.invoice_id IS NULL
					OR te1.invoice_id = '00000000-0000-0000-0000-000000000000'
					)
			GROUP BY ppid
			) Q1
		GROUP BY phase_id
		) Q16 ON Q16.phase_id = pp.project_phase_id
	LEFT JOIN (
		SELECT SUM(TEtot) AS UD
			,phase_id
		FROM (
			SELECT SUM(TE.total) AS TEtot
				,Phase_ID
			FROM project_phase pp1
			INNER JOIN Time_Expense te ON pp1.project_Phase_ID = te.phase_id
			INNER JOIN project_job_code pjc ON pjc.project_job_code_id = te.job_code_id
			WHERE te.phase_id IS NOT NULL
				AND isnull(pjc.flag_cap, 0) = 1
				AND (
					(slip_type_id = 1)
					OR (
						slip_type_id = 2
						AND flag_reimbursable = 1
						)
					)
			GROUP BY Phase_ID
			
			UNION ALL
			
			SELECT SUM(TE1.total) AS TEtot
				,ppid AS phase_id
			FROM time_expense te1
			INNER JOIN (
				SELECT p5.project_phase_id
					,pp2.project_phase_id AS ppid
				FROM project_phase p5
				INNER JOIN project_phase pp2 ON p5.parent_id = pp2.project_phase_id
				) PP3 ON te1.phase_id = PP3.project_phase_id
			INNER JOIN project_job_code pjc ON pjc.project_job_code_id = te1.job_code_id
			WHERE te1.phase_id IS NOT NULL
				AND isnull(pjc.flag_cap, 0) = 1
				AND (
					(slip_type_id = 1)
					OR (
						slip_type_id = 2
						AND flag_reimbursable = 1
						)
					)
			GROUP BY ppid
			) Q1
		GROUP BY phase_id
		) Q13 ON Q13.phase_id = pp.project_phase_id
	LEFT JOIN (
		SELECT SUM(Iamt) AS IA
			,phase_id
		FROM (
			SELECT SUM(amount) AS IAMT
				,project_phase_id AS phase_id
			FROM (
				SELECT SUM(amount) AS amount
					,PP.project_phase_id
					,PP.parent_id
				FROM invoice_lineitems IL
				INNER JOIN project_phase PP ON il.project_phase_id = pp.project_phase_id
				WHERE ISNULL(node_has_children, 0) = 0
				GROUP BY PP.project_phase_id
					,parent_id
				
				UNION
				
				SELECT SUM(amount) AS amount
					,PP.project_phase_id
					,PP.parent_id
				FROM project_phase PP
				INNER JOIN (
					SELECT SUM(amount) AS amount
						,PP.parent_id
						,PP.project_phase_id
						,MAX(ISNULL(node_level, 0)) AS node_level
					FROM invoice_lineitems IL
					INNER JOIN project_phase PP ON il.project_phase_id = pp.project_phase_id
					WHERE ISNULL(node_has_children, 0) = 0
						AND parent_id IS NOT NULL
					GROUP BY PP.project_phase_id
						,parent_id
					) THIRD ON PP.project_phase_id = third.parent_id
				GROUP BY PP.project_phase_id
					,PP.parent_id
				
				UNION
				
				SELECT SUM(amount) AS amount
					,PP.project_phase_id
					,pp.parent_id
				FROM project_phase PP
				INNER JOIN (
					SELECT SUM(amount) AS amount
						,PP.project_phase_id
						,PP.parent_id
					FROM project_phase PP
					INNER JOIN (
						SELECT SUM(amount) AS amount
							,PP.parent_id
							,PP.project_phase_id
							,MAX(ISNULL(node_level, 0)) AS node_level
						FROM invoice_lineitems IL
						INNER JOIN project_phase PP ON il.project_phase_id = pp.project_phase_id
						WHERE ISNULL(node_has_children, 0) = 0
							AND parent_id IS NOT NULL
						GROUP BY PP.project_phase_id
							,parent_id
						) THIRD ON PP.project_phase_id = third.parent_id
					GROUP BY PP.project_phase_id
						,PP.parent_id
					) SCND ON pp.project_phase_id = SCND.parent_id
				GROUP BY PP.project_phase_id
					,pp.parent_id
				) FINAL
			GROUP BY project_phase_id
			) Q1
		GROUP BY phase_id
		) Q14 ON Q14.Phase_id = pp.project_phase_id
	LEFT JOIN (
		SELECT SUM(TEtot) AS ADS
			,phase_id
		FROM (
			SELECT SUM(TE.total) AS TEtot
				,Phase_ID
			FROM project_phase pp1
			INNER JOIN Time_Expense te ON pp1.project_Phase_ID = te.phase_id
			LEFT JOIN project_job_code pjc ON te.job_code_id = pjc.project_job_code_id
				AND pjc.project_id = te.project_id
			WHERE te.slip_type_id = 1
				AND te.charge_status_id = 1
				AND te.phase_id IS NOT NULL
				AND te.invoice_id IS NOT NULL
				AND completion_image = '../AO_Images/slip_billed.png'
				AND flag_cap = 0
			GROUP BY Phase_ID
			
			UNION ALL
			
			SELECT SUM(TE1.total) AS TEtot
				,ppid AS phase_id
			FROM time_expense te1
			INNER JOIN (
				SELECT p5.project_phase_id
					,pp2.project_phase_id AS ppid
				FROM project_phase p5
				INNER JOIN project_phase pp2 ON p5.parent_id = pp2.project_phase_id
				) PP3 ON te1.phase_id = PP3.project_phase_id
			INNER JOIN project_job_code pjc ON te1.job_code_id = pjc.project_job_code_id
				AND pjc.project_id = te1.project_id
			WHERE te1.slip_type_id = 1
				AND te1.charge_status_id = 1
				AND te1.phase_id IS NOT NULL
				AND te1.invoice_id IS NOT NULL
				AND completion_image = '../AO_Images/slip_billed.png'
				AND flag_cap = 0
			GROUP BY ppid
			) Q1
		GROUP BY phase_id
		) Q15 ON Q15.Phase_id = pp.project_phase_id
	WHERE pp.ol_client_id = pp.ol_client_id
		AND p.STATUS != 'Template'
	) BudgetVsActual
INNER JOIN project_phase ON BudgetVsActual.PHASEID = project_phase.project_phase_id
GO


