using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.Windows.Forms;

namespace ScriptManager
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            WriteLog(string.Empty, Severity.INFORMATION.ToString(), "Begin new session.", "LOGON");

            // TODO: This line of code loads data into the 'scriptLogsDataSet.ChangeLog' table. You can move, or remove it, as needed.
            this.changeLogTableAdapter.Fill(this.scriptLogsDataSet.ChangeLog);
            // TODO: This line of code loads data into the 'scriptLogsDataSet.ScriptConfig' table. You can move, or remove it, as needed.
            this.scriptConfigTableAdapter.Fill(this.scriptLogsDataSet.ScriptConfig);
            // TODO: This line of code loads data into the 'scriptLogsDataSet.NetworkStatus' table. You can move, or remove it, as needed.
            this.networkStatusTableAdapter.Fill(this.scriptLogsDataSet.NetworkStatus);
        }

        private void dataGridView1_RowValidated(object sender, DataGridViewCellEventArgs e)
        {
            try
            {
                Console.WriteLine("RowValidated");
                this.Validate();
                this.networkStatusBindingSource.EndEdit();
                this.networkStatusTableAdapter.Update(this.scriptLogsDataSet.NetworkStatus);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"An error occurred: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                if (this.changeLogTableAdapter.Connection.State == ConnectionState.Open)
                {
                    WriteLog("NetworkStatus", Severity.ERROR.ToString(), ex.Message);
                }
            }
        }

        private void dataGridView2_RowValidated(object sender, DataGridViewCellEventArgs e)
        {
            try
            {
                Console.WriteLine("RowValidated");
                this.Validate();
                this.scriptConfigBindingSource.EndEdit();
                this.scriptConfigTableAdapter.Update(this.scriptLogsDataSet.ScriptConfig);
            }
            catch (SqlException ex)
            {
                MessageBox.Show($"An error occurred: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                if (this.changeLogTableAdapter.Connection.State == ConnectionState.Open)
                {
                    WriteLog("ScriptConfig", Severity.ERROR.ToString(), ex.Message);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"An error occurred: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                if (this.changeLogTableAdapter.Connection.State == ConnectionState.Open)
                {
                    WriteLog("ScriptConfig", Severity.ERROR.ToString(), ex.Message);
                }
            }
        }

        private void checkBox1_CheckedChanged(object sender, EventArgs e)
        {
            List<DataGridView> dataGridViews = new List<DataGridView> { dataGridView1, dataGridView2 };

            foreach (DataGridView dataGridView in dataGridViews)
            {
                dataGridView.ReadOnly = !dataGridView.ReadOnly;
                Console.WriteLine(dataGridView.Name + " is read-only:" + dataGridView.ReadOnly);
            }
        }

        private void AutoSizeTabControl(TabControl tabControl)
        {
            int maxWidth = 0;
            int maxHeight = 0;

            foreach (TabPage tabPage in tabControl.TabPages)
            {
                foreach (Control control in tabPage.Controls)
                {
                    maxWidth = Math.Max(maxWidth, control.Right);
                    maxHeight = Math.Max(maxHeight, control.Bottom);
                    Console.WriteLine(control.Name + ":" + control.Size.ToString());
                }
            }

            // set tabControlsize
            tabControl.Width = maxWidth + tabControl.Padding.X * 2;
            tabControl.Height = maxHeight + tabControl.ItemSize.Height + tabControl.Padding.Y * 2;
            Console.WriteLine("Checkbox Height: " + this.checkBox1.Height.ToString());
            int y = this.checkBox1.Height + 5;
            int x = tabControl.Location.X;
            tabControl.Location = new Point(x, y);
            Console.WriteLine($"New tabControl Location: {{{x},{y}}}");
            Console.WriteLine(tabControl.Name + ":" + tabControl.Location.ToString());

            // update form size
            this.Width = tabControl.Width + 5;
            this.Height = tabControl.Height + 5;
            Console.WriteLine(this.Name + ":" + this.Size.ToString());
        }

        private void tabControl_SelectedIndexChanged(object sender, EventArgs e)
        {
            TabControl tabControl = (TabControl)sender;
            var selectedIndex = tabControl.SelectedIndex;

            var tabName = tabControl.TabPages[selectedIndex].Text;

            var severity = Severity.INFORMATION.ToString();
            var message = $"Accessed {tabName}";

            WriteLog(severity, message);

            AutoSizeTabControl((TabControl)sender);
        }

        private void Form1_FormClosing(object sender, FormClosingEventArgs e)
        {
            WriteLog(string.Empty, Severity.INFORMATION.ToString(), "End session.", "LOGOFF");
        }
    }
}