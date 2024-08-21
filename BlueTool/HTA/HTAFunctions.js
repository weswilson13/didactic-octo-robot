

function OnLoad() {
    
    // var objADSysInfo = new ActiveXObject("ADSystemInfo");
    // var strUser = objADSysInfo.UserName;
    // var objUser = GetObject("LDAP://" + strUser);

    // // Populate fields with current user information
    // try { document.getElementById("givenName").value = objUser.Get("GivenName"); } catch(e){}
    // try { document.getElementById("displayName").value = objUser.Get("DisplayName"); } catch(e){}
    // try { document.getElementById("telephoneNumber").value = objUser.Get("TelephoneNumber"); } catch(e){}
}

function GetDistinguishedName(username) {
    var objRootDSE = GetObject("LDAP://RootDSE");
    var strDomain = objRootDSE.Get("DefaultNamingContext");
    alert(strDomain);
}

function LookupUser() {
    var strUser = document.getElementById("userName").value
    var cn = GetDistinguishedName(strUser);
    alert(cn);
    var objUser = GetObject("LDAP://" + cn);
    alert(objUser.Get("UserPrincipalName"));
    try { document.getElementById("givenName").value = objUser.Get("GivenName"); } catch(e){}
    try { document.getElementById("displayName").value = objUser.Get("DisplayName"); } catch(e){}
    try { document.getElementById("telephoneNumber").value = objUser.Get("TelephoneNumber"); } catch(e){}
}

function UpdateUser() {
    var strUser = document.getElementById("userName").value
    var objUser = GetObject("LDAP://" + strUser);
    // var objADSysInfo = new ActiveXObject("ADSystemInfo");
    // var strUser = objADSysInfo.UserName;
    // var objUser = GetObject("LDAP://" + strUser);

    // Update user information
    objUser.Put("givenName", document.getElementById("givenName").value);
    objUser.Put("displayName", document.getElementById("displayName").value);
    objUser.Put("telephoneNumber", document.getElementById("telephoneNumber").value);
    objUser.SetInfo();

    alert("User information updated successfully!");
}

function Search(search,SearchType) {
    var arrSearchResult = [];
    var strSearch = '';
    switch(SearchType) {
        case "contains":
            strSearch = "*"+search+"*";
            break;
        case "begins":
            strSearch = search+"*";
            break;
        case "ends":
            strSearch = "*"+search;
            break;
        case "exact":
            strSearch = search;
            break;
        default:
            strSearch = "*"+search+"*";
            break;
    }
    var objRootDSE = GetObject("LDAP://RootDSE");
    var strDomain = objRootDSE.Get("DefaultNamingContext");
    
    var strOU = "OU=Users"; // Set the OU to search here.
    var strAttrib = "name,samaccountname"; // Set the attributes to retrieve here.
    
    var objConnection = new ActiveXObject("ADODB.Connection");
    objConnection.Provider="ADsDSOObject";
    objConnection.Open("ADs Provider");
    var objCommand = new ActiveXObject("ADODB.Command");
    objCommand.ActiveConnection = objConnection;
    var Dom = "LDAP://"+strOU+","+strDomain;
    var arrAttrib = strAttrib.split(",");
    objCommand.CommandText = "select '"+strAttrib+"' from '"+Dom+"' WHERE objectCategory = 'user' AND objectClass='user' AND samaccountname='"+search+"' ORDER BY samaccountname ASC";
    
    try {
        var objRecordSet = objCommand.Execute();
        objRecordSet.Movefirst;
        
        while(!(objRecordSet.EoF)) {
            var locarray = new Array();
            for(var y = 0; y < arrAttrib.length; y++) { 
                locarray.push(objRecordSet.Fields(y).value); 
            } 
            arrSearchResult.push(locarray); objRecordSet.MoveNext; 
        } return arrSearchResult; 
    } catch(e) { 
        alert(e.message); 
    } 
}