using System;
using System.Globalization;
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
            txtCost.Text = String.Format("{0:c}",receipt.TotalCost);
            txtGallons.Text = receipt.NumberGallons.ToString();
            txtLicensePlate.Text = receipt.LicensePlate;
            txtTaxYear.Text = receipt.TaxYear.ToString();
            cmbVehicle.Text = receipt.Vehicle.ToString();
            dtPurcahaseDate.Value = receipt.PurchaseDate;
            txtLinkToPdf.Text = receipt.LinkToPdf.ToString();
            axAcroPDF1.LoadFile(txtLinkToPdf.Text);
        }

        public void UpdateReceiptData()
        {
            var receipt = new Receipt();

            receipt.ID = selectedReceiptId;
            receipt.TotalCost = float.Parse(txtCost.Text, NumberStyles.Currency | NumberStyles.AllowDecimalPoint);
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


        private void btnCancel_Click(object sender, EventArgs e)
        {
            this.Close();
        }
    }
}
