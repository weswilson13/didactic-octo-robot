namespace GasReceiptsApp
{
    partial class FilterView
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
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
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.components = new System.ComponentModel.Container();
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle13 = new System.Windows.Forms.DataGridViewCellStyle();
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle14 = new System.Windows.Forms.DataGridViewCellStyle();
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle15 = new System.Windows.Forms.DataGridViewCellStyle();
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle16 = new System.Windows.Forms.DataGridViewCellStyle();
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(FilterView));
            this.rbVehicle = new System.Windows.Forms.RadioButton();
            this.rbLicensePlate = new System.Windows.Forms.RadioButton();
            this.lblAverage = new System.Windows.Forms.Label();
            this.lblAverages = new System.Windows.Forms.Label();
            this.lblTotal = new System.Windows.Forms.Label();
            this.lblTotals = new System.Windows.Forms.Label();
            this.dataGridView1 = new System.Windows.Forms.DataGridView();
            this.iDDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.purchaseDateDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.totalCostDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.numberGallonsDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.vehicleDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.taxYearDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.licensePlateDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.receiptAttachedDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.linkToPdfDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.receiptsBindingSource = new System.Windows.Forms.BindingSource(this.components);
            this.gasreceiptsDataSet = new GasReceiptsApp.gasreceiptsDataSet();
            this.fillByFilteredViewToolStrip = new System.Windows.Forms.ToolStrip();
            this.taxYearToolStripLabel = new System.Windows.Forms.ToolStripLabel();
            this.taxYearToolStripComboBox = new System.Windows.Forms.ToolStripComboBox();
            this.vehicleToolStripLabel = new System.Windows.Forms.ToolStripLabel();
            this.vehicleToolStripComboBox = new System.Windows.Forms.ToolStripComboBox();
            this.licensePlateToolStripLabel = new System.Windows.Forms.ToolStripLabel();
            this.licensePlateToolStripComboBox = new System.Windows.Forms.ToolStripComboBox();
            this.toolStripSeparator1 = new System.Windows.Forms.ToolStripSeparator();
            this.fillByFilteredViewToolStripButton = new System.Windows.Forms.ToolStripButton();
            this.receiptsTableAdapter = new GasReceiptsApp.gasreceiptsDataSetTableAdapters.receiptsTableAdapter();
            this.btnClose = new System.Windows.Forms.Button();
            ((System.ComponentModel.ISupportInitialize)(this.dataGridView1)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.receiptsBindingSource)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.gasreceiptsDataSet)).BeginInit();
            this.fillByFilteredViewToolStrip.SuspendLayout();
            this.SuspendLayout();
            // 
            // rbVehicle
            // 
            this.rbVehicle.AutoSize = true;
            this.rbVehicle.Checked = true;
            this.rbVehicle.Location = new System.Drawing.Point(12, 28);
            this.rbVehicle.Name = "rbVehicle";
            this.rbVehicle.Size = new System.Drawing.Size(60, 17);
            this.rbVehicle.TabIndex = 2;
            this.rbVehicle.TabStop = true;
            this.rbVehicle.Text = "Vehicle";
            this.rbVehicle.UseVisualStyleBackColor = true;
            // 
            // rbLicensePlate
            // 
            this.rbLicensePlate.AutoSize = true;
            this.rbLicensePlate.Location = new System.Drawing.Point(78, 28);
            this.rbLicensePlate.Name = "rbLicensePlate";
            this.rbLicensePlate.Size = new System.Drawing.Size(89, 17);
            this.rbLicensePlate.TabIndex = 2;
            this.rbLicensePlate.Text = "License Plate";
            this.rbLicensePlate.UseVisualStyleBackColor = true;
            this.rbLicensePlate.CheckedChanged += new System.EventHandler(this.rbLicensePlate_CheckedChanged);
            // 
            // lblAverage
            // 
            this.lblAverage.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.lblAverage.AutoSize = true;
            this.lblAverage.Font = new System.Drawing.Font("Microsoft Sans Serif", 11.25F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblAverage.Location = new System.Drawing.Point(684, 28);
            this.lblAverage.Name = "lblAverage";
            this.lblAverage.Size = new System.Drawing.Size(78, 18);
            this.lblAverage.TabIndex = 3;
            this.lblAverage.Text = "Average: ";
            // 
            // lblAverages
            // 
            this.lblAverages.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.lblAverages.AutoSize = true;
            this.lblAverages.Font = new System.Drawing.Font("Microsoft Sans Serif", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblAverages.ForeColor = System.Drawing.Color.Black;
            this.lblAverages.Location = new System.Drawing.Point(700, 49);
            this.lblAverages.Name = "lblAverages";
            this.lblAverages.Size = new System.Drawing.Size(46, 18);
            this.lblAverages.TabIndex = 3;
            this.lblAverages.Text = "TEST";
            // 
            // lblTotal
            // 
            this.lblTotal.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.lblTotal.AutoSize = true;
            this.lblTotal.Font = new System.Drawing.Font("Microsoft Sans Serif", 11.25F, ((System.Drawing.FontStyle)((System.Drawing.FontStyle.Bold | System.Drawing.FontStyle.Underline))), System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblTotal.Location = new System.Drawing.Point(830, 28);
            this.lblTotal.Name = "lblTotal";
            this.lblTotal.Size = new System.Drawing.Size(51, 18);
            this.lblTotal.TabIndex = 3;
            this.lblTotal.Text = "Total:";
            // 
            // lblTotals
            // 
            this.lblTotals.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.lblTotals.AutoSize = true;
            this.lblTotals.Font = new System.Drawing.Font("Microsoft Sans Serif", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblTotals.ForeColor = System.Drawing.Color.Black;
            this.lblTotals.Location = new System.Drawing.Point(832, 49);
            this.lblTotals.Name = "lblTotals";
            this.lblTotals.Size = new System.Drawing.Size(46, 18);
            this.lblTotals.TabIndex = 3;
            this.lblTotals.Text = "TEST";
            // 
            // dataGridView1
            // 
            this.dataGridView1.AllowUserToAddRows = false;
            this.dataGridView1.AllowUserToDeleteRows = false;
            this.dataGridView1.AllowUserToOrderColumns = true;
            dataGridViewCellStyle13.BackColor = System.Drawing.Color.Azure;
            dataGridViewCellStyle13.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(0)))), ((int)(((byte)(64)))));
            this.dataGridView1.AlternatingRowsDefaultCellStyle = dataGridViewCellStyle13;
            this.dataGridView1.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.dataGridView1.AutoGenerateColumns = false;
            this.dataGridView1.BackgroundColor = System.Drawing.Color.WhiteSmoke;
            this.dataGridView1.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.dataGridView1.CellBorderStyle = System.Windows.Forms.DataGridViewCellBorderStyle.SingleVertical;
            dataGridViewCellStyle14.Alignment = System.Windows.Forms.DataGridViewContentAlignment.MiddleLeft;
            dataGridViewCellStyle14.BackColor = System.Drawing.Color.MidnightBlue;
            dataGridViewCellStyle14.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            dataGridViewCellStyle14.ForeColor = System.Drawing.Color.WhiteSmoke;
            dataGridViewCellStyle14.SelectionBackColor = System.Drawing.SystemColors.Highlight;
            dataGridViewCellStyle14.SelectionForeColor = System.Drawing.SystemColors.HighlightText;
            dataGridViewCellStyle14.WrapMode = System.Windows.Forms.DataGridViewTriState.True;
            this.dataGridView1.ColumnHeadersDefaultCellStyle = dataGridViewCellStyle14;
            this.dataGridView1.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.dataGridView1.Columns.AddRange(new System.Windows.Forms.DataGridViewColumn[] {
            this.iDDataGridViewTextBoxColumn,
            this.purchaseDateDataGridViewTextBoxColumn,
            this.totalCostDataGridViewTextBoxColumn,
            this.numberGallonsDataGridViewTextBoxColumn,
            this.vehicleDataGridViewTextBoxColumn,
            this.taxYearDataGridViewTextBoxColumn,
            this.licensePlateDataGridViewTextBoxColumn,
            this.receiptAttachedDataGridViewTextBoxColumn,
            this.linkToPdfDataGridViewTextBoxColumn});
            this.dataGridView1.DataSource = this.receiptsBindingSource;
            this.dataGridView1.Location = new System.Drawing.Point(10, 87);
            this.dataGridView1.Name = "dataGridView1";
            this.dataGridView1.ReadOnly = true;
            this.dataGridView1.Size = new System.Drawing.Size(953, 403);
            this.dataGridView1.TabIndex = 4;
            this.dataGridView1.DoubleClick += new System.EventHandler(this.dataGridView1_DoubleClick);
            // 
            // iDDataGridViewTextBoxColumn
            // 
            this.iDDataGridViewTextBoxColumn.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.DisplayedCells;
            this.iDDataGridViewTextBoxColumn.DataPropertyName = "ID";
            this.iDDataGridViewTextBoxColumn.HeaderText = "ID";
            this.iDDataGridViewTextBoxColumn.Name = "iDDataGridViewTextBoxColumn";
            this.iDDataGridViewTextBoxColumn.ReadOnly = true;
            this.iDDataGridViewTextBoxColumn.Width = 43;
            // 
            // purchaseDateDataGridViewTextBoxColumn
            // 
            this.purchaseDateDataGridViewTextBoxColumn.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.DisplayedCells;
            this.purchaseDateDataGridViewTextBoxColumn.DataPropertyName = "PurchaseDate";
            this.purchaseDateDataGridViewTextBoxColumn.HeaderText = "PurchaseDate";
            this.purchaseDateDataGridViewTextBoxColumn.Name = "purchaseDateDataGridViewTextBoxColumn";
            this.purchaseDateDataGridViewTextBoxColumn.ReadOnly = true;
            // 
            // totalCostDataGridViewTextBoxColumn
            // 
            this.totalCostDataGridViewTextBoxColumn.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.DisplayedCells;
            this.totalCostDataGridViewTextBoxColumn.DataPropertyName = "TotalCost";
            dataGridViewCellStyle15.Format = "C2";
            dataGridViewCellStyle15.NullValue = null;
            this.totalCostDataGridViewTextBoxColumn.DefaultCellStyle = dataGridViewCellStyle15;
            this.totalCostDataGridViewTextBoxColumn.HeaderText = "TotalCost";
            this.totalCostDataGridViewTextBoxColumn.Name = "totalCostDataGridViewTextBoxColumn";
            this.totalCostDataGridViewTextBoxColumn.ReadOnly = true;
            this.totalCostDataGridViewTextBoxColumn.Width = 77;
            // 
            // numberGallonsDataGridViewTextBoxColumn
            // 
            this.numberGallonsDataGridViewTextBoxColumn.DataPropertyName = "NumberGallons";
            dataGridViewCellStyle16.Format = "N3";
            dataGridViewCellStyle16.NullValue = null;
            this.numberGallonsDataGridViewTextBoxColumn.DefaultCellStyle = dataGridViewCellStyle16;
            this.numberGallonsDataGridViewTextBoxColumn.HeaderText = "NumberGallons";
            this.numberGallonsDataGridViewTextBoxColumn.Name = "numberGallonsDataGridViewTextBoxColumn";
            this.numberGallonsDataGridViewTextBoxColumn.ReadOnly = true;
            // 
            // vehicleDataGridViewTextBoxColumn
            // 
            this.vehicleDataGridViewTextBoxColumn.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.DisplayedCells;
            this.vehicleDataGridViewTextBoxColumn.DataPropertyName = "Vehicle";
            this.vehicleDataGridViewTextBoxColumn.HeaderText = "Vehicle";
            this.vehicleDataGridViewTextBoxColumn.Name = "vehicleDataGridViewTextBoxColumn";
            this.vehicleDataGridViewTextBoxColumn.ReadOnly = true;
            this.vehicleDataGridViewTextBoxColumn.Width = 67;
            // 
            // taxYearDataGridViewTextBoxColumn
            // 
            this.taxYearDataGridViewTextBoxColumn.DataPropertyName = "TaxYear";
            this.taxYearDataGridViewTextBoxColumn.HeaderText = "TaxYear";
            this.taxYearDataGridViewTextBoxColumn.Name = "taxYearDataGridViewTextBoxColumn";
            this.taxYearDataGridViewTextBoxColumn.ReadOnly = true;
            // 
            // licensePlateDataGridViewTextBoxColumn
            // 
            this.licensePlateDataGridViewTextBoxColumn.DataPropertyName = "LicensePlate";
            this.licensePlateDataGridViewTextBoxColumn.HeaderText = "LicensePlate";
            this.licensePlateDataGridViewTextBoxColumn.Name = "licensePlateDataGridViewTextBoxColumn";
            this.licensePlateDataGridViewTextBoxColumn.ReadOnly = true;
            // 
            // receiptAttachedDataGridViewTextBoxColumn
            // 
            this.receiptAttachedDataGridViewTextBoxColumn.DataPropertyName = "ReceiptAttached";
            this.receiptAttachedDataGridViewTextBoxColumn.HeaderText = "ReceiptAttached";
            this.receiptAttachedDataGridViewTextBoxColumn.Name = "receiptAttachedDataGridViewTextBoxColumn";
            this.receiptAttachedDataGridViewTextBoxColumn.ReadOnly = true;
            // 
            // linkToPdfDataGridViewTextBoxColumn
            // 
            this.linkToPdfDataGridViewTextBoxColumn.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.DisplayedCells;
            this.linkToPdfDataGridViewTextBoxColumn.DataPropertyName = "LinkToPdf";
            this.linkToPdfDataGridViewTextBoxColumn.HeaderText = "LinkToPdf";
            this.linkToPdfDataGridViewTextBoxColumn.Name = "linkToPdfDataGridViewTextBoxColumn";
            this.linkToPdfDataGridViewTextBoxColumn.ReadOnly = true;
            this.linkToPdfDataGridViewTextBoxColumn.Width = 81;
            // 
            // receiptsBindingSource
            // 
            this.receiptsBindingSource.DataMember = "receipts";
            this.receiptsBindingSource.DataSource = this.gasreceiptsDataSet;
            // 
            // gasreceiptsDataSet
            // 
            this.gasreceiptsDataSet.DataSetName = "gasreceiptsDataSet";
            this.gasreceiptsDataSet.SchemaSerializationMode = System.Data.SchemaSerializationMode.IncludeSchema;
            // 
            // fillByFilteredViewToolStrip
            // 
            this.fillByFilteredViewToolStrip.BackColor = System.Drawing.Color.WhiteSmoke;
            this.fillByFilteredViewToolStrip.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.taxYearToolStripLabel,
            this.taxYearToolStripComboBox,
            this.vehicleToolStripLabel,
            this.vehicleToolStripComboBox,
            this.licensePlateToolStripLabel,
            this.licensePlateToolStripComboBox,
            this.toolStripSeparator1,
            this.fillByFilteredViewToolStripButton});
            this.fillByFilteredViewToolStrip.Location = new System.Drawing.Point(0, 0);
            this.fillByFilteredViewToolStrip.Name = "fillByFilteredViewToolStrip";
            this.fillByFilteredViewToolStrip.Size = new System.Drawing.Size(1023, 28);
            this.fillByFilteredViewToolStrip.TabIndex = 5;
            this.fillByFilteredViewToolStrip.Text = "fillByFilteredViewToolStrip";
            // 
            // taxYearToolStripLabel
            // 
            this.taxYearToolStripLabel.Name = "taxYearToolStripLabel";
            this.taxYearToolStripLabel.Size = new System.Drawing.Size(49, 25);
            this.taxYearToolStripLabel.Text = "TaxYear:";
            // 
            // taxYearToolStripComboBox
            // 
            this.taxYearToolStripComboBox.BackColor = System.Drawing.Color.LightGray;
            this.taxYearToolStripComboBox.ForeColor = System.Drawing.SystemColors.WindowText;
            this.taxYearToolStripComboBox.Name = "taxYearToolStripComboBox";
            this.taxYearToolStripComboBox.Size = new System.Drawing.Size(100, 28);
            this.taxYearToolStripComboBox.Click += new System.EventHandler(this.taxYearToolStripComboBox_Click);
            // 
            // vehicleToolStripLabel
            // 
            this.vehicleToolStripLabel.Name = "vehicleToolStripLabel";
            this.vehicleToolStripLabel.Size = new System.Drawing.Size(47, 25);
            this.vehicleToolStripLabel.Text = "Vehicle:";
            // 
            // vehicleToolStripComboBox
            // 
            this.vehicleToolStripComboBox.BackColor = System.Drawing.Color.LightGray;
            this.vehicleToolStripComboBox.DropDownWidth = 100;
            this.vehicleToolStripComboBox.ForeColor = System.Drawing.SystemColors.MenuHighlight;
            this.vehicleToolStripComboBox.Name = "vehicleToolStripComboBox";
            this.vehicleToolStripComboBox.Size = new System.Drawing.Size(150, 28);
            // 
            // licensePlateToolStripLabel
            // 
            this.licensePlateToolStripLabel.Name = "licensePlateToolStripLabel";
            this.licensePlateToolStripLabel.Size = new System.Drawing.Size(75, 25);
            this.licensePlateToolStripLabel.Text = "LicensePlate:";
            // 
            // licensePlateToolStripComboBox
            // 
            this.licensePlateToolStripComboBox.BackColor = System.Drawing.Color.LightGray;
            this.licensePlateToolStripComboBox.Enabled = false;
            this.licensePlateToolStripComboBox.Name = "licensePlateToolStripComboBox";
            this.licensePlateToolStripComboBox.Size = new System.Drawing.Size(100, 28);
            // 
            // toolStripSeparator1
            // 
            this.toolStripSeparator1.Name = "toolStripSeparator1";
            this.toolStripSeparator1.Size = new System.Drawing.Size(6, 28);
            // 
            // fillByFilteredViewToolStripButton
            // 
            this.fillByFilteredViewToolStripButton.Alignment = System.Windows.Forms.ToolStripItemAlignment.Right;
            this.fillByFilteredViewToolStripButton.BackColor = System.Drawing.Color.White;
            this.fillByFilteredViewToolStripButton.Font = new System.Drawing.Font("Segoe UI Semibold", 12F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.fillByFilteredViewToolStripButton.ForeColor = System.Drawing.Color.Green;
            this.fillByFilteredViewToolStripButton.Image = ((System.Drawing.Image)(resources.GetObject("fillByFilteredViewToolStripButton.Image")));
            this.fillByFilteredViewToolStripButton.ImageTransparentColor = System.Drawing.Color.Magenta;
            this.fillByFilteredViewToolStripButton.Name = "fillByFilteredViewToolStripButton";
            this.fillByFilteredViewToolStripButton.Size = new System.Drawing.Size(84, 25);
            this.fillByFilteredViewToolStripButton.Text = "Update";
            this.fillByFilteredViewToolStripButton.Click += new System.EventHandler(this.fillByFilteredViewToolStripButton_Click);
            // 
            // receiptsTableAdapter
            // 
            this.receiptsTableAdapter.ClearBeforeFill = true;
            // 
            // btnClose
            // 
            this.btnClose.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
            this.btnClose.Location = new System.Drawing.Point(890, 505);
            this.btnClose.Name = "btnClose";
            this.btnClose.Size = new System.Drawing.Size(73, 28);
            this.btnClose.TabIndex = 6;
            this.btnClose.Text = "Close";
            this.btnClose.UseVisualStyleBackColor = true;
            this.btnClose.Click += new System.EventHandler(this.btnClose_Click);
            // 
            // FilterView
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.AutoSizeMode = System.Windows.Forms.AutoSizeMode.GrowAndShrink;
            this.ClientSize = new System.Drawing.Size(1023, 545);
            this.Controls.Add(this.btnClose);
            this.Controls.Add(this.fillByFilteredViewToolStrip);
            this.Controls.Add(this.dataGridView1);
            this.Controls.Add(this.lblTotals);
            this.Controls.Add(this.lblAverages);
            this.Controls.Add(this.lblTotal);
            this.Controls.Add(this.lblAverage);
            this.Controls.Add(this.rbLicensePlate);
            this.Controls.Add(this.rbVehicle);
            this.MinimumSize = new System.Drawing.Size(646, 571);
            this.Name = "FilterView";
            this.Text = "FilterView";
            this.Load += new System.EventHandler(this.FilterView_Load);
            ((System.ComponentModel.ISupportInitialize)(this.dataGridView1)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.receiptsBindingSource)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.gasreceiptsDataSet)).EndInit();
            this.fillByFilteredViewToolStrip.ResumeLayout(false);
            this.fillByFilteredViewToolStrip.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion
        private System.Windows.Forms.RadioButton rbVehicle;
        private System.Windows.Forms.RadioButton rbLicensePlate;
        private System.Windows.Forms.Label lblAverage;
        private System.Windows.Forms.Label lblAverages;
        private System.Windows.Forms.Label lblTotal;
        private System.Windows.Forms.Label lblTotals;
        private System.Windows.Forms.DataGridView dataGridView1;
        private gasreceiptsDataSet gasreceiptsDataSet;
        private System.Windows.Forms.BindingSource receiptsBindingSource;
        private gasreceiptsDataSetTableAdapters.receiptsTableAdapter receiptsTableAdapter;
        private System.Windows.Forms.ToolStrip fillByFilteredViewToolStrip;
        private System.Windows.Forms.ToolStripLabel taxYearToolStripLabel;
        private System.Windows.Forms.ToolStripLabel vehicleToolStripLabel;
        private System.Windows.Forms.ToolStripLabel licensePlateToolStripLabel;
        private System.Windows.Forms.ToolStripComboBox taxYearToolStripComboBox;
        private System.Windows.Forms.ToolStripComboBox vehicleToolStripComboBox;
        private System.Windows.Forms.ToolStripComboBox licensePlateToolStripComboBox;
        private System.Windows.Forms.ToolStripSeparator toolStripSeparator1;
        private System.Windows.Forms.ToolStripButton fillByFilteredViewToolStripButton;
        private System.Windows.Forms.Button btnClose;
        private System.Windows.Forms.DataGridViewTextBoxColumn iDDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn purchaseDateDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn totalCostDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn numberGallonsDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn vehicleDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn taxYearDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn licensePlateDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn receiptAttachedDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn linkToPdfDataGridViewTextBoxColumn;
    }
}