using System.Diagnostics;
using System.IO;
using System.Management.Automation;
using System.Collections.ObjectModel;
using System.Collections;
using System.Configuration;

namespace DCIUserUpload
{
    public partial class Form1 : Form
    {
        private bool isProgrammaticChange = false;

        public Form1()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {

        }

        private void radioButton1_CheckedChanged(object sender, EventArgs e)
        {

        }

        private void tableLayoutPanel1_Paint(object sender, PaintEventArgs e)
        {

        }

        private void label1_Click(object sender, EventArgs e)
        {

        }

        private void button1_Click(object sender, EventArgs e)
        {
            if (textBox1.Text == null || textChanged == false) return;
            //string[] ids = textBox1.Text.Split(',', ' ');
            List<string> ids = new List<string>();
            ids.AddRange(textBox1.Text.Split(new string[] { ",", " ", "\r\n" }, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries));

            var idType = DodIdRadioButton.Checked ? "-UserDoDId" : PidRadioButton.Checked ? "-UserPID" : null;
            var formattedIds = $"@( {string.Join(",", ids.Select(id => $"'{id}'"))})";

            using (PowerShell PowerShellInstance = PowerShell.Create())
            {
                if (StudentRadioButton.Checked)
                {
                    var scriptPath = ConfigurationManager.AppSettings["StudentScriptPath"];
                    PowerShellInstance.AddScript($"Set-ExecutionPolicy Bypass -Scope Process; . '{scriptPath}' {idType} {formattedIds}");
                }
                else if (InstructorRadioButton.Checked)
                {
                    var scriptPath = ConfigurationManager.AppSettings["InstructorScriptPath"];
                    PowerShellInstance.AddScript($"Set-ExecutionPolicy Bypass -Scope Process; . '{scriptPath}' {idType} {formattedIds}");
                }

                PowerShellInstance.Invoke();

                if (!PowerShellInstance.HadErrors) { textBox1.Text = defaultText; }
            }
        }

        private void textBox1_Click(object sender, EventArgs e)
        {
            if (!textChanged)
            {
                textBox1.Clear();
                isProgrammaticChange = true;
            }
        }

        private void textBox1_KeyPress(object sender, KeyPressEventArgs e)
        {
            isProgrammaticChange = false;
            textChanged = true;
        }

        private void textBox1_TextChanged(object sender, EventArgs e)
        {
            if (!string.IsNullOrWhiteSpace(textBox1.Text) && !isProgrammaticChange) { textChanged = true; }
            else { textChanged = false; }
        }

        private void DodIdRadiobutton_Click(object sender, EventArgs e)
        {
            defaultText = "Enter one or more DoD IDs separated by commas...";
            toolTip1.SetToolTip(textBox1, defaultText);
            if (!textChanged || string.IsNullOrWhiteSpace(textBox1.Text)) { textBox1.Text = defaultText; }
            isProgrammaticChange = true;
        }

        private void PidRadiobutton_Click(object sender, EventArgs e)
        {
            defaultText = "Enter one or more PIDs separated by commas...";
            toolTip1.SetToolTip(textBox1, defaultText);
            if (!textChanged || string.IsNullOrWhiteSpace(textBox1.Text)) { textBox1.Text = defaultText; }
            isProgrammaticChange = true;
        }

        private void textBox1_MouseHover(object sender, EventArgs e)
        {
            toolTip1.SetToolTip(textBox1, defaultText);
        }

        private void StudentRadioButton_MouseHover(object sender, EventArgs e)
        {
            studentToolTip.SetToolTip(StudentRadioButton, "Create CSVs for Students");
        }

        private void InstructorRadioButton_MouseHover(Object sender, EventArgs e)
        {
            instructorToolTip.SetToolTip(InstructorRadioButton, "Create CSVs for Instructors");
        }

        private void DoDIdRadioButton_MouseHover(Object sender, EventArgs e)
        {
            dodIdToolTip.SetToolTip(DodIdRadioButton, "Enter one or more DoD IDs");
        }

        private void PidRadioButton_MouseHover(Object sender, EventArgs e)
        {
            pidToolTip.SetToolTip(PidRadioButton, "Enter one or more PIDs");
        }
    }
}
