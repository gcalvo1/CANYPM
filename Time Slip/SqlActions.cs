using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace Time_Slip
{
    class SqlActions
    {
        private readonly string connectionString;
        //private readonly string filePath;

        public SqlActions(string ConnectionString)
        {
            connectionString = ConnectionString;
        }

        public DataTable SelectToDataTable(string selectStatement)
        {
            var dataTable = new DataTable();

            SqlConnection conn = new SqlConnection(connectionString);
            SqlCommand cmd = new SqlCommand(selectStatement, conn);

            conn.Open();

            // create data adapter
            SqlDataAdapter da = new SqlDataAdapter(cmd);
            // this will query your database and return the result to your datatable
            da.Fill(dataTable);
            conn.Close();
            da.Dispose();

            return dataTable;
        }
    }
}
