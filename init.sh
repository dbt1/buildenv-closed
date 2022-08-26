#!/bin/bash

#set -x

BASEPATH=`pwd`

# only current version
IMAGE_VERSION=`git -C $BASEPATH rev-parse --abbrev-ref HEAD`

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

# valid machine list
MACHINES="$MACHINES_GFUTURES $MACHINES_AIRDIGITAL hd60 hd61 $MACHINES_EDISION"

HINT_SYNTAX='\033[37;1mUsage '$0' <machine>\033[0m'
HINT_MACHINES="<$MACHINES>, <all> or keep empty < >"
HINT_IMAGE_VERSIONS="$IMAGE_VERSION"
 
LOG_PATH=$BASEPATH/log
mkdir -p $LOG_PATH
LOGFILE_NAME="$0_`date '+%Y%m%d_%H%M%S'`.log"
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

# function for checking of valid machine(s)
function is_valid_machine ()
{
	ISM=$1
	for M in $MACHINES ; do
		if [ "$ISM" == "$M" ] || [ "$MACHINE" == "all" ]; then
			echo true
			return 1
		fi
	done
	echo false
	return 0
}

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

function do_exec() {
	DEX_ARG1=$1
	DEX_ARG2=$2
	DEX_ARG3=$3
	rm -f $TMP_LOGFILE
	if [ "$DEX_ARG3" == "show_output" ]; then
		$DEX_ARG1
	else
		$DEX_ARG1 > /dev/null 2>> $TMP_LOGFILE
	fi
#	echo -e "DEX_ARG1 [$DEX_ARG1] DEX_ARG2 [$DEX_ARG2] DEX_ARG3 [$DEX_ARG3]"
	if [ $? != 0 ]; then
		if test -f $TMP_LOGFILE; then
			LOGTEXT=`cat $TMP_LOGFILE`
		fi
		echo "$LOGTEXT" >> $LOGFILE
		if [ "$DEX_ARG2" != "no_exit" ]; then
			if [ "$LOGTEXT" != "" ]; then
				echo -e "\033[31;1mERROR:\t\033[0m $LOGTEXT"
			fi
			exit 1
		else
			if [ "$LOGTEXT" != "" ]; then
				echo -e "\033[37;1mNOTE:\t\033[0m $LOGTEXT"
 			fi
		fi
	fi
# 	if [ $DEX_ARG2 == "no_exit" ]; then
# 		echo -e "\033[32;1mOK:\033[0m `cat $LOGFILE`"
# 	fi
}

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


function get_metaname () {
	TMP_NAME=$1

	if [ "$TMP_NAME" == "hd51" ] || [ "$TMP_NAME" == "bre2ze4k" ] || [ "$TMP_NAME" == "mutant51" ] || [ "$TMP_NAME" == "ax51" ]; then
		META_NAME="gfutures"
	elif [ "$TMP_NAME" == "h7" ] || [ "$TMP_NAME" == "zgemmah7" ]; then
		META_NAME="airdigital"
	elif [ "$TMP_NAME" == "hd60" ] || [ "$TMP_NAME" == "hd61" ]; then
		META_NAME="hisilicon"
	elif [ "$TMP_NAME" == "osmio4k" ] || [ "$TMP_NAME" == "osmio4kplus" ]; then
		META_NAME="edision"
	else
		META_NAME=$TMP_NAME
	fi
	echo "$META_NAME"
}


# clone or update required branch for required meta-<layer>
function clone_meta () {

	LAYER_NAME=$1
	BRANCH_NAME=$2
	LAYER_GIT_URL=$3
	BRANCH_HASH=$4
	TARGET_GIT_PATH=$5
	PATCH_LIST=$6
	
	#echo -e "Parameters= $LAYER_NAME $BRANCH_NAME $LAYER_GIT_URL $BRANCH_HASH $TARGET_GIT_PATH $PATCH_LIST"

	TMP_LAYER_BRANCH=$BRANCH_NAME

	if test ! -d $TARGET_GIT_PATH/.git; then
		echo -e "\033[35;1mclone branch $BRANCH_NAME from $LAYER_GIT_URL into $TARGET_GIT_PATH\033[0m"
		do_exec "git clone -b $BRANCH_NAME $LAYER_GIT_URL $TARGET_GIT_PATH" ' ' 'show_output'
		do_exec "git -C $TARGET_GIT_PATH checkout $BRANCH_HASH -b $IMAGE_VERSION"
		do_exec "git -C $TARGET_GIT_PATH pull -r origin $BRANCH_NAME" ' ' 'show_output'
		echo -e "\033[35;1mpatching $TARGET_GIT_PATH.\033[0m"
		for PF in  $PATCH_LIST ; do
			PATCH_FILE="$FILES_DIR/$PF"
			echo -e "apply: $PATCH_FILE"
			do_exec "git -C $TARGET_GIT_PATH am $PATCH_FILE" ' ' 'show_output'
		done
	else
		TMP_LAYER_BRANCH=`git -C $TARGET_GIT_PATH rev-parse --abbrev-ref HEAD`
		echo -e "\033[35;1mupdate $TARGET_GIT_PATH $TMP_LAYER_BRANCH\033[0m"
		do_exec "git -C $TARGET_GIT_PATH stash" 'no_exit'

		if [ "$TMP_LAYER_BRANCH" != "$BRANCH_NAME" ]; then
			echo -e "switch from branch $TMP_LAYER_BRANCH to branch $BRANCH_NAME..."
			do_exec "git -C $TARGET_GIT_PATH checkout  $BRANCH_NAME"
		fi

		#echo -e "\033[35;1mUPDATE:\033[0m\nupdate $LAYER_NAME from (branch $BRANCH_NAME) $LAYER_GIT_URL ..."
		do_exec "git -C $TARGET_GIT_PATH pull -r origin $BRANCH_NAME" ' ' 'show_output'

		if [ "$TMP_LAYER_BRANCH" != "$BRANCH_NAME" ]; then
			echo -e "\033[35;1mswitch back to branch $TMP_LAYER_BRANCH\033[0m"
			do_exec "git -C $TARGET_GIT_PATH checkout  $TMP_LAYER_BRANCH"
			echo -e "\033[35;1mrebase branch $BRANCH_NAME into branch $TMP_LAYER_BRANCH\033[0m"
			do_exec "git -C $TARGET_GIT_PATH rebase  $BRANCH_NAME" ' ' 'show_output'
		fi

		do_exec "git -C $TARGET_GIT_PATH stash pop" 'no_exit'
	fi

	return 0
}

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


# clone/update required branch from tuxbox bsp layers
function is_required_machine_layer ()
{
	HIM1=$1
	for M in $HIM1 ; do
		if [ "$M" == "$MACHINE" ]; then
			echo true
			return 1
		fi
	done
	echo false
	return 0
}

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


# create included config file from sample file
if test ! -f $BASEPATH/local.conf.common.inc; then
	echo -e "\033[37;1mCONFIG:\033[0m\tcreate $BASEPATH/local.conf.common.inc as include file for layer configuration ..."
	do_exec "cp -v $BASEPATH/local.conf.common.inc.sample $BASEPATH/local.conf.common.inc"
else
	echo -e "\033[37;1mNOTE:\tLocal configuration not considered\033[0m"
	echo -e "\t##########################################################################################"
	echo -e "\t# $BASEPATH/local.conf.common.inc already exists.				         #"
	echo -e "\t# Nothing was changed on this file for your configuration.				 #"
	echo -e "\t# Possible changes at sample configuration will be ignored.				 #"
	echo -e "\t# You should check local configuration and modify your configuration if required.	 #"
	echo -e "\t# \033[37;1m$BASEPATH/local.conf.common.inc\033[0m                                    	         #"
	echo -e "\t##########################################################################################"
fi

# get matching machine type from machine build id
function get_real_machine_type() {
	MACHINE_TYPE=$1
	if  [ "$MACHINE_TYPE" == "mutant51" ] || [ "$MACHINE_TYPE" == "ax51" ] || [ "$MACHINE_TYPE" == "hd51" ]; then
		RMT_RES="hd51"
	elif  [ "$MACHINE_TYPE" == "zgemmah7" ] || [ "$MACHINE_TYPE" == "h7" ]; then
		RMT_RES="h7"
	else
		RMT_RES=$MACHINE_TYPE
	fi
	echo $RMT_RES
}

# get matching machine build id from machine type
function get_real_machine_id() {
	MACHINEBUILD=$1
	if  [ "$MACHINEBUILD" == "hd51" ]; then
		RMI_RES="ax51"
	elif  [ "$MACHINEBUILD" == "h7" ]; then
		RMI_RES="zgemmah7"
	else
		RMI_RES=$MACHINEBUILD
	fi
	echo $RMI_RES
}

# function to create configuration for box types
function create_local_config () {
	CLC_ARG1=$1
	if [ "$CLC_ARG1" != "all" ]; then
		MACHINE_BUILD_DIR=$BUILD_ROOT/$CLC_ARG1
		mkdir -p $BUILD_ROOT

		if test -d $BUILD_ROOT_DIR/$CLC_ARG1; then
			if test ! -L $BUILD_ROOT_DIR/$CLC_ARG1; then
				# generate build/config symlinks for compatibility
				echo -e "\033[37;1m\tcreate compatible symlinks directory for $CLC_ARG1 environment ...\033[0m"
				mv $BUILD_ROOT_DIR/$CLC_ARG1 $BUILD_ROOT
				ln -s $MACHINE_BUILD_DIR $BUILD_ROOT_DIR/$CLC_ARG1
			fi
		else
			# generate default config
			if test ! -d $MACHINE_BUILD_DIR/conf; then
				echo -e "\033[37;1m\tcreate build directory for $CLC_ARG1 environment ...\033[0m"
				do_exec "cd $BUILD_ROOT_DIR"
				do_exec ". ./oe-init-build-env $MACHINE_BUILD_DIR"
				do_exec "cd $BASEPATH"
			fi
		fi

		# move config files into conf directory
		if test -f $BASEPATH/local.conf.common.inc; then
			LOCAL_CONFIG_FILE_PATH=$MACHINE_BUILD_DIR/conf/local.conf
			if test ! -f $LOCAL_CONFIG_FILE_PATH.$BACKUP_SUFFIX || test ! -f $LOCAL_CONFIG_FILE_PATH; then
				echo -e "\tcreate configuration for $CLC_ARG1 ... "
				if test -f $LOCAL_CONFIG_FILE_PATH; then
					do_exec "mv -v $LOCAL_CONFIG_FILE_PATH $LOCAL_CONFIG_FILE_PATH.$BACKUP_SUFFIX"
				fi
				# add line 1, include for local.conf.common.inc
				echo "include $BASEPATH/local.conf.common.inc" > $LOCAL_CONFIG_FILE_PATH

				# add line 2
				M_TYPE='MACHINE = "'`get_real_machine_type $CLC_ARG1`'"'
				echo $M_TYPE >> $LOCAL_CONFIG_FILE_PATH

				# add line 3
				M_ID='MACHINEBUILD = "'`get_real_machine_id $CLC_ARG1`'"'
				echo $M_ID >> $LOCAL_CONFIG_FILE_PATH
			fi
		else
			echo -e "\033[31;1mERROR:\033[0m:\ttemplate $BASEPATH/local.conf.common.inc not found..."
			exit 1
		fi

		if test ! -f $MACHINE_BUILD_DIR/conf/bblayers.conf.$BACKUP_SUFFIX; then
			echo -e "\tcreate bblayer configuration for $CLC_ARG1..."
			do_exec "cp -v $MACHINE_BUILD_DIR/conf/bblayers.conf $MACHINE_BUILD_DIR/conf/bblayers.conf.$BACKUP_SUFFIX"
			META_MACHINE_LAYER=meta-`get_metaname $CLC_ARG1`
			echo 'BBLAYERS += " \
			'$BUILD_ROOT_DIR'/'$TUXBOX_LAYER_NAME' \
			'$BUILD_ROOT_DIR'/'$META_MACHINE_LAYER' \
			'$BUILD_ROOT_DIR'/'$OE_LAYER_NAME/meta-oe' \
			'$BUILD_ROOT_DIR'/'$OE_LAYER_NAME/meta-networking' \
			"' >> $MACHINE_BUILD_DIR/conf/bblayers.conf
			if test -d $BUILD_ROOT_DIR/$META_MACHINE_LAYER/recipes-kodi; then
				echo 'BBLAYERS += " \
				'$BUILD_ROOT_DIR'/'$PYTHON2_LAYER_NAME' \
				"' >> $MACHINE_BUILD_DIR/conf/bblayers.conf
			fi
			if test -d $BUILD_ROOT_DIR/$META_MACHINE_LAYER/recipes-qt; then
				echo 'BBLAYERS += " \
				'$BUILD_ROOT_DIR'/'$QT5_LAYER_NAME' \
				"' >> $MACHINE_BUILD_DIR/conf/bblayers.conf
			fi
		fi
	fi
}

# function create local dist directory to prepare for web access
function create_dist_tree () {

	# create dist dir
	DIST_BASEDIR="$BASEPATH/dist/$IMAGE_VERSION"
	if test ! -d "$DIST_BASEDIR"; then
		echo -e "\033[37;1mcreate dist directory:\033[0m   $DIST_BASEDIR"
		do_exec "mkdir -p $DIST_BASEDIR"
	fi

	# create link sources
	DIST_LIST=`ls $BUILD_ROOT`
	for DL in  $DIST_LIST ; do
		DEPLOY_DIR="$BUILD_ROOT/$DL/tmp/deploy"
		ln -sf $DEPLOY_DIR $DIST_BASEDIR/$DL
		if test -L "$DIST_BASEDIR/$DL/deploy"; then
			unlink $DIST_BASEDIR/$DL/deploy
		fi
	done
}

# create configuration for machine
if [ "$MACHINE" == "all" ]; then
	for M in  $MACHINES ; do
		create_local_config $M;
	done
else
	create_local_config $MACHINE;
fi

create_dist_tree;

# check and create distribution directory inside html directory for online update
if test ! -L /var/www/html/dist; then
	echo -e "\033[37;1mNOTE:\t Online update usage.\033[0m"
	echo -e "\t##########################################################################################"
	echo -e "\t# /var/www/html/dist doesn't exists.                                                     #"
	echo -e "\t# If you want to use online update, please configure your webserver and use dist content #"
	echo -e "\t# Super user permissions are required to create symlink...                               #"
	echo -e "\t# An easy way is to create a symlink to dist directory:                                  #"
	echo -e "\t# \033[37;1msudo ln -s $BASEPATH/dist /var/www/html/dist\033[0m                                    #"
	echo -e "\t########################################################################################## "
fi

echo -e "\033[32;1mDONE!\033[0m"
exit 0
