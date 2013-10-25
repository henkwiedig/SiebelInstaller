Siebel Installer
================

Scripts to install a Siebel Demo Environment

These scripts will download, install, configure a complete Siebel Installation.

* Oracle Database 11.2.0.3
* Siebel Gateway 8.1.1.11
* Siebel Server 8.1.1.11
* Oracle Webserver 11.1.1.7
* Siebel Webserver Extention 8.1.1.11

**Requierments**

* 4 GB Memory, 1 CPU (more is always better)
* 32 GB Diskspace for installation media, 20 GB installed software
* Internet connection
* MOS Login

**Installation**

* Install RHEL or CentOs 6.4 (i use a minimal netinstall. see bootstrap/links.txt)
* Login to your as root
* curl https://raw.github.com/henkwiedig/SiebelInstaller/master/bootstrap/bootstap.sh | sh
* cd /opt ; git clone https://github.com/henkwiedig/SiebelInstaller.git
* cd SiebelInstaller
* ./siebelinstaller.sh
* wait to complete
* Login to http://ip-of-your-vm/ecommunication_enu/start.swe

**TODO**

* Cleanup, remove hard codeings
* Support more versions and languages
* Update existing installations

