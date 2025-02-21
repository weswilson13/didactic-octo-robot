# NNPTC Network Shutdown
*NOTE 1: Many of the shutdown commands issued in this procedure can be executed remotely. If the Administrator intends on using this method, it is recommended to establish a remote desktop session with the File cluster *owner* node (**NNPTC1FS10**). Reference* `Z:\Shared\NNPTC\W_Drives\ISD\scripts\Dahl\ShutdownForPowerOutage.txt` *for these commands.*

*NOTE 2: The Links page should be utilized for easy navigation required management portals and resources:* `Z:\Shared\NNPTC\W_Drives\ISD\Links\Links-VDI.html`

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



<!-- References to Hyperlinks -->
[NNPTC1VMS0501]:https://nnptc1vms0501.nnptc1.nnpp.gov/admin
[NNPTC1VC0801]:https://nnptc1vc0801.nnptc1.nnpp.gov/
[NNPTC1VMS0601]:https://nnptc1vms0601.nnptc1.nnpp.gov/admin
[NNPTC1VC0601]:https://nnptc1vc0601.nnptc1.nnpp.gov/
[PTCLW16V-HV0101]:https://ptclw16v-hv0101.nntp.gov/admin
[PTCL-VC0101]:https://ptcl-vc0101.nntp.gov/

