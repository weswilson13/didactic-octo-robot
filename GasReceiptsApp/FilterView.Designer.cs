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
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle1 = new System.Windows.Forms.DataGridViewCellStyle();
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle2 = new System.Windows.Forms.DataGridViewCellStyle();
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle3 = new System.Windows.Forms.DataGridViewCellStyle();
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle4 = new System.Windows.Forms.DataGridViewCellStyle();
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(FilterView));
            this.rbVehicle = new System.Windows.Forms.RadioButton();
            this.rbLicensePlate = new System.Windows.Forms.RadioButton();
            this.lblTotalGallons = new System.Windows.Forms.Label();
            this.lblSumGallons = new System.Windows.Forms.Label();
            this.lblTotalCost = new System.Windows.Forms.Label();
            this.lblSumCost = new System.Windows.Forms.Label();
            this.dataGridView1 = new System.Windows.Forms.DataGridView();
            this.receiptsBindingSource = new System.Windows.Forms.BindingSource(this.components);
            this.gasreceiptsDataSet = new GasReceiptsApp.gasreceiptsDataSet();
            this.fillByFilteredViewToolStrip = new System.Windows.Forms.ToolStrip();
            this.taxYearToolStripLabel = new System.Windows.Forms.ToolStripLabel();
            this.taxYearToolStripComboBox = new System.Windows.Forms.ToolStripComboBox();
            this.vehicleToolStripLabel = new System.Windows.Forms.ToolStripLabel();
            this.vehicleToolStripComboBox = new System.Windows.Forms.ToolStripComboBox();
            this.licensePlateToolStripLabel = new System.Windows.Forms.ToolStripLabel();
            this.licensePlateToolStripComboBox = new System.Windows.Forms.ToolStripComboBox();
            this.receiptsTableAdapter = new GasReceiptsApp.gasreceiptsDataSetTableAdapters.receiptsTableAdapter();
            this.iDDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.purchaseDateDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.totalCostDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.numberGallonsDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.vehicleDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.taxYearDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.licensePlateDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.receiptAttachedDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.linkToPdfDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.toolStripSeparator1 = new System.Windows.Forms.ToolStripSeparator();
            this.fillByFilteredViewToolStripButton = new System.Windows.Forms.ToolStripButton();
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
            // lblTotalGallons
            // 
            this.lblTotalGallons.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.lblTotalGallons.AutoSize = true;
            this.lblTotalGallons.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Underline, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblTotalGallons.Location = new System.Drawing.Point(667, 28);
            this.lblTotalGallons.Name = "lblTotalGallons";
            this.lblTotalGallons.Size = new System.Drawing.Size(93, 16);
            this.lblTotalGallons.TabIndex = 3;
            this.lblTotalGallons.Text = "Total Gallons: ";
            // 
            // lblSumGallons
            // 
            this.lblSumGallons.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.lblSumGallons.AutoSize = true;
            this.lblSumGallons.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblSumGallons.Location = new System.Drawing.Point(673, 49);
            this.lblSumGallons.Name = "lblSumGallons";
            this.lblSumGallons.Size = new System.Drawing.Size(0, 20);
            this.lblSumGallons.TabIndex = 3;
            // 
            // lblTotalCost
            // 
            this.lblTotalCost.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.lblTotalCost.AutoSize = true;
            this.lblTotalCost.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Underline, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblTotalCost.Location = new System.Drawing.Point(834, 28);
            this.lblTotalCost.Name = "lblTotalCost";
            this.lblTotalCost.Size = new System.Drawing.Size(74, 16);
            this.lblTotalCost.TabIndex = 3;
            this.lblTotalCost.Text = "Total Cost: ";
            // 
            // lblSumCost
            // 
            this.lblSumCost.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.lblSumCost.AutoSize = true;
            this.lblSumCost.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblSumCost.Location = new System.Drawing.Point(838, 49);
            this.lblSumCost.Name = "lblSumCost";
            this.lblSumCost.Size = new System.Drawing.Size(0, 20);
            this.lblSumCost.TabIndex = 3;
            // 
            // dataGridView1
            // 
            this.dataGridView1.AllowUserToAddRows = false;
            this.dataGridView1.AllowUserToDeleteRows = false;
            this.dataGridView1.AllowUserToOrderColumns = true;
            dataGridViewCellStyle1.BackColor = System.Drawing.Color.Azure;
            dataGridViewCellStyle1.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(0)))), ((int)(((byte)(0)))), ((int)(((byte)(64)))));
            this.dataGridView1.AlternatingRowsDefaultCellStyle = dataGridViewCellStyle1;
            this.dataGridView1.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.dataGridView1.AutoGenerateColumns = false;
            this.dataGridView1.BackgroundColor = System.Drawing.Color.WhiteSmoke;
            this.dataGridView1.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.dataGridView1.CellBorderStyle = System.Windows.Forms.DataGridViewCellBorderStyle.SingleVertical;
            dataGridViewCellStyle2.Alignment = System.Windows.Forms.DataGridViewContentAlignment.MiddleLeft;
            dataGridViewCellStyle2.BackColor = System.Drawing.Color.MidnightBlue;
            dataGridViewCellStyle2.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            dataGridViewCellStyle2.ForeColor = System.Drawing.Color.WhiteSmoke;
            dataGridViewCellStyle2.SelectionBackColor = System.Drawing.SystemColors.Highlight;
            dataGridViewCellStyle2.SelectionForeColor = System.Drawing.SystemColors.HighlightText;
            dataGridViewCellStyle2.WrapMode = System.Windows.Forms.DataGridViewTriState.True;
            this.dataGridView1.ColumnHeadersDefaultCellStyle = dataGridViewCellStyle2;
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
            this.dataGridView1.Location = new System.Drawing.Point(15, 87);
            this.dataGridView1.Name = "dataGridView1";
            this.dataGridView1.ReadOnly = true;
            this.dataGridView1.Size = new System.Drawing.Size(931, 412);
            this.dataGridView1.TabIndex = 4;
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
            this.fillByFilteredViewToolStrip.Size = new System.Drawing.Size(1006, 28);
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
            this.taxYearToolStripComboBox.Name = "taxYearToolStripComboBox";
            this.taxYearToolStripComboBox.Size = new System.Drawing.Size(100, 28);
            // 
            // vehicleToolStripLabel
            // 
            this.vehicleToolStripLabel.Name = "vehicleToolStripLabel";
            this.vehicleToolStripLabel.Size = new System.Drawing.Size(47, 25);
            this.vehicleToolStripLabel.Text = "Vehicle:";
            // 
            // vehicleToolStripComboBox
            // 
            this.vehicleToolStripComboBox.DropDownWidth = 100;
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
            this.licensePlateToolStripComboBox.Enabled = false;
            this.licensePlateToolStripComboBox.Name = "licensePlateToolStripComboBox";
            this.licensePlateToolStripComboBox.Size = new System.Drawing.Size(100, 28);
            // 
            // receiptsTableAdapter
            // 
            this.receiptsTableAdapter.ClearBeforeFill = true;
            // 
            // iDDataGridViewTextBoxColumn
            // 
            this.iDDataGridViewTextBoxColumn.DataPropertyName = "ID";
            this.iDDataGridViewTextBoxColumn.HeaderText = "ID";
            this.iDDataGridViewTextBoxColumn.Name = "iDDataGridViewTextBoxColumn";
            this.iDDataGridViewTextBoxColumn.ReadOnly = true;
            // 
            // purchaseDateDataGridViewTextBoxColumn
            // 
            this.purchaseDateDataGridViewTextBoxColumn.DataPropertyName = "PurchaseDate";
            this.purchaseDateDataGridViewTextBoxColumn.HeaderText = "PurchaseDate";
            this.purchaseDateDataGridViewTextBoxColumn.Name = "purchaseDateDataGridViewTextBoxColumn";
            this.purchaseDateDataGridViewTextBoxColumn.ReadOnly = true;
            // 
            // totalCostDataGridViewTextBoxColumn
            // 
            this.totalCostDataGridViewTextBoxColumn.DataPropertyName = "TotalCost";
            dataGridViewCellStyle3.Format = "C2";
            dataGridViewCellStyle3.NullValue = null;
            this.totalCostDataGridViewTextBoxColumn.DefaultCellStyle = dataGridViewCellStyle3;
            this.totalCostDataGridViewTextBoxColumn.HeaderText = "TotalCost";
            this.totalCostDataGridViewTextBoxColumn.Name = "totalCostDataGridViewTextBoxColumn";
            this.totalCostDataGridViewTextBoxColumn.ReadOnly = true;
            // 
            // numberGallonsDataGridViewTextBoxColumn
            // 
            this.numberGallonsDataGridViewTextBoxColumn.DataPropertyName = "NumberGallons";
            dataGridViewCellStyle4.Format = "N3";
            dataGridViewCellStyle4.NullValue = null;
            this.numberGallonsDataGridViewTextBoxColumn.DefaultCellStyle = dataGridViewCellStyle4;
            this.numberGallonsDataGridViewTextBoxColumn.HeaderText = "NumberGallons";
            this.numberGallonsDataGridViewTextBoxColumn.Name = "numberGallonsDataGridViewTextBoxColumn";
            this.numberGallonsDataGridViewTextBoxColumn.ReadOnly = true;
            // 
            // vehicleDataGridViewTextBoxColumn
            // 
            this.vehicleDataGridViewTextBoxColumn.DataPropertyName = "Vehicle";
            this.vehicleDataGridViewTextBoxColumn.HeaderText = "Vehicle";
            this.vehicleDataGridViewTextBoxColumn.Name = "vehicleDataGridViewTextBoxColumn";
            this.vehicleDataGridViewTextBoxColumn.ReadOnly = true;
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
            this.linkToPdfDataGridViewTextBoxColumn.DataPropertyName = "LinkToPdf";
            this.linkToPdfDataGridViewTextBoxColumn.HeaderText = "LinkToPdf";
            this.linkToPdfDataGridViewTextBoxColumn.Name = "linkToPdfDataGridViewTextBoxColumn";
            this.linkToPdfDataGridViewTextBoxColumn.ReadOnly = true;
            // 
            // toolStripSeparator1
            // 
            this.toolStripSeparator1.Name = "toolStripSeparator1";
            this.toolStripSeparator1.Size = new System.Drawing.Size(6, 28);
            // 
            // fillByFilteredViewToolStripButton
            // 
            this.fillByFilteredViewToolStripButton.Alignment = System.Windows.Forms.ToolStripItemAlignment.Right;
            this.fillByFilteredViewToolStripButton.BackColor = System.Drawing.SystemColors.HotTrack;
            this.fillByFilteredViewToolStripButton.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Text;
            this.fillByFilteredViewToolStripButton.Font = new System.Drawing.Font("Segoe UI Semibold", 12F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.fillByFilteredViewToolStripButton.ForeColor = System.Drawing.Color.WhiteSmoke;
            this.fillByFilteredViewToolStripButton.Image = ((System.Drawing.Image)(resources.GetObject("fillByFilteredViewToolStripButton.Image")));
            this.fillByFilteredViewToolStripButton.ImageTransparentColor = System.Drawing.Color.Magenta;
            this.fillByFilteredViewToolStripButton.Name = "fillByFilteredViewToolStripButton";
            this.fillByFilteredViewToolStripButton.Size = new System.Drawing.Size(68, 25);
            this.fillByFilteredViewToolStripButton.Text = "Update";
            this.fillByFilteredViewToolStripButton.Click += new System.EventHandler(this.fillByFilteredViewToolStripButton_Click);
            // 
            // FilterView
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1006, 554);
            this.Controls.Add(this.fillByFilteredViewToolStrip);
            this.Controls.Add(this.dataGridView1);
            this.Controls.Add(this.lblSumCost);
            this.Controls.Add(this.lblSumGallons);
            this.Controls.Add(this.lblTotalCost);
            this.Controls.Add(this.lblTotalGallons);
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
        private System.Windows.Forms.Label lblTotalGallons;
        private System.Windows.Forms.Label lblSumGallons;
        private System.Windows.Forms.Label lblTotalCost;
        private System.Windows.Forms.Label lblSumCost;
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
        private System.Windows.Forms.DataGridViewTextBoxColumn iDDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn purchaseDateDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn totalCostDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn numberGallonsDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn vehicleDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn taxYearDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn licensePlateDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn receiptAttachedDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn linkToPdfDataGridViewTextBoxColumn;
        private System.Windows.Forms.ToolStripSeparator toolStripSeparator1;
        private System.Windows.Forms.ToolStripButton fillByFilteredViewToolStripButton;
    }
}