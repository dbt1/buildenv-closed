#!/bin/bash
source init.functions.sh
#set -x

BASEPATH=`pwd`
TIMESTAMP=`date '+%Y%m%d_%H%M%S'`

# only current version
# IMAGE_VERSION=`git -C $BASEPATH rev-parse --abbrev-ref HEAD`
IMAGE_VERSION="3.2.4"

FILES_DIR="$BASEPATH/files"

# identical listings
MACHINES_IDENTICAL_HD51="hd51 ax51 mutant51"
MACHINES_IDENTICAL_H7="h7 zgemmah7"

# gfutures listing
MACHINES_GFUTURES="$MACHINES_IDENTICAL_HD51 bre2ze4k"
# airdigital listing
MACHINES_AIRDIGITAL="$MACHINES_IDENTICAL_H7"
# edision listing
MACHINES_EDISION="osmio4k osmio4kplus"
# ceryon listing
MACHINES_CERYON="e4hdultra"

# valid machine list
MACHINES="$MACHINES_GFUTURES $MACHINES_AIRDIGITAL hd60 hd61 $MACHINES_EDISION $MACHINES_CERYON"

HINT_SYNTAX='\033[37;1mUsage '$0' <machine>\033[0m'
HINT_MACHINES="<$MACHINES>, <all> or keep empty < >"
HINT_IMAGE_VERSIONS="$IMAGE_VERSION"
 
LOG_PATH=$BASEPATH/log
mkdir -p $LOG_PATH

BACKUP_PATH=$BASEPATH/backups
mkdir -p $BACKUP_PATH

LOGFILE_NAME="$0_$TIMESTAMP.log"
LOGFILE=$LOG_PATH/$LOGFILE_NAME
TMP_LOGFILE=$LOG_PATH/.tmp.log
touch $LOGFILE

LOGFILE_LINK=$BASEPATH/$0.log

rm -f $TMP_LOGFILE
rm -f $LOGFILE_LINK
ln -sf $LOGFILE $LOGFILE_LINK


# set passed parameters
if [ "$1" == "" ]; then
	MACHINE="all"
else
	MACHINE=$1
fi

if [ `is_valid_machine "$MACHINE"` == false ]; then
    echo -e "\033[31;1mERROR:\tNo valid machine defined.\033[0m\n\t$HINT_SYNTAX.
    \tKeep parameter <machine> empty to initialize all possible machine types or set your favorite machine.
    \tPossible types are:
    \t\033[37;1m$HINT_MACHINES\033[0m\n"
    exit 1
fi

echo -e "##########################################################################################"
echo -e "\033[37;1mInitialze build environment:\nversion: $IMAGE_VERSION\nmachine: $MACHINE\033[0m"
echo -e "##########################################################################################\n"


BACKUP_SUFFIX=bak

YOCTO_GIT_URL=https://git.yoctoproject.org/git/poky
POKY=poky
POKY_NAME=$IMAGE_VERSION
BUILD_ROOT_DIR=$BASEPATH/$POKY-$IMAGE_VERSION
BUILD_ROOT=$BUILD_ROOT_DIR/build

OE_LAYER_NAME=meta-openembedded
OE_LAYER_GIT_URL=https://git.openembedded.org/meta-openembedded
OE_LAYER_PATCH_LIST="0001-openembedded-disable-meta-python.patch 0002-openembedded-disable-openembedded-layer-meta-phyton.patch"

OE_CORE_LAYER_NAME=openembedded-core
OE_CORE_LAYER_GIT_URL=https://github.com/openembedded/openembedded-core.git

TUXBOX_LAYER_NAME=meta-neutrino
TUXBOX_LAYER_GIT_URL=https://github.com/Tuxbox-Project

TUXBOX_BSP_LAYER_GIT_URL=$TUXBOX_LAYER_GIT_URL

AIRDIGITAL_LAYER_NAME=meta-airdigital
AIRDIGITAL_LAYER_GIT_URL=$TUXBOX_BSP_LAYER_GIT_URL/$AIRDIGITAL_LAYER_NAME

GFUTURES_LAYER_NAME=meta-gfutures
GFUTURES_LAYER_GIT_URL=$TUXBOX_BSP_LAYER_GIT_URL/$GFUTURES_LAYER_NAME

EDISION_LAYER_NAME=meta-edision
EDISION_LAYER_GIT_URL=$TUXBOX_LAYER_GIT_URL/$EDISION_LAYER_NAME

HISI_LAYER_NAME=meta-hisilicon
HISI_LAYER_GIT_URL=$TUXBOX_LAYER_GIT_URL/$HISI_LAYER_NAME

CERYON_LAYER_NAME=meta-ceryon
CERYON_LAYER_GIT_URL=$TUXBOX_BSP_LAYER_GIT_URL/$CERYON_LAYER_NAME

PYTHON2_LAYER_NAME=meta-python2
PYTHON2_LAYER_GIT_URL=https://git.openembedded.org/$PYTHON2_LAYER_NAME
PYTHON2_PATCH_LIST="0001-local_conf_outcomment_line_15.patch"

QT5_LAYER_NAME=meta-qt5
QT5_LAYER_GIT_URL=https://github.com/meta-qt5/$QT5_LAYER_NAME


# set required branches
COMPATIBLE_BRANCH=gatesgarth
YOCTO_BRANCH_HASH=bc71ec0
PYTHON2_BRANCH_HASH=27d2aeb
OE_BRANCH_HASH=f3f7a5f


# clone/update required branch from yocto
clone_meta '' $COMPATIBLE_BRANCH $YOCTO_GIT_URL $YOCTO_BRANCH_HASH $BUILD_ROOT_DIR
# for compatibility with old path structure
# ln -sf $BUILD_ROOT_DIR $BASEPATH/$POKY-$IMAGE_VERSION
echo -e "\033[32;1mOK ...\033[0m\n"

# clone required branch from openembedded
clone_meta '' $COMPATIBLE_BRANCH $OE_LAYER_GIT_URL $OE_BRANCH_HASH $BUILD_ROOT_DIR/$OE_LAYER_NAME "$OE_LAYER_PATCH_LIST"
echo -e "\033[32;1mOK ...\033[0m\n"
clone_meta '' master $OE_CORE_LAYER_GIT_URL '' $BUILD_ROOT_DIR/$OE_CORE_LAYER_NAME
echo -e "\033[32;1mOK ...\033[0m\n"

# clone required branch for meta-python2
clone_meta '' $COMPATIBLE_BRANCH $PYTHON2_LAYER_GIT_URL $PYTHON2_BRANCH_HASH $BUILD_ROOT_DIR/$PYTHON2_LAYER_NAME "$PYTHON2_PATCH_LIST"
echo -e "\033[32;1mOK ...\033[0m\n"

# clone required branch for meta-qt5
clone_meta '' $COMPATIBLE_BRANCH $QT5_LAYER_GIT_URL '' $BUILD_ROOT_DIR/$QT5_LAYER_NAME
echo -e "\033[32;1mOK ...\033[0m\n"

# clone/update required branch from meta-neutrino
clone_meta '' $COMPATIBLE_BRANCH $TUXBOX_LAYER_GIT_URL/$TUXBOX_LAYER_NAME '' $BUILD_ROOT_DIR/$TUXBOX_LAYER_NAME
echo -e "\033[32;1mOK ...\033[0m\n"


# gfutures
if [ "$MACHINE" == "all" ] || [ `is_required_machine_layer "' $MACHINES_GFUTURES '"` == true ]; then
	# gfutures
	clone_meta '' $COMPATIBLE_BRANCH $GFUTURES_LAYER_GIT_URL '' $BUILD_ROOT_DIR/$GFUTURES_LAYER_NAME
	echo -e "\033[32;1mOK ...\033[0m\n"
fi
# airdigital
if [ "$MACHINE" == "all" ] || [ `is_required_machine_layer "' $MACHINES_AIRDIGITAL '"` == true ]; then
	clone_meta '' $COMPATIBLE_BRANCH $AIRDIGITAL_LAYER_GIT_URL '' $BUILD_ROOT_DIR/$AIRDIGITAL_LAYER_NAME
	echo -e "\033[32;1mOK ...\033[0m\n"
fi
# edision
if [ "$MACHINE" == "all" ] || [ `is_required_machine_layer "' $MACHINES_EDISION '"` == true ]; then
	clone_meta '' $COMPATIBLE_BRANCH $EDISION_LAYER_GIT_URL '' $BUILD_ROOT_DIR/$EDISION_LAYER_NAME
	echo -e "\033[32;1mOK ...\033[0m\n"
fi
#TODO: move into gfutures
# hisilicon
	if [ "$MACHINE" == "all" ] || [ "$MACHINE" == "hd60" ] || [ "$MACHINE" == "hd61" ]; then
	clone_meta '' $COMPATIBLE_BRANCH $HISI_LAYER_GIT_URL '' $BUILD_ROOT_DIR/$HISI_LAYER_NAME
	echo -e "\033[32;1mOK ...\033[0m\n"
fi
# ceryon
if [ "$MACHINE" == "all" ] || [ `is_required_machine_layer "' $MACHINES_CERYON '"` == true ]; then
	clone_meta '' $COMPATIBLE_BRANCH $CERYON_LAYER_GIT_URL '' $BUILD_ROOT_DIR/$CERYON_LAYER_NAME
	echo -e "\033[32;1mOK ...\033[0m\n"
fi


# create included config file from sample file
if test ! -f $BASEPATH/local.conf.common.inc; then
	echo -e "\033[37;1mCONFIG:\033[0m\tcreate $BASEPATH/local.conf.common.inc as include file for layer configuration ..."
	do_exec "cp -v $BASEPATH/local.conf.common.inc.sample $BASEPATH/local.conf.common.inc"
fi


# create configuration for machine
if [ "$MACHINE" == "all" ]; then
	for M in  $MACHINES ; do
		create_local_config $M;
	done
else
	create_local_config $MACHINE;
fi


create_dist_tree;

echo -e "\033[37;1mNOTE:\033[0m"

# check and create distribution directory inside html directory for online update
if test ! -L /var/www/html/dist; then
	echo -e "\033[37;1m\tLocal setup for package online update.\033[0m"
	echo -e "\t############################################################################################"
	echo -e "\t/var/www/html/dist doesn't exists."
	echo -e "\tIf you want to use online update, please configure your webserver and use dist content"
	echo -e "\t"
	echo -e "\tAn easy way is to create a symlink to dist directory:"
	echo -e "\t"
	echo -e "\t\t\033[37;1msudo ln -s $BASEPATH/dist /var/www/html/dist\033[0m"

fi
echo -e "\t"
echo -e "\033[37;1m\tLocal environment setup\033[0m"
echo -e "\t############################################################################################"
echo -e "\t$BASEPATH/local.conf.common.inc was created by the 1st call of $0 from"
echo -e "\t$BASEPATH/local.conf.common.inc.sample"
echo -e "\tIf this file already exists nothing was changed on this file for your configuration."
echo -e "\tYou should check $BASEPATH/local.conf.common.inc and modify this file if required."
echo -e "\t"
echo -e "\tUnlike here: Please check this files for modifications or upgrades:"
echo -e "\t"
echo -e "\t\t\033[37;1m$BUILD_ROOT/<machine>/bblayer.conf\033[0m"
echo -e "\t\t\033[37;1m$BUILD_ROOT/<machine>/local.conf\033[0m"
# echo -e "\t############################################################################################"
echo -e "\t"
echo -e "\033[37;1m\tStart build\033[0m"
echo -e "\t############################################################################################"
echo -e "\tNow you are ready to build your own images and packages."
echo -e "\tSelectable machines are:"
echo -e "\t"
echo -e "\t\t\033[37;1m$MACHINES\033[0m"
echo -e "\t"
echo -e "\t Select your favorite machine (or identical) and the next steps are:\033[37;1m"
echo -e "\t"
echo -e "\t\tcd $BUILD_ROOT_DIR"
echo -e "\t\t. ./oe-init-build-env build/<machine>"
echo -e "\t\tbitbake neutrino-image"
echo -e "\t\033[0m"

echo -e "\t"
echo -e "\033[37;1m\tUpdating meta-layers\033[0m"
echo -e "\t############################################################################################"
echo -e "\tExecute init script again."
echo -e "\t"
echo -e "\tFor more informations and next steps take a look at the README.md!"
echo -e "\t"
echo -e "\033[32;1mDONE!\033[0m"

exit 0
