using NetworkStatusManager.Properties;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.ComponentModel.Design;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using static Azure.Core.HttpHeader;
using static System.Windows.Forms.VisualStyles.VisualStyleElement.Rebar;

namespace NetworkStatusManager
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void bindingSource1_CurrentChanged(object sender, EventArgs e)
        {

        }

        private void dataGridView1_CellContentClick(object sender, DataGridViewCellEventArgs e)
        {

        }

        private void Form1_Load(object sender, EventArgs e)
        {
            // TODO: This line of code loads data into the 'scriptLogsDataSet.NetworkStatus' table. You can move, or remove it, as needed.
            this.networkStatusTableAdapter.Fill(this.scriptLogsDataSet.NetworkStatus);

        }

        private void button1_Click(object sender, EventArgs e)
        {
            UpdateData();
        }

        private void dataGridView1_RowValidated(object sender, DataGridViewCellEventArgs e)
        {
            UpdateData();
        }

        private void UpdateData()
        {
            try
            {
                // End editing on the BindingSource
                this.Validate();
                this.bindingSource1.EndEdit();

                // Update the database using the TableAdapter
                this.networkStatusTableAdapter.Update(this.scriptLogsDataSet.NetworkStatus);

                MessageBox.Show("Changes saved successfully!", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"An error occurred: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}
