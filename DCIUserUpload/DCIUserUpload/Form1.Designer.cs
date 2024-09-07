namespace DCIUserUpload
{
    partial class Form1
    {
        /// <summary>
        ///  Required designer variable.
        /// </summary>
        private string defaultText = "Enter one or more DoD IDs separated by commas...";
        private static bool textChanged = false;
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        ///  Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        ///  Required method for Designer support - do not modify
        ///  the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            components = new System.ComponentModel.Container();
            button1 = new Button();
            StudentRadioButton = new RadioButton();
            tableLayoutPanel1 = new TableLayoutPanel();
            InstructorRadioButton = new RadioButton();
            label1 = new Label();
            tableLayoutPanel2 = new TableLayoutPanel();
            PidRadioButton = new RadioButton();
            DodIdRadioButton = new RadioButton();
            label2 = new Label();
            textBox1 = new TextBox();
            toolTip1 = new ToolTip(components);
            studentToolTip = new ToolTip(components);
            instructorToolTip = new ToolTip(components);
            dodIdToolTip = new ToolTip(components);
            pidToolTip = new ToolTip(components);
            tableLayoutPanel1.SuspendLayout();
            tableLayoutPanel2.SuspendLayout();
            SuspendLayout();
            // 
            // button1
            // 
            button1.Anchor = AnchorStyles.Bottom;
            button1.ImageAlign = ContentAlignment.BottomCenter;
            button1.Location = new Point(86, 309);
            button1.Name = "button1";
            button1.Size = new Size(92, 23);
            button1.TabIndex = 0;
            button1.Text = "Create Users";
            button1.UseVisualStyleBackColor = true;
            button1.Click += button1_Click;
            // 
            // StudentRadioButton
            // 
            StudentRadioButton.AutoSize = true;
            StudentRadioButton.Checked = true;
            StudentRadioButton.Location = new Point(3, 31);
            StudentRadioButton.Name = "StudentRadioButton";
            StudentRadioButton.Size = new Size(66, 19);
            StudentRadioButton.TabIndex = 1;
            StudentRadioButton.TabStop = true;
            StudentRadioButton.Text = "Student";
            StudentRadioButton.UseVisualStyleBackColor = true;
            StudentRadioButton.MouseHover += StudentRadioButton_MouseHover;
            // 
            // tableLayoutPanel1
            // 
            tableLayoutPanel1.ColumnCount = 1;
            tableLayoutPanel1.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 50F));
            tableLayoutPanel1.Controls.Add(InstructorRadioButton, 0, 2);
            tableLayoutPanel1.Controls.Add(StudentRadioButton, 0, 1);
            tableLayoutPanel1.Controls.Add(label1, 0, 0);
            tableLayoutPanel1.Location = new Point(12, 12);
            tableLayoutPanel1.Name = "tableLayoutPanel1";
            tableLayoutPanel1.RowCount = 3;
            tableLayoutPanel1.RowStyles.Add(new RowStyle(SizeType.Percent, 50F));
            tableLayoutPanel1.RowStyles.Add(new RowStyle(SizeType.Percent, 50F));
            tableLayoutPanel1.RowStyles.Add(new RowStyle(SizeType.Absolute, 26F));
            tableLayoutPanel1.Size = new Size(90, 83);
            tableLayoutPanel1.TabIndex = 2;
            tableLayoutPanel1.Paint += tableLayoutPanel1_Paint;
            // 
            // InstructorRadioButton
            // 
            InstructorRadioButton.AutoSize = true;
            InstructorRadioButton.Location = new Point(3, 59);
            InstructorRadioButton.Name = "InstructorRadioButton";
            InstructorRadioButton.Size = new Size(76, 19);
            InstructorRadioButton.TabIndex = 2;
            InstructorRadioButton.Text = "Instructor";
            InstructorRadioButton.UseVisualStyleBackColor = true;
            InstructorRadioButton.MouseHover += InstructorRadioButton_MouseHover;
            // 
            // label1
            // 
            label1.Anchor = AnchorStyles.Bottom | AnchorStyles.Left;
            label1.AutoSize = true;
            label1.Font = new Font("Segoe UI", 14F, FontStyle.Bold);
            label1.Location = new Point(3, 3);
            label1.Name = "label1";
            label1.Size = new Size(51, 25);
            label1.TabIndex = 3;
            label1.Text = "Role";
            label1.Click += label1_Click;
            // 
            // tableLayoutPanel2
            // 
            tableLayoutPanel2.ColumnCount = 1;
            tableLayoutPanel2.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 50F));
            tableLayoutPanel2.Controls.Add(PidRadioButton, 0, 2);
            tableLayoutPanel2.Controls.Add(DodIdRadioButton, 0, 1);
            tableLayoutPanel2.Controls.Add(label2, 0, 0);
            tableLayoutPanel2.Location = new Point(161, 12);
            tableLayoutPanel2.Name = "tableLayoutPanel2";
            tableLayoutPanel2.RowCount = 3;
            tableLayoutPanel2.RowStyles.Add(new RowStyle(SizeType.Percent, 50F));
            tableLayoutPanel2.RowStyles.Add(new RowStyle(SizeType.Percent, 50F));
            tableLayoutPanel2.RowStyles.Add(new RowStyle(SizeType.Absolute, 26F));
            tableLayoutPanel2.Size = new Size(90, 83);
            tableLayoutPanel2.TabIndex = 2;
            tableLayoutPanel2.Paint += tableLayoutPanel1_Paint;
            // 
            // PidRadioButton
            // 
            PidRadioButton.AutoSize = true;
            PidRadioButton.Location = new Point(3, 59);
            PidRadioButton.Name = "PidRadioButton";
            PidRadioButton.Size = new Size(43, 19);
            PidRadioButton.TabIndex = 2;
            PidRadioButton.Text = "PID";
            PidRadioButton.UseVisualStyleBackColor = true;
            PidRadioButton.Click += PidRadiobutton_Click;
            PidRadioButton.MouseHover += PidRadioButton_MouseHover;
            // 
            // DodIdRadioButton
            // 
            DodIdRadioButton.AutoSize = true;
            DodIdRadioButton.Checked = true;
            DodIdRadioButton.Location = new Point(3, 31);
            DodIdRadioButton.Name = "DodIdRadioButton";
            DodIdRadioButton.Size = new Size(62, 19);
            DodIdRadioButton.TabIndex = 1;
            DodIdRadioButton.TabStop = true;
            DodIdRadioButton.Text = "DoD ID";
            DodIdRadioButton.UseVisualStyleBackColor = true;
            DodIdRadioButton.Click += DodIdRadiobutton_Click;
            DodIdRadioButton.MouseHover += DoDIdRadioButton_MouseHover;
            // 
            // label2
            // 
            label2.Anchor = AnchorStyles.Bottom | AnchorStyles.Left;
            label2.AutoSize = true;
            label2.Font = new Font("Segoe UI", 14F, FontStyle.Bold);
            label2.Location = new Point(3, 3);
            label2.Name = "label2";
            label2.Size = new Size(79, 25);
            label2.TabIndex = 3;
            label2.Text = "ID Type";
            label2.Click += label1_Click;
            // 
            // textBox1
            // 
            textBox1.Anchor = AnchorStyles.Top | AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right;
            textBox1.Location = new Point(12, 101);
            textBox1.Multiline = true;
            textBox1.Name = "textBox1";
            textBox1.Text = defaultText;
            textBox1.ScrollBars = ScrollBars.Vertical;
            textBox1.Size = new Size(239, 202);
            textBox1.TabIndex = 3;
            textBox1.Click += textBox1_Click;
            textBox1.KeyPress += textBox1_KeyPress;
            textBox1.MouseHover += textBox1_MouseHover;
            // 
            // toolTip1
            // 
            toolTip1.ToolTipIcon = ToolTipIcon.Info;
            // 
            // Form1
            // 
            AutoScaleDimensions = new SizeF(7F, 15F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(265, 344);
            Controls.Add(textBox1);
            Controls.Add(tableLayoutPanel2);
            Controls.Add(tableLayoutPanel1);
            Controls.Add(button1);
            MinimumSize = new Size(260, 380);
            Name = "Form1";
            StartPosition = FormStartPosition.CenterScreen;
            Text = "Create Upload CSV";
            Load += Form1_Load;
            tableLayoutPanel1.ResumeLayout(false);
            tableLayoutPanel1.PerformLayout();
            tableLayoutPanel2.ResumeLayout(false);
            tableLayoutPanel2.PerformLayout();
            ResumeLayout(false);
            PerformLayout();
        }

        #endregion

        private Button button1;
        private RadioButton StudentRadioButton;
        private TableLayoutPanel tableLayoutPanel1;
        private RadioButton InstructorRadioButton;
        private Label label1;
        private TableLayoutPanel tableLayoutPanel2;
        private RadioButton PidRadioButton;
        private RadioButton DodIdRadioButton;
        private Label label2;
        private TextBox textBox1;
        private ToolTip toolTip1;
        private ToolTip studentToolTip;
        private ToolTip instructorToolTip;
        private ToolTip dodIdToolTip;
        private ToolTip pidToolTip;
    }
}
