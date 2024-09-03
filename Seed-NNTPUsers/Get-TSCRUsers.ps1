param(
    [string[]]$DODID
)

process {
    $DODID.ForEach({
        [System.Windows.Forms.MessageBox]::Show($PSItem)
    })
}