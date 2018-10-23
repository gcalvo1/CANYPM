using System;
using System.Data;
using System.Text;

namespace Missing_Dates
{
    class DataTableExtensions
    {

        public void WriteToCsvFile(DataTable dataTable, string filePath)
        {
            StringBuilder fileContent = new StringBuilder();

            foreach (var col in dataTable.Columns)
            {
                fileContent.Append(col + ",");
            }

            fileContent.Replace(",", Environment.NewLine, fileContent.Length - 1, 1);



            foreach (DataRow dr in dataTable.Rows)
            {

                foreach (var column in dr.ItemArray)
                {
                    fileContent.Append("\"" + column + "\",");
                }

                fileContent.Replace(",", Environment.NewLine, fileContent.Length - 1, 1);
            }

            System.IO.File.WriteAllText(filePath, fileContent.ToString());

        }
    }
}
