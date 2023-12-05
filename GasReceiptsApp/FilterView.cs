using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Windows.Forms;

namespace GasReceiptsApp
{
    public partial class FilterView : Form
    {
        private readonly string connectionString = ConfigurationManager.ConnectionStrings["GasReceiptsApp.Properties.Settings.gasreceiptsCxn"].ConnectionString;
        public FilterView()
        {
            InitializeComponent();
        }

        private void FilterView_Load(object sender, EventArgs e)
        {
            // TODO: This line of code loads data into the 'gasreceiptsDataSet.receipts' table. You can move, or remove it, as needed.
            //this.receiptsTableAdapter.Fill(this.gasreceiptsDataSet.receipts);
            FillDataTable();

            SqlSelect("SELECT DISTINCT TaxYear FROM Receipts ORDER BY 1 DESC", this.taxYearToolStripComboBox);
            SqlSelect("SELECT DISTINCT Vehicle FROM Receipts", this.vehicleToolStripComboBox);
            SqlSelect("SELECT DISTINCT LicensePlate FROM Receipts", this.licensePlateToolStripComboBox);

        }

        public void SqlSelect(string query, ToolStripComboBox comboBox)
        {
            using (var sqlConnection = new SqlConnection(connectionString))
            {
                sqlConnection.Open();

                var sqlCmd = new SqlCommand(query, sqlConnection);
                var results = sqlCmd.ExecuteReader();

                while (results.Read())
                {
                    comboBox.Items.Add(results[0]);
                }
            }

        }

        private void fillByFilteredViewToolStripButton_Click(object sender, EventArgs e)
        {
            FillDataTable();
        }

        private void FillDataTable()
        {
            using (var sqlConnection = new SqlConnection(connectionString))
            {
                sqlConnection.Open();

                var sqlCmd = new SqlCommand("FilterReceipts", sqlConnection);
                sqlCmd.CommandType = CommandType.StoredProcedure;
                sqlCmd.Parameters.Add(new SqlParameter("@LicensePlate", this.licensePlateToolStripComboBox.Text));
                sqlCmd.Parameters.Add(new SqlParameter("@Vehicle", this.vehicleToolStripComboBox.Text));
                sqlCmd.Parameters.Add(new SqlParameter("@TaxYear", this.taxYearToolStripComboBox.Text));

                var sqlAdapter = new SqlDataAdapter(sqlCmd);
                var sqlData = new DataTable();
                sqlAdapter.Fill(sqlData);

                dataGridView1.DataSource = sqlData;

                sqlCmd.CommandText = "CalculateSums";

                var sums = sqlCmd.ExecuteReader();
                while (sums.Read())
                {
                    this.lblSumCost.Text = String.Format("{0:c}",sums["SumCost"]);
                    this.lblSumGallons.Text = String.Format("{0:0.000}", sums["SumGallons"]);
                }
            }
        }

        private void rbLicensePlate_CheckedChanged(object sender, EventArgs e)
        {
            if (rbLicensePlate.Checked)
            {
                vehicleToolStripComboBox.Enabled = false;
                vehicleToolStripComboBox.Text = null;

                licensePlateToolStripComboBox.Enabled = true;
            }
            else
            {
                vehicleToolStripComboBox.Enabled = true;

                licensePlateToolStripComboBox.Enabled = false;
                licensePlateToolStripComboBox.Text = null;
            }
        }
    }
}
