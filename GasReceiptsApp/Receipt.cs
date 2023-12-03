using System;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;

namespace GasReceiptsApp
{
    public class Receipt
    {
        public int ID { get; set; }
        public DateTime PurchaseDate { get; set; }
        public float TotalCost { get; set; }
        public float NumberGallons { get; set; }
        public string Vehicle { get; set; }
        public string LicensePlate { get; set; }
        public int TaxYear { get; set; }

        private readonly string connectionString = ConfigurationManager.ConnectionStrings["GasReceiptsApp.Properties.Settings.gasreceiptsCxn"].ConnectionString;
        
        public Receipt GetReceipt(int receiptId)
        {
            var receipt = new Receipt();

            var sqlConnection = new SqlConnection(connectionString);
            sqlConnection.Open();

            var cmdText = "SELECT ID,PurchaseDate,TotalCost,NumberGallons,Receipt,Vehicle,TaxYear,LicensePlate FROM receipts where ID = " + receiptId;
            var sqlCmd = new SqlCommand(cmdText, sqlConnection);

            var sqlReader = sqlCmd.ExecuteReader();

            if (sqlReader != null)
            {
                while (sqlReader.Read()) { 
                    receipt.ID = Convert.ToInt16(sqlReader["ID"]);
                    receipt.TotalCost = float.Parse(sqlReader["TotalCost"].ToString());
                    receipt.NumberGallons = float.Parse(sqlReader["NumberGallons"].ToString());
                    receipt.LicensePlate = sqlReader["LicensePlate"].ToString();
                    receipt.TaxYear = Convert.ToUInt16(sqlReader["TaxYear"]);
                    receipt.Vehicle = sqlReader["Vehicle"].ToString();
                    receipt.PurchaseDate = Convert.ToDateTime(sqlReader["PurchaseDate"]);

                }

            }

            sqlReader.Close();
            sqlCmd.Dispose();
            sqlConnection.Close();
            sqlConnection.Dispose();

            return receipt;

        }

        public void UpdateReceipt(Receipt receipt)
        {  
            try
            {
                var sqlConnection = new SqlConnection(connectionString);
                var sqlCmd = new SqlCommand("UpdateReceipt", sqlConnection);
                sqlCmd.CommandType = CommandType.StoredProcedure;

                sqlCmd.Parameters.Add(new SqlParameter("@ReceiptId", receipt.ID));
                sqlCmd.Parameters.Add(new SqlParameter("@TotalCost", receipt.TotalCost));
                sqlCmd.Parameters.Add(new SqlParameter("@NumberGallons", receipt.NumberGallons));
                sqlCmd.Parameters.Add(new SqlParameter("@LicensePlate", receipt.LicensePlate));
                sqlCmd.Parameters.Add(new SqlParameter("@Vehicle", receipt.Vehicle));
                sqlCmd.Parameters.Add(new SqlParameter("@PurchaseDate", receipt.PurchaseDate));
                sqlCmd.Parameters.Add(new SqlParameter("@TaxYear", receipt.TaxYear));

                sqlConnection.Open();
                sqlCmd.ExecuteNonQuery();

                sqlCmd.Dispose();
                sqlConnection.Close();
                sqlConnection.Dispose();
            }
            catch (Exception ex)
            {
                throw ex;
            }           

        }
    }
}
