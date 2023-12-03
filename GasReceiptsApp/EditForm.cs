using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace GasReceiptsApp
{
    public partial class EditForm : Form
    {
        private readonly int selectedReceiptId;
        public EditForm(int receiptId)
        {
            InitializeComponent();
            selectedReceiptId = receiptId;
            GetReceiptData();
        }

        private void EditForm_Load(object sender, EventArgs e)
        {

        }
        public void GetReceiptData()
        {
            var receipt = new Receipt();
            receipt = receipt.GetReceipt(selectedReceiptId);

            lblFormTitle.Text = $"Edit Receipt {selectedReceiptId}";
            txtCost.Text = receipt.TotalCost.ToString();
            txtGallons.Text = receipt.NumberGallons.ToString();
            txtLicensePlate.Text = receipt.LicensePlate;
            txtTaxYear.Text = receipt.TaxYear.ToString();
            cmbVehicle.Text = receipt.Vehicle.ToString();
            dtPurcahaseDate.Value = receipt.PurchaseDate;
            txtLinkToPdf.Text = receipt.LinkToPdf.ToString();
        }

        public void UpdateReceiptData()
        {
            var receipt = new Receipt();

            receipt.ID = selectedReceiptId;
            receipt.TotalCost = Convert.ToSingle(txtCost.Text);
            receipt.NumberGallons = Convert.ToSingle(txtGallons.Text);
            receipt.PurchaseDate = dtPurcahaseDate.Value;
            receipt.Vehicle = cmbVehicle.Text;
            receipt.LicensePlate = txtLicensePlate.Text;
            receipt.TaxYear = Convert.ToInt16(txtTaxYear.Text);
            receipt.LinkToPdf = txtLinkToPdf.Text.Trim('"');

            receipt.UpdateReceipt(receipt);

        }

        private void btnUpdateReceipt_Click(object sender, EventArgs e)
        {
            UpdateReceiptData();
            this.Close();
        }

        private void folderBrowserDialog1_HelpRequest(object sender, EventArgs e)
        {

        }
    }
}
