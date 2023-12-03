using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
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
        private void loadDataToolStripButton_Click(object sender, EventArgs e)
        {
            try
            {
                this.receiptsTableAdapter.LoadData();
            }
            catch (System.Exception ex)
            {
                //System.Windows.Forms.MessageBox.Show(ex.Message);
                Console.WriteLine(ex.Message);
            }

        }

        private void dataGridView1_CellContentClick(object sender, DataGridViewCellEventArgs e)
        {
            
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
    }
}
