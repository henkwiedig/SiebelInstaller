Siebel Installer
================

Scripts to install a Siebel Demo Environment

These scripts will download, install, configure a complete Siebel Installation.
A One-Click Siebel-Admin solution.

* Oracle Database 11.2.0.3
* Siebel Gateway 8.1.1.11
* Siebel Server 8.1.1.11
* Oracle Webserver 11.1.1.7
* Siebel Webserver Extention 8.1.1.11

**Requirements**

* 4 GB Memory, 1 CPU (more is always better)
* 35 GB Diskspace for installation media, 25 GB installed software (minimal siebel running)
* Internet connection
* MOS Login

**Installation**

* Install CentOs 6.4 (see bootstrap/links.txt or use bootstrap/create_vm.sh, RHEL should work too)
    * Manual installation : 
      Please obey requirements, minimal installation is sufficient
    * in case of ./bootstrap/create_vm.sh : 
      VBox automatically boots, press [TAB] at boot promt and append "ks=hd:fd0:/ks.cfg" to cmdline
* Login to your box as root (i use a VirtualBox machine)
* curl https://raw.github.com/henkwiedig/SiebelInstaller/master/bootstrap/bootstap.sh | sh
* cd /opt ; git clone https://github.com/henkwiedig/SiebelInstaller.git
* cd SiebelInstaller
* ./siebelinstaller.sh
* wait to complete
* Login to http://ip-of-your-vm:7777/ecommunication_enu/start.swe

**TODO**

* Cleanup, remove hard codeings
* Support more versions and languages
* Update existing installations

