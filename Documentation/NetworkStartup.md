<style>
    .updated {
        /* color:rgb(255, 255, 255); */
        position: absolute;
        top: 5px;
        right: 5px;
        font-size: 12px;
    }
</style>
<div class="updated">
    <a>Last Updated By: Wes Wilson</a></br>
    <a>Last Updated: 2/22/2025</a></br>
</div>

# ![NNPTC Logo][NNPTCLogo] NNPTC Network Startup

*NOTE 1: Preferentially use the Administrators credentials for all logins. If necessary, breakglass credentials can be retrieved from Thycotic Secret Server (while it is available) or the breakglass password book. Breakglass credentials will be denoted with an alphanumeric code in superscript that can be matched to the credential in Secret Server (or book) for ease of reference*

*NOTE 2: The [Links] page should be utilized for easy navigation to required management portals and resources:* `Z:\Shared\NNPTC\W_Drives\ISD\Links\Links-VDI.html`

## 1. Restore Support Equipment and UPSs

1. Ensure power is on at the CRAC Units
2. <sup>CRAC1</sup> Log in to the console for each CRAC unit. Turn the unit ON.
3. Go to each COM closet. Secure and unplug the UPS.
4. Plug in the UPSs in P120 and D107, verify they are *Online*.
5. Verify the UPS in P201A is online and supplying power via the *inverter*
    1. \<Procedure to bring UPS online>

## 2. Networking Infrastructure

1. Turn on the *Core* switches (NNPP - **NNPTC-D216-01** and NNTP - ~~**PTCLW-SW-01**~~)
2. Turn on the Firewalls (NNTP, **Palo Alto Firewall 01**, **Palo Alto Firewall 02**)

**Make sure the core switches are fully online before continuing (~10 minutes)** The lights on the active ports will be green when it is up.

## 3. KVMs

Turn on the KVMs (NNPP and NNTP)

## 4. Domain Controllers

Power on the Domain Controllers:
  * **NNPTC1DC21**
  * **NNPTC1DC22**
  * **PTCW16P-DC06**
  * **PTCW16P-DC07**
  * **PTCLW22P-DC01** (NNTP)

** Wait for these servers to come online fully before proceeding.** Verify using the KVM or other means.

## 5. Cisco Identity Services Engine (ISE)

1. Turn on all of the *primary* ISE Nodes
    * **NNPTC-D216-ISE-03** (NNPP)
    * **PTCL-ISE-03** (NNTP)

    Wait at least 5 minutes. It will take ~15 minutes for the application server to fully come online.

    To monitor services, <sup>ISE1</sup> log in to the ISE server via KVM or SSH Client (SecureCRT or PuTTY). Enter the following command: `show application status ise`

2. Power on secondary ISE nodes
    * **NNPTC-D216-ISE-04** (NNPP)
    * **PTCL-ISE-04** (NNTP)

## 6. DHCP

Using the <sup>KVM1</sup> KVM or <sup>IDRAC1</sup> iDRAC, power on the *primary* DHCP servers
  * **NNPTC1BU03** (NNPP)
  * **PTCLW16P-BU01** (NNTP)

## 7. Cluster Nodes and Other Services

1. Power on the following servers:
    * Primary SQL Cluster Node (**NNPTC1SQ18**)
    * Primary File Cluster Node (**NNPTC1FS10**)
    * SCCM Relay Server (**PTCLW19P-SCCM04**)
    * Hyper-V Management Server (**NNPTC1VM04**)

    **Wait for these servers to come online fully before proceeding**

2. <sup>TR1</sup> Log in to the Hyper-V Management Server (**NNPTC1VM04**). Open Hyper-V Manager and power on the Trellix servers in the following order:
    1. Trellix Database Server (**NNPTC1EPOSQL03**). Wait for services to come online.
    1. Trellix Management Server (**NNPTC1EPO03**)

3. <sup>SA1</sup> Log in to the *primary* File Cluster Node (**NNPTC1FS10**)

4. Power on the secondary Cluster Nodes
    * Secondary File Cluster Node (**NNPTC1FS11**)
    * Secondary SQL Cluster Node (**NNPTC1SQ17**)

5. (**Optional**) Clean up DNS entries for Virtual Desktops:
    1. Open DNS Management
    1. (NNPP) Remove all entries matching NNPTC-VM* from the NNPTC1.nnpp.gov DNS Zone
    1. (NNTP) Remove any entries matching PTCLW1[0,1]V* 

## 8. Nutanix
1. Turn on each host in each of the Nutanix Appliances

    | Block 6 | Block 7 | Block 8 |
    | --- | --- | --- |
    | NNPTC-NTNX-06-01 | NNPTC-NTNX-07-01 | NNPTC-NTNX-08-01 |
    | NNPTC-NTNX-06-02 | NNPTC-NTNX-07-02 | NNPTC-NTNX-08-02 |
    | NNPTC-NTNX-06-03 | NNPTC-NTNX-07-03 | NNPTC-NTNX-08-03 |
    | NNPTC-NTNX-06-04 | NNPTC-NTNX-07-04 | NNPTC-NTNX-08-04 |

<!-- References to Hyperlinks and Images-->
<!-- Formatting: 
    Links:  [Link Text]: path-to-link "Alternative Text"
    Images: [tag]: path-to-image "Alternative Text"
-->

<!-- Hyperlinks -->
[Links]:Z:\Shared\NNPTC\W_Drives\ISD\Links\Links-VDI.html

[NNPTC1VMS0501]:https://nnptc1vms0501.nnptc1.nnpp.gov/admin "Block 8 Horizon"
[NNPTC1VC0801]:https://nnptc1vc0801.nnptc1.nnpp.gov/ "Block 8 vCenter"
[NNPTC1VMS0601]:https://nnptc1vms0601.nnptc1.nnpp.gov/admin "Block 6 Horizon"
[NNPTC1VC0601]:https://nnptc1vc0601.nnptc1.nnpp.gov/ "Block 6 vCenter"
[PTCLW16V-HV0101]:https://ptclw16v-hv0101.nntp.gov/admin "NNTP Horizon"
[PTCL-VC0101]:https://ptcl-vc0101.nntp.gov/ "NNTP vCenter"

[NNPTC1ESX0801]:https://nnptc1esx0801.nnptc1.nnpp.gov "Block 8 vSAN Node 1"
[NNPTC1ESX0802]:https://nnptc1esx0802.nnptc1.nnpp.gov "Block 8 vSAN Node 2"
[NNPTC1ESX0803]:https://nnptc1esx0803.nnptc1.nnpp.gov "Block 8 vSAN Node 3"
[NNPTC1ESX0804]:https://nnptc1esx0804.nnptc1.nnpp.gov "Block 8 vSAN Node 4"
[NNPTC1ESX0601]:https://nnptc1esx0601.nnptc1.nnpp.gov "Block 6 vSAN Node 1"
[NNPTC1ESX0602]:https://nnptc1esx0602.nnptc1.nnpp.gov "Block 6 vSAN Node 2"
[NNPTC1ESX0603]:https://nnptc1esx0603.nnptc1.nnpp.gov "Block 6 vSAN Node 3"
[NNPTC1ESX0604]:https://nnptc1esx0604.nnptc1.nnpp.gov "Block 6 vSAN Node 4"
[PTCLVM-ESX0201]:https://ptclvm-esx0201.nntp.gov "NNTP vSAN Node 1"
[PTCLVM-ESX0202]:https://ptclvm-esx0202.nntp.gov "NNTP vSAN Node 2"
[PTCLVM-ESX0203]:https://ptclvm-esx0203.nntp.gov "NNTP vSAN Node 3"
[PTCLVM-ESX0204]:https://ptclvm-esx0204.nntp.gov "NNTP vSAN Node 4"
[PTCLVM-ESX02M]:https://ptclvm-esx0201.nntp.gov "NNTP Management Node"

[Prism Element]:https://nnptc-ntnx-04.nnptc1.nnpp.gov:9440 "Nutanix Management Console"

<!-- Images -->
[NNPTCLogo]: NNPTC_Logo.JPG "NNPTC Logo"