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
        public string LinkToPdf { get; set; }

        private readonly string connectionString = ConfigurationManager.ConnectionStrings["GasReceiptsApp.Properties.Settings.gasreceiptsCxn"].ConnectionString;
        
        public Receipt GetReceipt(int receiptId)
        {
            var receipt = new Receipt();

            var sqlConnection = new SqlConnection(connectionString);
            sqlConnection.Open();

            var sqlCmd = new SqlCommand("GetReceipt", sqlConnection);
            sqlCmd.CommandType = CommandType.StoredProcedure;
            sqlCmd.Parameters.Add(new SqlParameter("@receiptId", receiptId));

            var sqlReader = sqlCmd.ExecuteReader();

            if (sqlReader != null)
            {
                while (sqlReader.Read()) { 
                    receipt.ID = Convert.ToInt16(sqlReader["ID"]);
                    if (!String.IsNullOrEmpty(sqlReader["TotalCost"].ToString()))
                        receipt.TotalCost = Convert.ToSingle(sqlReader["TotalCost"].ToString());
                    if (!String.IsNullOrEmpty(sqlReader["NumberGallons"].ToString()))
                        receipt.NumberGallons = Convert.ToSingle(sqlReader["NumberGallons"].ToString());
                    receipt.LicensePlate = sqlReader["LicensePlate"].ToString();
                    receipt.TaxYear = Convert.ToUInt16(sqlReader["TaxYear"]);
                    receipt.Vehicle = sqlReader["Vehicle"].ToString();
                    receipt.PurchaseDate = Convert.ToDateTime(sqlReader["PurchaseDate"]);
                    receipt.LinkToPdf = sqlReader["LinkToPdf"].ToString();

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
                sqlCmd.Parameters.Add(new SqlParameter("@LinkToPdf", receipt.LinkToPdf));

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
