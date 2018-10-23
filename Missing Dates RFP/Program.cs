using System;
using System.IO;
using Missing_Dates;

namespace Missing_Dates_RFP
{
    class Program
    {
        static void Main(string[] args)
        {
            //Variable definition
            var connectionString = "Data Source=172.16.0.6;Initial Catalog=AO2017;Persist Security Info=True;User ID=sa;Password=BQ3$ervice";
            var generalFilePath = @"\\canydocs\archives\Users\Missing Dates Report\";
            var reportName = "RFP";
            var fileName = reportName.Replace(" ", "_") + "_" + DateTime.Now.ToString("yyyyMMdd_HHmmss") + ".csv";
            var filePath = generalFilePath + reportName + @"\" + fileName;

            var selectStatement = @"EXECUTE dbo.Missing_Dates_RFP_Report";

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
