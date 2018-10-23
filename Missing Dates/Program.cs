using System;
using System.IO;

namespace Missing_Dates
{
    class Program
    {
        static void Main()
        {
            //Variable definition
            var connectionString = "Data Source=172.16.0.6;Initial Catalog=AO2017;Persist Security Info=True;User ID=sa;Password=BQ3$ervice";
            var generalFilePath = @"\\canydocs\Archives\Users\Gcalvo\Reports\";
            var reportName = "Time Slips";
            var fileName = reportName.Replace(" ", "_") + "_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".csv";
            var filePath = generalFilePath + reportName + @"\" + fileName;

            var selectStatement = @"SELECT 
	                                    Project.project_number [Project Number]
	                                    , Project.project_name Project
	                                    , Phase.phase_name Phase
	                                    , Phase.flag_active [Flag Active]
	                                    , start_date [Start Date] 
	                                    , end_date [End Date]
	                                    , Studio.user_logon Studio
	                                    , clc_project_leader_name [Project Leader]
                                    FROM dbo.project_phase Phase
                                    LEFT JOIN project Project
                                    ON Phase.project_id = Project.project_id
                                    LEFT JOIN user_table Studio
                                    ON Project.principle_id = Studio.user_id
                                    WHERE Project.status = 'Active'
	                                    AND Phase.flag_active = 1";

            //Execution start

            //Instansiate a new SqlActions object
            var sqlActions = new SqlActions(connectionString);

            //Execute the selectStatement and store the results in a list of strings
            var dt = sqlActions.SelectToDataTable(selectStatement);

            //Create file to write to
            File.Create(filePath).Dispose();

            //Instansiate a new DataTableExtensions object
            var dataTableExtensions = new DataTableExtensions();
            //Write the data from the data table to the file
            dataTableExtensions.WriteToCsvFile(dt, filePath);
        }
    }
}
