# NNPTC Network Shutdown

*NOTE 1: Many of the shutdown commands issued in this procedure can be executed remotely. If the Administrator intends on using this method, it is recommended to establish a remote desktop session with the File cluster *owner* node (**NNPTC1FS10**). Reference* `Z:\Shared\NNPTC\W_Drives\ISD\scripts\Dahl\ShutdownForPowerOutage.txt` *for these commands.*

*NOTE 2: The [Links] page should be utilized for easy navigation required management portals and resources:* `Z:\Shared\NNPTC\W_Drives\ISD\Links\Links-VDI.html`

## 1. CommVault (Backup Solution)

1. Log in to the CommVault Management Server (**NNPTC1CS01**), open the CommCell console and secure any backups as follows:

    1. For a scheduled outage, set up a blackout window for the duration of the outage

    1. Otherwise, kill any active jobs

2. Gracefully shut down the server (this prevents any backups from starting unintentionally)

3. Log in to each CommVault node (**NNPTC1CV01**, **NNPTC1CV02**, **NNPTC1CV03**) with an SSH client (PuTTY, SecureCRT, etc.). Execute the following commands to shutdown services:
    1. `commvault stop`
    1. `commvault list` to enumerate all running processes. **All** processes should be in a *stopped* state before proceeding with the next commands. Move to the next step and come back to the CommVault shutdown if necessary.
    1. On a single node, execute `gluster volume stop NNPTCCommVault01`
    1. at the completion of the above command, execute the following on each node:
    `shutdown -h now`

## 2. Trellix (Endpoint Security)

1. Log in to the Hyper-V server (**NNPTC1VM04**) hosting the Trellix support servers - E-Policy (**NNPTC1EPO03**) and SQL Server (**NNPTC1EPOSQL03**)
2. Open Hyper-V Manager
3. Log in to and gracefully shutdown the E-Policy server (**NNPTC1EPO03**)
4. Log in to and gracefully shutdown the Trellix database server (**NNPTC1EPOSQL03**)
5. Gracefully shutdown the Hyper-V server (**NNPTC1VM04**)

## 3. Redundant or Non-Vital Services

Log in to and gracefully shutdown each of the following servers:

* File cluster *passive* node (**NNPTC1FS11**)
* SQL cluster *passive* node (**NNPTC1SQ17**)
* SCCM relay server (**PTCW19V-SCCM04**)
* Backup NNPTC1 domain controller (**NNPTC1DC22**)
* Backup NRCS domain controller (**PTCW16P-DC07**)

## 4. Virtual Desktop Infrastructure (VDI)

### VMWare Virtual Environment

**These steps are applicable to both NNPP and NNTP VDI except where noted.**

1. Using the Links page (see above), log in to the applicable VMWare Horizon View console (**[NNPTC1VMS0501]**, **[NNPTC1VMS0601]**, **[PTCLW16V-HV0101]**)

2. For each desktop pool, disable provisioning and the pool itself:
    1. Click on **Desktops** under the inventory in the left window pane
    1. Select all pools by enabling the top-level checkbox
    1. Select Status -> Disable Provisioning
    1. Click 'OK' when prompted
    1. Select Status -> Disable Desktop Pool
    1. Click 'OK' when prompted

3. Remove all virtual desktops
    1. Select the **Machines** node in the system tree under Inventory
    1. Select all of the VMs
    1. With all of the VMs selected, click 'Remove' at the top of the page  
        1. *NOTE: the complete list of VMs may be paginated. Ensure all VMs are removed from all pages*
    1. Click 'OK' when prompted

4. Delete the **cp-parent** VMs
    1. Using the Links page (see above), log in to the applicable VMWare vCenter (**[NNPTC1VC0801]**, **[NNPTC1VC0601]**, **[PTCL-VC0101]**)
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
    1. Right click on each server and select *Power -> Shutdown Guest*

6. Using the Links page (see above), log in to each ESXi Host using the appropriate vSphere Web Client  

    Block 6 | Block 8 | NNTP
    --- | --- | ---
    [NNPTC1ESX0601] | [NNPTC1ESX0801] | [PTCLVM-ESX0201]
    [NNPTC1ESX0602] | [NNPTC1ESX0802] | [PTCLVM-ESX0202]
    [NNPTC1ESX0603] | [NNPTC1ESX0803] | [PTCLVM-ESX0203]
    [NNPTC1ESX0604] | [NNPTC1ESX0804] | [PTCLVM-ESX0204]
    |||[PTCLVM-ESX02M]

    **Note:** You may be prompted that the server is already managed by vCenter Server. Click 'OK'.

    1. In the **vSphere** window for each ESXi host, click the *Virtual Machines* node. Shutdown the **vCenter** appliances (**NNPTC1VC0801**, **NNPTC1VC0601**, **PTCL-VC0101**)
        1. Right click on the VM and select **Guest OS -> Shut Down**

    1. **Ensure all of the VMs except the Nutanix VMs are shut down before proceeding**. All of the VM icons should no longer have the "play" triangle.

7. **NNPP Only** Use a SSH Client (SecureCRT or PuTTY) to log into **one** of the Nutanix CVMs for **each block** (**nnptc-ntnx-06-01.nnptc1.nnpp.gov**, **nnptc-ntnx-08-01.nnptc1.nnpp.gov**)
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

### Nutanix AHV Virtual Environment

1. Gracefully shutdown the following servers:

    <!-- --> | <!-- --> | <!-- --> | <!-- -->
    --- | --- | --- | ---
    NNPTC1APV01 | NNPTC1HD04 | NNPTC1HP04 | NNPTC1KM02
    NNPTC1MON02 | NNPTC1NS01 | NNPTC1PS04 | NNPTC1SP02
    NNPTC1SP03 | NNPTC1SQ16 | NNPTC1TSS01 | NNPTC1SW02 
    NNPTC1VMS0501 | NNPTC1VMS0601 | NNPTC1ELAS01 | NNPTC1ELAS02
    NNPTC1ELAS03 | NNPTC1ELAS04 | NNPTC1ELAS05 | NNPTC1ELAS06
    NNPTC1ELAS07

    **Note:** the NNPTC1ELASXX servers must be shut down in **DESCENDING** order

2. Using the Links page (see above), open [Prism Element]
    1. **IMPORTANT:** Unless you have a valid ADMINVC- account, click 'Cancel' if prompted for a smart card certificate.
    1. If the smart card certificate fails to work, clearing the certificate choice or restarting the browser session will be necessary to continue. Do not attempt to use the smart card certificate a second time.  

3. Click on the **Home** button and select **VM**.

4. Find and non-controller VMs that are still running and click on them.
    1. Click the **Power Off Actions** button
    1. Select **Guest shutdown** and click **submit**

5. Using an SSH Client (SecureCRT or PuTTY), log in to a controller VM. Issue the following commands:
    1. `cluster stop`
    1. If prompted, press **I agree** in acknowledgement. Wait until the cluster stops

6. Using an SSH Client (SecureCRT or PuTTY), log into Nutanix Block 7 CVMs and issue the command `shutdown -h now`

## 5. Badgescanners

Using a Client Admin account from a workstation in the Technician VLAN, shutdown the I/PORT Blade PCs

## 6. Vital Services

1. Gracefully shutdown the File Cluster owner node (**NNPTC1FS10**) and the SQL Cluster owner node (**NNPTC1SQ18**)

2. Gracefully shutdown the primary NNPTC1 (**NNPTC1DC21**) and NRCS (**PTCW16P-DC06**) domain controllers 

<!-- References to Hyperlinks -->
[Links]:Z:\Shared\NNPTC\W_Drives\ISD\Links\Links-VDI.html

[NNPTC1VMS0501]:https://nnptc1vms0501.nnptc1.nnpp.gov/admin
[NNPTC1VC0801]:https://nnptc1vc0801.nnptc1.nnpp.gov/
[NNPTC1VMS0601]:https://nnptc1vms0601.nnptc1.nnpp.gov/admin
[NNPTC1VC0601]:https://nnptc1vc0601.nnptc1.nnpp.gov/
[PTCLW16V-HV0101]:https://ptclw16v-hv0101.nntp.gov/admin
[PTCL-VC0101]:https://ptcl-vc0101.nntp.gov/

[NNPTC1ESX0801]:https://nnptc1esx0801.nnptc1.nnpp.gov
[NNPTC1ESX0802]:https://nnptc1esx0802.nnptc1.nnpp.gov
[NNPTC1ESX0803]:https://nnptc1esx0803.nnptc1.nnpp.gov
[NNPTC1ESX0804]:https://nnptc1esx0804.nnptc1.nnpp.gov
[NNPTC1ESX0601]:https://nnptc1esx0601.nnptc1.nnpp.gov
[NNPTC1ESX0602]:https://nnptc1esx0602.nnptc1.nnpp.gov
[NNPTC1ESX0603]:https://nnptc1esx0603.nnptc1.nnpp.gov
[NNPTC1ESX0604]:https://nnptc1esx0604.nnptc1.nnpp.gov
[PTCLVM-ESX0201]:https://ptclvm-esx0201.nntp.gov
[PTCLVM-ESX0202]:https://ptclvm-esx0202.nntp.gov
[PTCLVM-ESX0203]:https://ptclvm-esx0203.nntp.gov
[PTCLVM-ESX0204]:https://ptclvm-esx0204.nntp.gov
[PTCLVM-ESX02M]:https://ptclvm-esx0201.nntp.gov

[Prism Element]:https://nnptc-ntnx-04.nnptc1.nnpp.gov:9440