using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

namespace GasReceiptsApp
{
    public partial class GasReceiptsForm : Form
    {
        public GasReceiptsForm()
        {
            InitializeComponent();
        }

        private void GasReceiptsForm_Load(object sender, EventArgs e)
        {
            // TODO: This line of code loads data into the 'gasreceiptsDataSet.receipts' table. You can move, or remove it, as needed.
            this.receiptsTableAdapter.Fill(this.gasreceiptsDataSet.receipts);

        }

        private void GasReceiptsForm_Activated(object sender, EventArgs e)
        {
            this.receiptsTableAdapter.Fill(this.gasreceiptsDataSet.receipts);
        }

        private void dataGridView1_CellContentClick(object sender, DataGridViewCellEventArgs e)
        {
            if (e.ColumnIndex >= 0 && e.RowIndex >= 0)
            {
                DataGridViewLinkCell linkCell = dataGridView1.Rows[e.RowIndex].Cells[e.ColumnIndex] as DataGridViewLinkCell;

                if (linkCell != null)
                {
                    Process.Start(linkCell.Value.ToString());
                }
            }
        }

        private void btnUpdate_Click(object sender, EventArgs e)
        {
            int receiptId = (int)dataGridView1.CurrentRow.Cells[0].Value;
            var editForm = new EditForm(receiptId);

            editForm.ShowDialog();
        }

        private void btnClose_Click(object sender, EventArgs e)
        {
            this.Close();
        }

        private void dataGridView1_DoubleClick(object sender, EventArgs e)
        {
            btnUpdate_Click(sender, e);
        }

        private void button1_Click(object sender, EventArgs e)
        {
            var filterForm = new FilterView();
            filterForm.ShowDialog();
        }

        private void btnUpdateDatabase_Click(object sender, EventArgs e)
        {
            MessageBox.Show("Checking for new receipts...", "Import Receipts", MessageBoxButtons.OK, MessageBoxIcon.Information);
            var path = "";
            if (Directory.Exists(@"\\mydomain\dfs\stuff")) {
                path = @"\\mydomain\dfs\Stuff\Scripts\ScheduledTasks\Import-GasReceipts.ps1";
            }
            else if (Directory.Exists(@"Z:\Scripts")) {
                path = @"Z:\Scripts\ScheduledTasks\Import-GasReceipts.ps1";
            }

            var command = $"-ExecutionPolicy Bypass -Command \"{path}\"";

            var processInfo = new ProcessStartInfo("powershell.exe", command);
            processInfo.ErrorDialog = true;
            processInfo.UseShellExecute = false;
            processInfo.CreateNoWindow = true;

            try
            {
                var process = Process.Start(processInfo);
                process.WaitForExit();


                var errorLevel = process.ExitCode;

                process.Close();
                process.Dispose();

                MessageBox.Show($"Completed with Error Code {errorLevel}");
                //return errorLevel;
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
            }
        }
    }
}
