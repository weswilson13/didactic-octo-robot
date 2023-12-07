namespace GasReceiptsApp
{
    partial class GasReceiptsForm
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
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle5 = new System.Windows.Forms.DataGridViewCellStyle();
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle3 = new System.Windows.Forms.DataGridViewCellStyle();
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle4 = new System.Windows.Forms.DataGridViewCellStyle();
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(GasReceiptsForm));
            this.btnEditReceipt = new System.Windows.Forms.Button();
            this.label1 = new System.Windows.Forms.Label();
            this.dataGridView1 = new System.Windows.Forms.DataGridView();
            this.LinkToPdf = new System.Windows.Forms.DataGridViewLinkColumn();
            this.btnClose = new System.Windows.Forms.Button();
            this.btnFilter = new System.Windows.Forms.Button();
            this.btnUpdateDatabase = new System.Windows.Forms.Button();
            this.iDDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.purchaseDateDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.totalCostDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.numberGallonsDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.vehicleDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.taxYearDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.licensePlateDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.receiptAttachedDataGridViewTextBoxColumn = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.receiptsBindingSource = new System.Windows.Forms.BindingSource(this.components);
            this.gasreceiptsDataSet = new GasReceiptsApp.gasreceiptsDataSet();
            this.receiptsTableAdapter = new GasReceiptsApp.gasreceiptsDataSetTableAdapters.receiptsTableAdapter();
            ((System.ComponentModel.ISupportInitialize)(this.dataGridView1)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.receiptsBindingSource)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.gasreceiptsDataSet)).BeginInit();
            this.SuspendLayout();
            // 
            // btnEditReceipt
            // 
            this.btnEditReceipt.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
            this.btnEditReceipt.Location = new System.Drawing.Point(766, 510);
            this.btnEditReceipt.Name = "btnEditReceipt";
            this.btnEditReceipt.Size = new System.Drawing.Size(61, 28);
            this.btnEditReceipt.TabIndex = 0;
            this.btnEditReceipt.Text = "Edit";
            this.btnEditReceipt.UseVisualStyleBackColor = true;
            this.btnEditReceipt.Click += new System.EventHandler(this.btnUpdate_Click);
            // 
            // label1
            // 
            this.label1.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.label1.BackColor = System.Drawing.SystemColors.ActiveCaption;
            this.label1.Font = new System.Drawing.Font("Microsoft Sans Serif", 15.75F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label1.ForeColor = System.Drawing.SystemColors.ControlDarkDark;
            this.label1.Location = new System.Drawing.Point(0, 9);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(935, 29);
            this.label1.TabIndex = 2;
            this.label1.Text = "Gas Receipts";
            // 
            // dataGridView1
            // 
            this.dataGridView1.AllowUserToAddRows = false;
            this.dataGridView1.AllowUserToDeleteRows = false;
            this.dataGridView1.AllowUserToOrderColumns = true;
            dataGridViewCellStyle1.BackColor = System.Drawing.Color.AntiqueWhite;
            this.dataGridView1.AlternatingRowsDefaultCellStyle = dataGridViewCellStyle1;
            this.dataGridView1.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.dataGridView1.AutoGenerateColumns = false;
            this.dataGridView1.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.dataGridView1.CellBorderStyle = System.Windows.Forms.DataGridViewCellBorderStyle.SingleHorizontal;
            dataGridViewCellStyle2.Alignment = System.Windows.Forms.DataGridViewContentAlignment.MiddleLeft;
            dataGridViewCellStyle2.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(20)))), ((int)(((byte)(25)))), ((int)(((byte)(70)))));
            dataGridViewCellStyle2.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            dataGridViewCellStyle2.ForeColor = System.Drawing.Color.WhiteSmoke;
            dataGridViewCellStyle2.SelectionBackColor = System.Drawing.SystemColors.GradientInactiveCaption;
            dataGridViewCellStyle2.SelectionForeColor = System.Drawing.SystemColors.ControlDarkDark;
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
            this.LinkToPdf});
            this.dataGridView1.DataSource = this.receiptsBindingSource;
            dataGridViewCellStyle5.Alignment = System.Windows.Forms.DataGridViewContentAlignment.MiddleLeft;
            dataGridViewCellStyle5.BackColor = System.Drawing.SystemColors.Window;
            dataGridViewCellStyle5.Font = new System.Drawing.Font("Microsoft Sans Serif", 8.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            dataGridViewCellStyle5.ForeColor = System.Drawing.SystemColors.ControlText;
            dataGridViewCellStyle5.NullValue = null;
            dataGridViewCellStyle5.SelectionBackColor = System.Drawing.SystemColors.Highlight;
            dataGridViewCellStyle5.SelectionForeColor = System.Drawing.SystemColors.HighlightText;
            dataGridViewCellStyle5.WrapMode = System.Windows.Forms.DataGridViewTriState.False;
            this.dataGridView1.DefaultCellStyle = dataGridViewCellStyle5;
            this.dataGridView1.Location = new System.Drawing.Point(0, 51);
            this.dataGridView1.Name = "dataGridView1";
            this.dataGridView1.Size = new System.Drawing.Size(935, 453);
            this.dataGridView1.TabIndex = 3;
            this.dataGridView1.CellContentClick += new System.Windows.Forms.DataGridViewCellEventHandler(this.dataGridView1_CellContentClick);
            this.dataGridView1.DoubleClick += new System.EventHandler(this.dataGridView1_DoubleClick);
            // 
            // LinkToPdf
            // 
            this.LinkToPdf.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.DisplayedCells;
            this.LinkToPdf.DataPropertyName = "LinkToPdf";
            this.LinkToPdf.HeaderText = "LinkToPdf";
            this.LinkToPdf.Name = "LinkToPdf";
            this.LinkToPdf.Resizable = System.Windows.Forms.DataGridViewTriState.True;
            this.LinkToPdf.SortMode = System.Windows.Forms.DataGridViewColumnSortMode.Automatic;
            this.LinkToPdf.Width = 81;
            // 
            // btnClose
            // 
            this.btnClose.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
            this.btnClose.Location = new System.Drawing.Point(848, 510);
            this.btnClose.Name = "btnClose";
            this.btnClose.Size = new System.Drawing.Size(61, 28);
            this.btnClose.TabIndex = 0;
            this.btnClose.Text = "Close";
            this.btnClose.UseVisualStyleBackColor = true;
            this.btnClose.Click += new System.EventHandler(this.btnClose_Click);
            // 
            // btnFilter
            // 
            this.btnFilter.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
            this.btnFilter.Location = new System.Drawing.Point(677, 511);
            this.btnFilter.Name = "btnFilter";
            this.btnFilter.Size = new System.Drawing.Size(66, 27);
            this.btnFilter.TabIndex = 4;
            this.btnFilter.Text = "Filter";
            this.btnFilter.UseVisualStyleBackColor = true;
            this.btnFilter.Click += new System.EventHandler(this.button1_Click);
            // 
            // btnUpdateDatabase
            // 
            this.btnUpdateDatabase.Location = new System.Drawing.Point(13, 511);
            this.btnUpdateDatabase.Name = "btnUpdateDatabase";
            this.btnUpdateDatabase.Size = new System.Drawing.Size(74, 27);
            this.btnUpdateDatabase.TabIndex = 5;
            this.btnUpdateDatabase.Text = "Import";
            this.btnUpdateDatabase.UseVisualStyleBackColor = true;
            this.btnUpdateDatabase.Click += new System.EventHandler(this.btnUpdateDatabase_Click);
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
            // 
            // totalCostDataGridViewTextBoxColumn
            // 
            this.totalCostDataGridViewTextBoxColumn.DataPropertyName = "TotalCost";
            dataGridViewCellStyle3.Format = "C2";
            dataGridViewCellStyle3.NullValue = null;
            this.totalCostDataGridViewTextBoxColumn.DefaultCellStyle = dataGridViewCellStyle3;
            this.totalCostDataGridViewTextBoxColumn.HeaderText = "TotalCost";
            this.totalCostDataGridViewTextBoxColumn.Name = "totalCostDataGridViewTextBoxColumn";
            // 
            // numberGallonsDataGridViewTextBoxColumn
            // 
            this.numberGallonsDataGridViewTextBoxColumn.DataPropertyName = "NumberGallons";
            dataGridViewCellStyle4.Format = "N3";
            dataGridViewCellStyle4.NullValue = null;
            this.numberGallonsDataGridViewTextBoxColumn.DefaultCellStyle = dataGridViewCellStyle4;
            this.numberGallonsDataGridViewTextBoxColumn.HeaderText = "NumberGallons";
            this.numberGallonsDataGridViewTextBoxColumn.Name = "numberGallonsDataGridViewTextBoxColumn";
            // 
            // vehicleDataGridViewTextBoxColumn
            // 
            this.vehicleDataGridViewTextBoxColumn.DataPropertyName = "Vehicle";
            this.vehicleDataGridViewTextBoxColumn.HeaderText = "Vehicle";
            this.vehicleDataGridViewTextBoxColumn.Name = "vehicleDataGridViewTextBoxColumn";
            // 
            // taxYearDataGridViewTextBoxColumn
            // 
            this.taxYearDataGridViewTextBoxColumn.DataPropertyName = "TaxYear";
            this.taxYearDataGridViewTextBoxColumn.HeaderText = "TaxYear";
            this.taxYearDataGridViewTextBoxColumn.Name = "taxYearDataGridViewTextBoxColumn";
            // 
            // licensePlateDataGridViewTextBoxColumn
            // 
            this.licensePlateDataGridViewTextBoxColumn.DataPropertyName = "LicensePlate";
            this.licensePlateDataGridViewTextBoxColumn.HeaderText = "LicensePlate";
            this.licensePlateDataGridViewTextBoxColumn.Name = "licensePlateDataGridViewTextBoxColumn";
            // 
            // receiptAttachedDataGridViewTextBoxColumn
            // 
            this.receiptAttachedDataGridViewTextBoxColumn.DataPropertyName = "ReceiptAttached";
            this.receiptAttachedDataGridViewTextBoxColumn.HeaderText = "ReceiptAttached";
            this.receiptAttachedDataGridViewTextBoxColumn.Name = "receiptAttachedDataGridViewTextBoxColumn";
            this.receiptAttachedDataGridViewTextBoxColumn.ReadOnly = true;
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
            // receiptsTableAdapter
            // 
            this.receiptsTableAdapter.ClearBeforeFill = true;
            // 
            // GasReceiptsForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(935, 549);
            this.Controls.Add(this.btnUpdateDatabase);
            this.Controls.Add(this.btnFilter);
            this.Controls.Add(this.dataGridView1);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.btnClose);
            this.Controls.Add(this.btnEditReceipt);
            this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
            this.Name = "GasReceiptsForm";
            this.Text = "Gas Receipts";
            this.Activated += new System.EventHandler(this.GasReceiptsForm_Activated);
            this.Load += new System.EventHandler(this.GasReceiptsForm_Load);
            ((System.ComponentModel.ISupportInitialize)(this.dataGridView1)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.receiptsBindingSource)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.gasreceiptsDataSet)).EndInit();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Button btnEditReceipt;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.DataGridView dataGridView1;
        private gasreceiptsDataSet gasreceiptsDataSet;
        private System.Windows.Forms.BindingSource receiptsBindingSource;
        private gasreceiptsDataSetTableAdapters.receiptsTableAdapter receiptsTableAdapter;
        private System.Windows.Forms.Button btnClose;
        private System.Windows.Forms.DataGridViewTextBoxColumn iDDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn purchaseDateDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn totalCostDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn numberGallonsDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn vehicleDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn taxYearDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn licensePlateDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewTextBoxColumn receiptAttachedDataGridViewTextBoxColumn;
        private System.Windows.Forms.DataGridViewLinkColumn LinkToPdf;
        private System.Windows.Forms.Button btnFilter;
        private System.Windows.Forms.Button btnUpdateDatabase;
    }
}

