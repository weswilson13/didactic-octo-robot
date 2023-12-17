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

Private Sub MapNetworkDrive(driveLetter, remoteShare)
    dim objNetwork

    Set objNetwork = CreateObject("WScript.Network")
    objNetwork.MapNetworkDrive driveLetter & ":", remoteShare, False
End Sub

Sub ImportComputer()
    dim objShell, fso, parentFolder, absolutePath, input
    
    input = InputBox("Enter the remote host: ")

    Set fso = CreateObject("Scripting.FileSystemObject")
    parentFolder = location.host + fso.GetParentFolderName(location.pathname)
    if (location.host <>"") then _
        parentFolder = "\\" + parentFolder

    Set objShell = CreateObject("Wscript.Shell")
    objShell.Run "powershell.exe -executionpolicy bypass -file " & Join(Array(parentFolder,"Get-ComputerInfo.ps1 " & chr(34) & parentFolder & chr(34) & " " & input),"\"),1,True


End Sub ' Import