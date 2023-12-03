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
    public partial class TestForm : Form
    {
        public TestForm()
        {
            InitializeComponent();
        }

        private void receiptsBindingNavigatorSaveItem_Click(object sender, EventArgs e)
        {
            this.Validate();
            this.receiptsBindingSource.EndEdit();
            this.tableAdapterManager.UpdateAll(this.gasreceiptsDataSet);

        }

        private void TestForm_Load(object sender, EventArgs e)
        {
            // TODO: This line of code loads data into the 'gasreceiptsDataSet.receipts' table. You can move, or remove it, as needed.
            this.receiptsTableAdapter.Fill(this.gasreceiptsDataSet.receipts);

        }
    }
}
