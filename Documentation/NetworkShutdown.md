<style>
    .updated {
        /* color:rgb(255, 255, 255); */
        position: absolute;
        top: 5px;
        right: 5px;
        font-size: 12px;
    }
    .page-break {
        break-after: page;
    }
</style>
<div class="updated">
    <a>Last Updated By: Wes Wilson</a></br>
    <a>Last Updated: 2/22/2025</a></br>
</div>

# ![NNPTC Logo][NNPTCLogo] NNPTC Network Shutdown

*NOTE 1: Preferentially use the Administrator's credentials for all logins. If necessary, break glass credentials can be retrieved from Thycotic Secret Server (while it is available) or the break glass password book. Throughout this document, break glass credentials will be denoted with an alphanumeric code in superscript that can be matched to the credential in Secret Server (or book) for ease of reference*

*NOTE 2: Many of the shutdown commands issued in this procedure can be executed remotely. If the Administrator intends on using this method, it is recommended to establish a remote desktop session with the File cluster *owner* node (**NNPTC1FS10**). Reference* `Z:\Shared\NNPTC\W_Drives\ISD\scripts\Dahl\ShutdownForPowerOutage.txt` *for these commands.*

*NOTE 3: The [Links] page should be utilized for easy navigation to required management portals and resources:* `Z:\Shared\NNPTC\W_Drives\ISD\Links\Links-VDI.html`

# General Flow and Steps

[1. CommVault](#1-commvault-backup-solution)  
[2. Trellix](#2-trellix-endpoint-security)  
[3. Non-Vital Servers](#3-redundant-or-non-vital-services)  
[4. Virtual Environment](#4-virtual-desktop-infrastructure-vdi)  
[5. Badgescanners](#5-badgescanners)  
[6. Vital Servers](#6-vital-services)  
[7. NNTP Firewalls](#7-nntp-firewalls)  
[8. NNTP Vital Services](#8-nntp-domain-controllers)  
[9. Authentication Servers](#9-cisco-identity-services-ise)  
[10. Support Equipment and UPSs](#10-secure-support-equipment-and-upss)  
[11. DHCP](#11-dhcp)
[12. Credential Mapping](#12 - Credential Mapping)

## 1. CommVault (Backup Solution)

1. <sup>SA1</sup> Log in to the CommVault Management Server (**NNPTC1CS01**), open the *CommCell console* and secure any backups as follows:

    1. For a scheduled outage, set up a blackout window for the duration of the outage
        1. \<insert steps to setup a blackout window>

    1. Otherwise, kill any active jobs
        1. \<insert steps to kill jobs>

2. Gracefully shut down the server (this prevents any backups from starting unintentionally)

<div class="page-break"></div>

3. <sup>CV1</sup> Log in to each CommVault node (**NNPTC1CV01**, **NNPTC1CV02**, **NNPTC1CV03**) with an SSH client (PuTTY, SecureCRT, etc.). Execute the following commands to shutdown services:
    1. `commvault stop`
    1. `commvault list` to enumerate all running processes. **All** processes should be in a *stopped* state before proceeding with the next commands. Move to the next step and come back to the CommVault shutdown if necessary.
    1. On a single node, execute `gluster volume stop NNPTCCommVault01`
    1. at the completion of the above command, execute the following on each node:
    `shutdown -h now`

## 2. Trellix (Endpoint Security)

1. <sup>TR1</sup> Log in to the Hyper-V Management server (**NNPTC1VM04**) hosting the Trellix support servers - E-Policy/Management (**NNPTC1EPO03**) and SQL Server (**NNPTC1EPOSQL03**)
2. Open Hyper-V Manager
3. <sup>TR1</sup> Log in to and gracefully shutdown the Trellix Management server (**NNPTC1EPO03**)
4. <sup>TR1</sup> Log in to and gracefully shutdown the Trellix database server (**NNPTC1EPOSQL03**)
5. Gracefully shutdown the Hyper-V server (**NNPTC1VM04**)

## 3. Redundant or Non-Vital Services

<sup>SA1</sup> Log in to and gracefully shutdown each of the following servers:

* File cluster *passive* node (**NNPTC1FS11**)
* SQL cluster *passive* node (**NNPTC1SQ17**)
* SCCM relay server (**PTCW19V-SCCM04**)
* Backup NNPTC1 domain controller (**NNPTC1DC22**)
* Backup NRCS domain controller (**PTCW16P-DC07**)

**NOTE:** For servers without logins (e.g.- NRCS DC) a graceful shutdown may be manually performed by pressing the power button on the physical server for ~1 second. Observe the shutdown via KVM or other means.

## 4. Virtual Desktop Infrastructure (VDI)

### 4.a VMWare Virtual Environment

**These steps are applicable to both NNPP and NNTP VDI except where noted.**

1. Using the [Links] page (see above), log in to the applicable VMWare Horizon View console  
(<sup>SA1</sup> **[NNPTC1VMS0501]**, <sup>SA1</sup> **[NNPTC1VMS0601]**, <sup>SA2</sup> **[PTCLW16V-HV0101]**)

<div class="page-break"></div>

2. For each desktop pool, disable provisioning and the pool itself:
    1. Click on **Desktops** under the inventory in the left window pane
    1. Select all pools by enabling the top-level checkbox
    1. Select **Status -> Disable Provisioning**
    1. Click 'OK' when prompted
    1. Select **Status -> Disable Desktop Pool**
    1. Click 'OK' when prompted

3. Remove all virtual desktops
    1. Select the **Machines** node in the system tree under Inventory
    1. Select all of the VMs
    1. With all of the VMs selected, click **Remove** at the top of the page  
        1. *NOTE: the complete list of VMs may be paginated. Ensure all VMs are removed on all pages*
    1. Click 'OK' when prompted

4. Delete the **cp-parent** VMs
    1. Using the [Links] page (see above), log in to the applicable VMWare vCenter  
    (<sup>VC1</sup> **[NNPTC1VC0801]**, <sup>VC2</sup> **[NNPTC1VC0601]**, <sup>VC1</sup> **[PTCL-VC0101]**)
    1. From the vCenter interface for the cluster, select each ESXi host from the left window pane
        1. On the **Summary** tab, click the **Edit** button the lower potion of the **Custom Attributes** section
        1. Change the value of `InstantClone.Maintenance` from `0` to `1`
    1. Wait about 5-10 minutes or until all of the **cp-parent** VMs power off and delete
    1. Select the **vCenter** at the top of the system tree
        1. Click on the **Configure** tab
        1. Click on **Advanced Settings**
        1. Click the **Edit** button
        1. Select the *filter* icon and type `vcls` (there should be only one entry)
        1. Set the value to `False`
        1. Click **Save**

5. In **vSphere**, select the *VMs and Templates* view
    1. Click on the **Menu** button and select *Hosts and Clusters*
        1. Shutdown all VMs in this folder except for the vCenter appliance(s) (**NNPTC1VC0801**, **NNPTC1VC0601**, **PTCL-VC0101**), and for **NNPP ONLY** - any Nutanix Controller VMs (CVMs) with the name NTNX-*.
    1. Right click on each server and select **Power -> Shutdown Guest**

<div class="page-break"></div>

6. Using the [Links] page (see above), log in to each ESXi Host using the appropriate vSphere Web Client  

    | <sup>ESX1</sup> Block 6 vSAN | <sup>ESX1</sup> Block 8 vSAN | <sup>ESX1</sup> NNTP vSAN |
    | --- | --- | --- |
    | [NNPTC1ESX0601] | [NNPTC1ESX0801] | [PTCLVM-ESX0201] |
    | [NNPTC1ESX0602] | [NNPTC1ESX0802] | [PTCLVM-ESX0202] |
    | [NNPTC1ESX0603] | [NNPTC1ESX0803] | [PTCLVM-ESX0203] |
    | [NNPTC1ESX0604] | [NNPTC1ESX0804] | [PTCLVM-ESX0204] |
    | <!-- -->        | <!-- -->        | [PTCLVM-ESX02M]  |

    **Note:** You may be prompted that the server is already managed by vCenter Server. Click 'OK'.

    1. In the **vSphere** window for each ESXi host, click the *Virtual Machines* node. Shutdown the **vCenter** appliances (**NNPTC1VC0801**, **NNPTC1VC0601**, **PTCL-VC0101**)
        1. Right click on the VM and select **Guest OS -> Shut Down**

    1. **Ensure all of the VMs except the Nutanix VMs are shut down before proceeding**. All of the VM icons should no longer have the "play" triangle.

7. **NNPP Only** <sup>NT1</sup> Use a SSH Client (SecureCRT or PuTTY) to log into **one** of the Nutanix CVMs for **each block** (**nnptc-ntnx-06-01.nnptc1.nnpp.gov**, **nnptc-ntnx-08-01.nnptc1.nnpp.gov**)
    1. Shut down the cluster storage:
        1. Execute the command `cluster stop`
        1. If prompted, type `I agree` in acknowledgement
        1. Verify by executing `cluster status` and noting all 4 nodes in the down state

8. **NNPP Only** From the ESXi vSphere web console, shutdown each Controller VM
    1. Right click on each server _NTNX-*-CVM_ and select shutdown guest OS
        1. If the VM does not shutdown, select **Open Remote Console**. If this doesn't work, click on the VM and then click the link to launch the web console and click 'OK'.
        1. Click in the console window on each server and press 'enter'. You should see a login prompt.
        1. Press they key combination CTRL + ALT to release the curser from the console window
        1. Click the VM menu and select **Power -> Shutdown Guest**

9. Place the ESXi hosts in *Maintenance Mode* and shut down the host
    1. From the vSphere web client for each host, click the **Actions** button and select *Enter Maintenance Mode*. On **NNTP**, if prompted about data migration, choose the option for **No Data Migration**.
    1. Once the host is in Maintenance Mode, click the **Actions** button and select **Shutdown**.

<div class="page-break"></div>

### 4.b Nutanix AHV Virtual Environment

1. <sup>SA1</sup> Gracefully shutdown the following servers:

    <table>
        <tr><th colspan="4">Block 7 AHV VMs</th></tr>
        <tr><td>NNPTC1APV01</td><td>NNPTC1HD04</td><td>NNPTC1HP04</td><td>NNPTC1KM02</td></tr>
        <tr><td>NNPTC1MON02</td><td>NNPTC1NS01</td><td>NNPTC1PS04</td><td>NNPTC1SP02</td></tr>
        <tr><td>NNPTC1SP03</td><td>NNPTC1SQ16</td><td>NNPTC1TSS01</td><td>NNPTC1SW02</td></tr>
        <tr><td>NNPTC1VMS0501</td><td>NNPTC1VMS0601</td><td>NNPTC1ELAS01</td><td>NNPTC1ELAS02</td></tr>
        <tr><td>NNPTC1ELAS03</td><td>NNPTC1ELAS04</td><td>NNPTC1ELAS05</td><td>NNPTC1ELAS06</td></tr>
        <tr><td>NNPTC1ELAS07</td><td></td><td></td><td></td></tr>
    </table>

    **Note:** the NNPTC1ELAS0X servers must be shut down in **DESCENDING** order

2. <sup>NT2</sup> Using the [Links] page (see above), open [Prism Element]
    1. **IMPORTANT:** Unless you have a valid ADMINVC- account, click 'Cancel' if prompted for a smart card certificate.
    1. If the smart card certificate fails, clearing the certificate choice or restarting the browser session will be necessary to continue. Do not attempt to use the smart card certificate a second time.  

3. Click on the **Home** button and select **VM**.

4. Find any non-controller VMs that are still running and click on them.
    1. Click the **Power Off Actions** button
    1. Select **Guest shutdown** and click **submit**

5. <sup>NT1</sup> Using an SSH Client (SecureCRT or PuTTY), log in to a controller VM. Issue the following commands:
    1. `cluster stop`
    1. If prompted, press **I agree** in acknowledgement.
    1. Wait until the cluster stops.

6. <sup>NT1</sup> Using an SSH Client (SecureCRT or PuTTY), log into Nutanix Block 7 CVMs and issue the command `shutdown -h now`

## 5. Badgescanners

<sup>CA1</sup> Using a Client Admin account from a workstation in the Technician VLAN, shutdown the I/PORT Blade PCs

## 6. Vital Services

1. <sup>SA1</sup> Gracefully shutdown the File Cluster owner node (**NNPTC1FS10**) and the SQL Cluster owner node (**NNPTC1SQ18**)

2. <sup>SA1</sup> Gracefully shutdown the SQL backup server (**NNPTC1NM02**)

3. <sup>DA1</sup> Gracefully shutdown the primary NNPTC1 (**NNPTC1DC21**) and NRCS (**PTCW16P-DC06**) domain controllers

**NOTE:** For servers without logins (e.g.- NRCS DC) a graceful shutdown may be manually performed by pressing the power button on the physical server for ~1 second. Observe the shutdown via KVM or other means.

## 7. NNTP Firewalls

1. <sup>SW1</sup> Using the [Links] page (see above), login to the web interface for the backup Firewall (**Palo Alto Firewall 02**)
2. Click on the **Device** menu in the ribbon. Select **Setup**
3. Click the link to **Shutdown Device**
4. Repeat Steps 1-3 for the primary Firewall (**Pal Alto Firewall 01**)

## 8. NNTP Vital Services

1. <sup>SA2</sup> Gracefully shutdown the File server (**PTCLW16P-BU01**)
2. <sup>DA2</sup> Gracefully shutdown the domain controller (**PTCLW22P-DC01**)

**NOTE:** For servers without logins (e.g.- NNTP DC) a graceful shutdown may be manually performed by pressing the power button on the physical server for ~1 second. Observe the shutdown via KVM or other means.

## 9. Cisco Identity Services (ISE)

1. <sup>ISE1</sup> Using the appropriate KVM, log in to each ISE server console (primary first followed by the secondary)
2. Execute the command `halt`
3. Enter `y` in acknowledgement

## 10. Secure Support Equipment and UPSs

1. <sup>CRAC1</sup> Log in to the console for each CRAC unit. Turn the unit off.
2. Go to each COM closet. Secure and unplug the UPS.
3. Secure and unplug the UPSs in P120 and D107.
4. **EXTENDED OUTAGES ONLY** Secure the UPS in P201A
    1. \<Procedure to secure UPS>

## 11. DHCP
<sup>SA1</sup> Gracefully shutdown the primary DHCP server (**NNPTC1BU03**)

**NOTE:** If access is not possible via KVM or iDRAC, press the power button on the server for ~1 second

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