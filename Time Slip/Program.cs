using System;
using System.IO;

namespace Time_Slip
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
            var year = 2017;

            var selectStatement = @"SELECT
                                          te.clc_display_user_name [User Name]
                                          , te.hours Hours
                                          , te.slip_date  [Slip Date]
                                          , te.charge_status_id [Charge Status ID]
                                          , te.slip_type_id [Slip Type ID]
                                          , te.clc_project_status [Project Status]
	                                      , p.flag_internal [Flag Internal]
                                    FROM dbo.Time_Expense te
                                    LEFT JOIN Project p 
                                    ON te.project_id = p.project_id
                                    WHERE YEAR(te.slip_date) = " + year;

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
            dataTableExtensions.WriteToCsvFile(dt,filePath);
        }
    }
}
