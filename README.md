# Quick start image build #

## Preparation
NOTE: If you are using the Tuxbox-Builder VM (this is not mandatory) please jump to step 1. The Tuxbox-Builder VM already contains required packages.
For details and download of Tuxbox-Builder VM see: https://sourceforge.net/projects/n4k/files/Tuxbox-Builder

### Install required packages (Debian 9/10)
```bash
apt-get install -y gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential \
chrpath socat cpio python python3 python3-pip python3-pexpect xz-utils debianutils \
iputils-ping python3-git python3-jinja2 libegl1-mesa pylint3 xterm subversion locales-all \
libxml2-utils ninja-build default-jre clisp libcapstone3
```
Also required is sdl.
```bash
apt-get install -y libsdl1.2-dev
```
For newer image versions with dunfell (3.1) or later use libsdl2-dev instead libsdl1.2-dev
```bash
apt-get install -y libsdl2-dev
```

### Recommended additional packages:
```bash
apt-get install -y gitk git-gui meld
```
NOTE: In case of no configured git, please set your global git user data:
```bash
git config --global user.email "you@example.com"
git config --global user.user "Your Name"
```

For usage with other distributions see:

https://www.yoctoproject.org/docs/3.0.3/brief-yoctoprojectqs/brief-yoctoprojectqs.html

## 1. Clone init script into a directory of your choice
```bash
$:~ git clone https://github.com/tuxbox-neutrino/build.git
```

## 2. Change to the generated directory
```bash
$:~ cd build
```

## 3. Execute init script
This will clone all required layers and moves some config files into your build directory.
* Parameter 1: Machine type can be  h7, hd51, hd60, hd61, osmio4k, osmio4kplus or set 'all' or keep empty '' for all machines.
* Parameter 2: Image version can be 3.0, 3.1, 3.2 or keep empty for latest version (recommended, because of older versions are not really maintained anymore)
```bash
$:~ ./init.sh <machine> <image-version>
```

## 4. Switch to poky directory
After sccessfull executed init script you will find a subdirectory like poky-3.x .
Now switch to this directory e.g.:
```bash
$:~ cd poky-3.2
```

## 5. Execute environment script
Please use possible machine type which you selected (see step 3)! Here as example we use hd51.
This creates (if not exists!) the build directory named as hd51 (default name ist build) and sets the build environment.
```bash
$:~ . ./oe-init-build-env hd51

### Shell environment set up for builds. ###

You can now run 'bitbake <target>'

Common targets are:
    core-image-minimal
    core-image-sato
    meta-toolchain
    meta-ide-support

You can also run generated qemu images with a command like 'runqemu qemux86'

Other commonly useful commands are:
 - 'devtool' and 'recipetool' handle common recipe tasks
 - 'bitbake-layers' handles common layer tasks
 - 'oe-pkgdata-util' handles common target package tasks
tuxbox@tuxbox-builder:~/Build/poky-3.0/hd51
$
```
NOTE: If you left the build directory you must retry step 5 for your machine type to recreate the required environment.

## 6. Build image
After step 5 you are ready to build an image.
```bash
$:~ /build/poky-3.0/<machine>$ bitbake neutrino-image
```
This may take a while. Some warn messages can be ignored and error messages during setscene tasks are no problem but errors during build and package tasks will abort the process. In this case please report or send us your solution to https://forum.tuxbox-neutrino.org/forum/viewforum.php?f=77. Help is very welcome.

If all done, such a message should appear:
```bash
...
NOTE: Tasks Summary: Attempted 4568 tasks of which 4198 didn't need to be rerun and all succeeded.
...
```
## That's it ...

Built images and packages to find under:
```
~/build/poky-X.X/<machine>/tmp/deploy
```
or in the dist directory:
```
~/build/dist/<image-version/<machine>/
```

## Update the meta layer repositories
Execution of init script will update the yocto poky-x.x repository to the required yocto release and will updating the included local meta layers to  current
state of remote repositories. Of corse you can update and modyify your local meta-layer for meta-neutrino and machine layers repositories manually. The update routines will stash uncommitted changes or will rebase your local commits to new remote changes, but conflicts are possible. In this case you must solve manually.
Please do not modify the Yocto-sources! This is not recommended by the Yocto-Team. Do it only if you know what you do!

Note: Your config files will be untouched. New or adapted config options are not considered. Please check your configuration if required.


## Reset configuration
If you want to reset your configs, please rename (delete is not recommended) the conf directory and execute the init script again.


## Customize if required
It's recommended to build for first time without any changes on config files to get an impression how the build process is working and see the results.
The possibilities for adjustments are very extensive and not really manageable for beginners. However, the Yoctoproject is very 
extensively documented and provides the best source of information.

The generated local.conf contains only a few lines but contains a line which is linking a common config file and is valid for all images and supported machine types. The origin cloned sample config file ("local.conf.common.inc.sample") should be untouched. This avoids possible conflicts during updating the init script from git repo. After executed init script (step 3), the config sample file was renamed from "local.conf.common.inc.sample" to "local.conf.common.inc" and this file you can feed with your own options which have effect for all images you want to build.
Alternatively you can modify the default "$HOME/Build/poky-X.X/<machine>/conf/local.conf" with your own requirements or include your own config file. After updated init script, some new or changed options could be added or removed. This case you should consider for your own configuration.

For local configuration these config files within your build directory are required:
```
../build/poky-X.X/<machine>/conf/bblayers.conf
../build/poky-X.X/<machine>/conf/local.conf
```

This is the minimal required setup for bblayers.conf. 
NOTE! machine name is not a part of layer name (e.g. hd51) 

```bitbake
# POKY_BBLAYERS_CONF_VERSION is increased each time build/conf/bblayers.conf
# changes incompatibly
POKY_BBLAYERS_CONF_VERSION = "2"

BBPATH = "${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \
  	${HOME}/build/poky-X.X/meta \
  	${HOME}/build/poky-X.X/meta-poky \
  	${HOME}/build/poky-X.X/meta-yocto-bsp \
	${HOME}/build/poky-X.X/meta-neutrino \
	${HOME}/build/poky-X.X/poky/meta-<metaname> \
"
```  
Further informations about yocto buildsystem you can find here:

* https://www.yoctoproject.org/docs/latest/brief-yoctoprojectqs/brief-yoctoprojectqs.html
* https://www.yoctoproject.org/docs/current/mega-manual/mega-manual.html
