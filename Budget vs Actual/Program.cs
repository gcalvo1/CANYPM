using System;
using System.IO;
using Missing_Dates;
using System.Collections.Generic;

namespace Budget_vs_Actual
{
    class Program
    {
        static void Main()
        {
            //Variable definition
            var connectionString = "Data Source=172.16.0.6;Initial Catalog=AO2017;Persist Security Info=True;User ID=sa;Password=BQ3$ervice";
            var generalFilePath = @"\\canydocs\archives\Users\BVI Reports\Team Billing Reports\";            
            List<string> teamList = new List<string>();
            teamList.Add("Team Red");
            teamList.Add("Team Blue");
            teamList.Add("Team Green");
            teamList.Add("Team Silver");
            teamList.Add("Black Team");
            teamList.Add("Team Platinum");
            teamList.Add("Team Magenta");
            teamList.Add("Team White");
            teamList.Add("Misc");

            foreach (var team in teamList)
            {
                var reportName = "BVA - " + team;
                var fileName = reportName.Replace(" ", "_") + "_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".csv";
                var filePath = generalFilePath + team + @"\" + fileName;

                var selectStatement = @"EXECUTE dbo.Budget_vs_Actual_Report '" + team + "'";
            
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
}
