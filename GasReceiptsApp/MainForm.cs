using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
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
    }
}
