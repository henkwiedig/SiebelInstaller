SiebelInstaller
===============

Scripts to install a Siebel Demo Environment

These scripts will download, install, configure a complete Siebel Installation.

* Oracle Database xx
* Siebel Gateway 8.1.1.11
* Siebel Server 8.1.1.11
* Oracle Webserver xx
* Siebel Webserver Extention 8.1.1.11

** Requierments **

* x GB Memory
* x GB Diskspace
* Internet connection
* MOS Login

** Installation **

* Install RHEL or CentOs 6.4 (i is a minimal netinstall)
* Login to your as root
* wget https://github.com/henkwiedig/SiebelInstaller.git/bootstrap/bootstrap.sh
* ./bootstrap.sh
* git clone https://github.com/henkwiedig/SiebelInstaller.git
* cd SiebelInstaller
* ./SiebelInstaller
* wait to complete
* Login to http://ip-of-your-vm/ecommunication_enu/start.swe

** TODO **

* Get it to work from a to z
* Support more versions and languages
* Update existing installations

