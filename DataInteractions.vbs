Sub LoadStatuses
    Dim cn, sql, rs
    Dim objOption
    
    sql = "Select ID, Status From tblStatuses"
    
    Set cn = CreateObject("ADODB.Connection")
    cn.ConnectionString = connString
    cn.Open 
    
    Set rs = cn.Execute(sql)

    while (not rs.eof)
        Set objOption = Document.CreateElement("OPTION")
        objOption.Text = rs.Fields("Status")
        objOption.Value = rs.Fields("ID")
        Statuses.Add(objOption)
        rs.movenext
    wend

    cn.Close
    Set cn = nothing

End Sub