Siebel Installer
================

Scripts to install a Siebel Demo Environment

These scripts will download, install, configure a complete Siebel Installation.
A One-Click Siebel-Admin solution.

* Oracle Database 12.1.0.2.0
* Siebel 16.0.0.0
* Oracle Webserver 11.1.1.7

**Requirements**

* 4 GB Memory, 1 CPU (more is always better)
* 35 GB Diskspace for installation media, 25 GB installed software (minimal siebel running)
* Internet connection
* MOS Login

**Installation**

* Install CentOs 7, please obey requirements, minimal software selection is sufficient
* Login to your box as root (i use a VirtualBox machine)
* curl https://raw.github.com/henkwiedig/SiebelInstaller/master/bootstrap/bootstap.sh | sh
* cd /opt ; git clone https://github.com/henkwiedig/SiebelInstaller.git
* cd SiebelInstaller
* ./siebelinstaller.sh
* wait to complete
* Login to Siebel: http://ip-of-your-vm:7777/ecommunication_enu/start.swe
* Login to Oracle EM: https://ip-of-your-vm:1158/em

**TODO**

* Cleanup, remove hard codeings
* Support more versions and languages
* Update existing installations

