
# README 

To clone git repository: 
##Make sure you are in /home/kali

`git clone https://github.com/a-elhajjar/uow-newkali.git`

##To make all sh files executables, after clonning type

`find uow-newkali -type f -name "*.sh" -exec chmod +x {} \;`

## run the script

`cd uow-newkali`

`sudo ./kaliscript.sh`

<details> <summary><strong>Student ID</strong></summary>


<details> <summary><strong>DNS Switcher for Kali</strong></summary>

This script (`switch-dns.sh`) makes it easy to switch between **University DNS** (for use on campus) and **Home DNS** (for use outside the university).  
It ensures that `/etc/resolv.conf` always contains the correct nameservers and can optionally lock it (`chattr +i`) to prevent overwriting.

---

### Features
- Creates two profile files on first run:
  - `/etc/resolv.conf.uni` – with University DNS servers
  - `/etc/resolv.conf.home` – with public resolvers for home use
- Switches `/etc/resolv.conf` between profiles
- Applies/removes the immutable flag automatically
- Keeps timestamped backups of old configs
- On first run, the script automatically creates the two profile files:
  - /etc/resolv.conf.uni → University + fallback DNS
  - /etc/resolv.conf.home → Public resolvers for home use
- These files are then used each time you switch.
---

### Profiles

For univeirty profile: 
```shell
search localdomain
nameserver 192.168.179.2 # University DNS
nameserver 161.74.92.25
nameserver 161.74.92.50 # Google DNS
nameserver 8.8.8.8
```

```shell
nameserver 8.8.8.8
nameserver 1.1.1.1
```


### Usage

**1- Make the script executable:**

```bash
chmod +x switch-dns.sh
Run with sudo from the same directory:
```
**2- Switch to University DNS profile**
```bash
sudo ./switch-dns.sh uni
```
**3- Switch to Home DNS profile**
```bash
sudo ./switch-dns.sh home
```
**4- Show which profile is currently active and whether resolv.conf is locked**
```bash
sudo ./switch-dns.sh status
```
**5**Display the current /etc/resolv.conf contents**
```bash
sudo ./switch-dns.sh show
```
</details>

