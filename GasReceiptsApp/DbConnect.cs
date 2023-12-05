using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Windows.Forms;

namespace GasReceiptsApp
{
    public class DbConnect
    {
        public string Query { get; set; }
        
        private readonly string connectionString = ConfigurationManager.ConnectionStrings["GasReceiptsApp.Properties.Settings.gasreceiptsCxn"].ConnectionString;

        public void SqlSelect(ToolStripComboBox comboBox)
        {
            using (var sqlConnection = new SqlConnection(connectionString))
            {
                sqlConnection.Open();

                var sqlCmd = new SqlCommand(Query, sqlConnection);
                var results = sqlCmd.ExecuteReader();

                while (results.Read())
                {
                    comboBox.Items.Add(results[0]);
                }
            }

        }
    }
}
