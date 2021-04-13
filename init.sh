#!/bin/bash

#set -x

BASEPATH=`pwd`
FILES_DIR=$BASEPATH/files
MACHINES="h7 hd51 hd60 hd61 osmio4k osmio4kplus"
HINT_SYNTAX='Usage '$0' <machine> <image-version>'
HINT_MACHINES="<$MACHINES all>"
HINT_IMAGE_VERSIONS='<3.2> <3.1> <3.0>'
 
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
if [ "$1" = "" ]; then
	MACHINE="all"
else
	MACHINE=$1
fi

if [ "$2" = "" ]; then
	IMAGE_VERSION="3.2"
else
	IMAGE_VERSION=$2
fi

# check for empty machine
if [ -z "$MACHINE" ]; then
    echo -e "\033[31;1mERROR:\tNo machine defined. Possible machines are $HINT_MACHINES. $HINT_SYNTAX ...\033[0m"
    exit 1
fi

# check for valid machine
if [ "$MACHINE" != "hd51" ] && [ "$MACHINE" != "h7" ] && [ "$MACHINE" != "hd60" ] && [ "$MACHINE" != "hd61" ] && [ "$MACHINE" != "osmio4k" ] && [ "$MACHINE" != "osmio4kplus" ] && [ "$MACHINE" != "all" ]; then
    echo -e "\033[31;1mERROR:\tInvalid machine defined. $HINT_SYNTAX. Possible machines are $HINT_MACHINES\033[0m"
    exit 1
fi

# check for image versions
if [ "$IMAGE_VERSION" != "3.2" ] && [ "$IMAGE_VERSION" != "3.1" ] && [ "$IMAGE_VERSION" != "3.0" ]; then
    echo -e "\033[31;1mERROR:\tInvalid image version defined. $HINT_SYNTAX. Possible image versions are $HINT_IMAGE_VERSIONS, keep empty for current version\033[0m"
    exit 1    
fi

echo -e "\033[37;1mNOTE:\tInitialze build environment for image version $IMAGE_VERSION and machine: $MACHINE \033[0m\n"

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
		LOGTEXT=`cat $TMP_LOGFILE`
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

POKY_NAME=poky-$IMAGE_VERSION
BUILD_ROOT_DIR=$BASEPATH/$POKY_NAME
GUI_LAYER_NAME=meta-neutrino
BACKUP_SUFFIX=bak

YOCTO_GIT_URL=https://git.yoctoproject.org/git/poky
# update of yocto layer is disabled on executing init script, for yocto oe it's better to use a tested tag, defined with $YOCTO_BRANCH_HASH
YOCTO_LAYER_DO_UPDATE=0

TUXBOX_LAYER_GIT_URL=https://github.com/neutrino-hd

PYTHON2_LAYER_NAME=meta-python2
PYTHON2_LAYER_GIT_URL=https://git.openembedded.org
PYTHON2_LAYER_DO_UPDATE=1

QT5_LAYER_NAME=meta-qt5
QT5_LAYER_GIT_URL=https://github.com/meta-qt5
QT5_LAYER_DO_UPDATE=1

GIT_CLONE='git clone'
GIT_PULL='git pull -r'
GIT_STASH='git stash'
GIT_STASH_POP='git stash pop'


# set required branch
YOCTO_BRANCH_NAME=""
if [ "$IMAGE_VERSION" = "3.0" ]; then
	YOCTO_BRANCH_NAME=zeus
	YOCTO_BRANCH_HASH=d88d62c
elif [ "$IMAGE_VERSION" = "3.1" ]; then
	YOCTO_BRANCH_NAME=dunfell
	YOCTO_BRANCH_HASH=2181825
elif [ "$IMAGE_VERSION" = "3.2" ]; then
	YOCTO_BRANCH_NAME=gatesgarth
	YOCTO_BRANCH_HASH=4e4a302
	PYTHON2_BRANCH_HASH=27d2aeb
fi

# clone required branch from yocto
if test ! -d $BUILD_ROOT_DIR/.git; then
	echo -e "\033[36;1mCLONE POKY:\033[0m\nclone branch $YOCTO_BRANCH_NAME from $YOCTO_GIT_URL into $BUILD_ROOT_DIR..."
	do_exec "$GIT_CLONE -b $YOCTO_BRANCH_NAME $YOCTO_GIT_URL $POKY_NAME" ' ' 'show_output'
	do_exec "cd $BUILD_ROOT_DIR"
	do_exec "git checkout $YOCTO_BRANCH_HASH -b $IMAGE_VERSION"
	do_exec "git tag $IMAGE_VERSION"
	if [ $YOCTO_LAYER_DO_UPDATE != 0 ]; then
		do_exec "$GIT_PULL origin $YOCTO_BRANCH_NAME" ' ' 'show_output'
	fi
	echo -e "\033[36;1mdone ...\033[0m\n"
else
	if [ $YOCTO_LAYER_DO_UPDATE != 0 ]; then
		do_exec "cd $BUILD_ROOT_DIR"
		CURRENT_YOCTO_BRANCH=`git -C $BUILD_ROOT_DIR rev-parse --abbrev-ref HEAD`

		echo -e "\033[36;1mUPDATE poky:\033[0m\nupdate $CURRENT_YOCTO_BRANCH..."

		echo -e "\033[37;1mCHECKOUT:\033[0m\nswitch from $CURRENT_YOCTO_BRANCH to $IMAGE_VERSION..."
		do_exec "git checkout $IMAGE_VERSION"

		echo -e "\033[37;1mUPDATE:\033[0m\nupdate $POKY_NAME from (branch $YOCTO_BRANCH_NAME) $YOCTO_GIT_URL ..."
		do_exec "$GIT_PULL origin $YOCTO_BRANCH_NAME" ' ' 'show_output'

		echo -e "\033[37;1mCHECKOUT:\033[0m\nswitch back to $YOCTO_BRANCH_NAME ..."
		do_exec "git checkout $YOCTO_BRANCH_NAME"
		do_exec "$GIT_PULL origin $YOCTO_BRANCH_NAME" ' ' 'show_output'

		echo -e "\033[37;1mCHECKOUT:\033[0m\nswitch back to $IMAGE_VERSION ..."
		do_exec "git checkout $IMAGE_VERSION"

		echo -e "\033[36;1mdone ...\033[0m\n"
	else
		echo -e "\033[36;1mupdate of yocto poky is disabled... keeping $YOCTO_BRANCH_NAME at $YOCTO_BRANCH_HASH\033[0m\n"
	fi
fi


# clone or update required branch from gui meta layer
if test ! -d $BUILD_ROOT_DIR/$GUI_LAYER_NAME/.git; then
	echo -e "\033[33;1mCLONE $GUI_LAYER_NAME:\033[0m\nclone $GUI_LAYER_NAME (branch $YOCTO_BRANCH_NAME) from $TUXBOX_LAYER_GIT_URL ..."
	do_exec "cd $BUILD_ROOT_DIR"
	do_exec "$GIT_CLONE -b $YOCTO_BRANCH_NAME $TUXBOX_LAYER_GIT_URL/$GUI_LAYER_NAME.git $GUI_LAYER_NAME" ' ' 'show_output'
	echo -e "\033[33;1mdone ...\033[0m\n"
else
	do_exec "cd $BUILD_ROOT_DIR/$GUI_LAYER_NAME"
	CURRENT_GUI_LAYER_BRANCH=`git -C $BUILD_ROOT_DIR/$GUI_LAYER_NAME rev-parse --abbrev-ref HEAD`
	echo -e "\033[33;1mUPDATE: update $GUI_LAYER_NAME $CURRENT_GUI_LAYER_BRANCH\033[0m"
	do_exec "$GIT_STASH" 'no_exit'

	if [ "$CURRENT_GUI_LAYER_BRANCH" != "$YOCTO_BRANCH_NAME" ]; then
		echo -e "\033[37;1mCHECKOUT:\033[0m\nswitch from $CURRENT_GUI_LAYER_BRANCH to $YOCTO_BRANCH_NAME..."
		do_exec "git checkout  $YOCTO_BRANCH_NAME"
	fi

	echo -e "\033[37;1mUPDATE:\033[0m\nupdate $GUI_LAYER_NAME from (branch $YOCTO_BRANCH_NAME) $TUXBOX_LAYER_GIT_URL ..."
	do_exec "$GIT_PULL origin $YOCTO_BRANCH_NAME" ' ' 'show_output'

	if [ "$CURRENT_GUI_LAYER_BRANCH" != "$YOCTO_BRANCH_NAME" ]; then
		echo -e "\033[37;1mCHECKOUT:\033[0m\nswitch back to $CURRENT_GUI_LAYER_BRANCH ..."
		do_exec "git checkout  $CURRENT_GUI_LAYER_BRANCH"
		echo -e "\033[37;1mREBASE:\033[0m\nrebase branch $YOCTO_BRANCH_NAME into $CURRENT_GUI_LAYER_BRANCH"
		do_exec "git rebase  $YOCTO_BRANCH_NAME" ' ' 'show_output'
	fi

	do_exec "$GIT_STASH_POP" 'no_exit'
	echo -e "\033[33;1mdone ...\033[0m\n"
fi


# clone or update required branch for python2 from https://git.openembedded.org/meta-python2
function clone_meta_python2 () {
	META_MACHINE_LAYER=meta-$1

	if [ $PYTHON2_LAYER_DO_UPDATE == "1" ] && [ "$IMAGE_VERSION" != "3.0" ] && [ "$IMAGE_VERSION" != "3.1" ] && test -d $BUILD_ROOT_DIR/$META_MACHINE_LAYER/recipes-multimedia/kodi; then

		$CURRENT_PYTHON_LAYER_BRANCH

		if test ! -d $BUILD_ROOT_DIR/$PYTHON2_LAYER_NAME/.git; then
			echo -e "\033[35;1mCLONE $PYTHON2_LAYER_NAME:\033[0m\nclone $PYTHON2_LAYER_NAME (branch $YOCTO_BRANCH_NAME) from $PYTHON2_LAYER_GIT_URL ..."
			do_exec "cd $BUILD_ROOT_DIR"
			do_exec "$GIT_CLONE -b $YOCTO_BRANCH_NAME $PYTHON2_LAYER_GIT_URL/$PYTHON2_LAYER_NAME $PYTHON2_LAYER_NAME" ' ' 'show_output'
			do_exec "git -C $BUILD_ROOT_DIR/$PYTHON2_LAYER_NAME checkout $PYTHON2_BRANCH_HASH -b $IMAGE_VERSION"
			do_exec "git -C $BUILD_ROOT_DIR/$PYTHON2_LAYER_NAME am $FILES_DIR/0001-local_conf_outcomment_line_15.patch" ' ' 'show_output'
			do_exec "$GIT_PULL origin $YOCTO_BRANCH_NAME" ' ' 'show_output'
			echo -e "\033[35;1mdone ...\033[0m\n"
		else
			do_exec "cd $BUILD_ROOT_DIR/$PYTHON2_LAYER_NAME"
			CURRENT_PYTHON_LAYER_BRANCH=`git -C $BUILD_ROOT_DIR/$PYTHON2_LAYER_NAME rev-parse --abbrev-ref HEAD`
			echo -e "\033[35;1mUPDATE: update $PYTHON2_LAYER_NAME $CURRENT_PYTHON_LAYER_BRANCH\033[0m"
			do_exec "$GIT_STASH" 'no_exit'

			if [ "$CURRENT_PYTHON_LAYER_BRANCH" != "$YOCTO_BRANCH_NAME" ]; then
				echo -e "\033[35;1mCHECKOUT:\033[0m\nswitch from $CURRENT_PYTHON_LAYER_BRANCH to $YOCTO_BRANCH_NAME..."
				do_exec "git checkout  $YOCTO_BRANCH_NAME"
			fi

			#echo -e "\033[35;1mUPDATE:\033[0m\nupdate $PYTHON2_LAYER_NAME from (branch $YOCTO_BRANCH_NAME) $PYTHON2_LAYER_GIT_URL ..."
			do_exec "$GIT_PULL origin $YOCTO_BRANCH_NAME" ' ' 'show_output'

			if [ "$CURRENT_PYTHON_LAYER_BRANCH" != "$YOCTO_BRANCH_NAME" ]; then
				echo -e "\033[35;1mCHECKOUT:\033[0m\nswitch back to $CURRENT_PYTHON_LAYER_BRANCH ..."
				do_exec "git checkout  $CURRENT_PYTHON_LAYER_BRANCH"
				echo -e "\033[35;1mREBASE:\033[0m\nrebase branch $YOCTO_BRANCH_NAME into $CURRENT_PYTHON_LAYER_BRANCH"
				do_exec "git rebase  $YOCTO_BRANCH_NAME" ' ' 'show_output'
			fi

			do_exec "$GIT_STASH_POP" 'no_exit'
			echo -e "\033[35;1mdone ...\033[0m\n"
			PYTHON2_LAYER_DO_UPDATE=0
		fi
	fi
}

# clone or update required branch for qt5
function clone_meta_qt5 () {
	META_MACHINE_LAYER=meta-$1

	if [ $QT5_LAYER_DO_UPDATE == "1" ] && [ "$IMAGE_VERSION" != "3.0" ] && [ "$IMAGE_VERSION" != "3.1" ] && test -d $BUILD_ROOT_DIR/$META_MACHINE_LAYER/recipes-multimedia/kodi; then

		$CURRENT_QT_LAYER_BRANCH

		if test ! -d $BUILD_ROOT_DIR/$QT5_LAYER_NAME/.git; then
			echo -e "\033[35;1mCLONE $QT5_LAYER_NAME:\033[0m\nclone $QT5_LAYER_NAME (branch $YOCTO_BRANCH_NAME) from $QT5_LAYER_GIT_URL ..."
			do_exec "cd $BUILD_ROOT_DIR"
			do_exec "$GIT_CLONE -b $YOCTO_BRANCH_NAME $QT5_LAYER_GIT_URL/$QT5_LAYER_NAME $QT5_LAYER_NAME" ' ' 'show_output'
			do_exec "git -C $BUILD_ROOT_DIR/$QT5_LAYER_NAME checkout $QT5_BRANCH_HASH -b $IMAGE_VERSION"
			do_exec "$GIT_PULL origin $YOCTO_BRANCH_NAME" ' ' 'show_output'
			echo -e "\033[35;1mdone ...\033[0m\n"
		else
			do_exec "cd $BUILD_ROOT_DIR/$QT5_LAYER_NAME"
			CURRENT_QT_LAYER_BRANCH=`git -C $BUILD_ROOT_DIR/$QT5_LAYER_NAME rev-parse --abbrev-ref HEAD`
			echo -e "\033[35;1mUPDATE: update $QT5_LAYER_NAME $CURRENT_QT_LAYER_BRANCH\033[0m"
			do_exec "$GIT_STASH" 'no_exit'

			if [ "$CURRENT_QT_LAYER_BRANCH" != "$YOCTO_BRANCH_NAME" ]; then
				echo -e "\033[35;1mCHECKOUT:\033[0m\nswitch from $CURRENT_QT_LAYER_BRANCH to $YOCTO_BRANCH_NAME..."
				do_exec "git checkout  $YOCTO_BRANCH_NAME"
			fi

			#echo -e "\033[35;1mUPDATE:\033[0m\nupdate $QT5_LAYER_NAME from (branch $YOCTO_BRANCH_NAME) $QT5_LAYER_GIT_URL ..."
			do_exec "$GIT_PULL origin $YOCTO_BRANCH_NAME" ' ' 'show_output'

			if [ "$CURRENT_QT_LAYER_BRANCH" != "$YOCTO_BRANCH_NAME" ]; then
				echo -e "\033[35;1mCHECKOUT:\033[0m\nswitch back to $CURRENT_QT_LAYER_BRANCH ..."
				do_exec "git checkout  $CURRENT_QT_LAYER_BRANCH"
				echo -e "\033[35;1mREBASE:\033[0m\nrebase branch $YOCTO_BRANCH_NAME into $CURRENT_QT_LAYER_BRANCH"
				do_exec "git rebase  $YOCTO_BRANCH_NAME" ' ' 'show_output'
			fi

			do_exec "$GIT_STASH_POP" 'no_exit'
			echo -e "\033[35;1mdone ...\033[0m\n"
			QT5_LAYER_DO_UPDATE=0
		fi
	fi
}

function get_metaname () {
	TMP_NAME=$1

	if [ "$TMP_NAME" == "hd51" ]; then
		META_NAME="hd51"
	elif [ "$TMP_NAME" == "h7" ]; then
		META_NAME="zgemma"
	elif [ "$TMP_NAME" == "hd60" ] || [ "$TMP_NAME" == "hd61" ]; then
		META_NAME="hisilicon"
	elif [ "$TMP_NAME" == "osmio4k" ] || [ "$TMP_NAME" == "osmio4kplus" ]; then
		META_NAME="edision"
	else
		META_NAME=$TMP_NAME
	fi
	echo "$META_NAME"
}

# function for clone or update required branch(es) from machine meta layer
function clone_box_layer () {
	NAME=`get_metaname $1`
	
	if [ "$NAME" != "all" ]; then
		if test ! -d $BUILD_ROOT_DIR/meta-$NAME/.git; then
			echo -e "\033[34;1mCLONE: clone meta-$NAME (branch $YOCTO_BRANCH_NAME) from $TUXBOX_LAYER_GIT_URL ...\033[0m"
			do_exec "cd $BUILD_ROOT_DIR"
			do_exec "$GIT_CLONE -b $YOCTO_BRANCH_NAME $TUXBOX_LAYER_GIT_URL/meta-$NAME.git" ' ' 'show_output'
			echo -e "\033[34;1mdone ...\033[0m\n"

			if test ! -d $BUILD_ROOT_DIR/$PYTHON2_LAYER_NAME; then
				clone_meta_python2 $NAME
			fi

			if test ! -d $BUILD_ROOT_DIR/$QT5_LAYER_NAME; then
				clone_meta_qt5 $NAME
			fi
		else
			do_exec "cd $BUILD_ROOT_DIR/meta-$NAME"
			do_exec "$GIT_STASH" 'no_exit'

			CURRENT_MACHINE_LAYER_BRANCH=`git -C $BUILD_ROOT_DIR/meta-$NAME rev-parse --abbrev-ref HEAD`
			if [ "$CURRENT_MACHINE_LAYER_BRANCH" != "$YOCTO_BRANCH_NAME" ]; then
				echo -e "\033[37;1mCHECKOUT:\033[0m\nswitch from $CURRENT_MACHINE_LAYER_BRANCH to $YOCTO_BRANCH_NAME..."
				do_exec "git checkout  $YOCTO_BRANCH_NAME"
			fi

			echo -e "\033[34;1mUPDATE: update meta-$NAME (branch $YOCTO_BRANCH_NAME) from $TUXBOX_LAYER_GIT_URL ...\033[0m"
			do_exec "$GIT_PULL origin $YOCTO_BRANCH_NAME" ' ' 'show_output'

			if [ "$CURRENT_MACHINE_LAYER_BRANCH" != "$YOCTO_BRANCH_NAME" ]; then
				echo -e "\033[37;1mCHECKOUT:\033[0m\nswitch back  to $CURRENT_MACHINE_LAYER_BRANCH ..."
				do_exec "git checkout  $CURRENT_MACHINE_LAYER_BRANCH"
				echo -e "\033[37;1mREBASE:\033[0m\nrebase branch $YOCTO_BRANCH_NAME into $CURRENT_MACHINE_LAYER_BRANCH"
				do_exec "git rebase  $YOCTO_BRANCH_NAME" ' ' 'show_output'
			fi

			do_exec "$GIT_STASH_POP" 'no_exit'
			echo -e "\033[34;1mdone ...\033[0m\n"

			clone_meta_python2 $NAME
		fi
	fi
}

# clone or update meta layers
if [ "$MACHINE" == "all" ]; then
	for M in  $MACHINES ; do
		clone_box_layer $M;
	done
else
	clone_box_layer $MACHINE;
fi


# create included config file from sample file
if test ! -f $BASEPATH/local.conf.common.inc; then
	echo -e "\033[37;1mCONFIG:\033[0m\tcreate $BASEPATH/local.conf.common.inc as include file for layer configuration ..."
	do_exec "cp -v $BASEPATH/local.conf.common.inc.sample $BASEPATH/local.conf.common.inc"
else
	echo -e "\033[37;1mNOTE:\t Local configuration not considered\033[0m"
	echo -e "\t##########################################################################################"
	echo -e "\t# $BASEPATH/local.conf.common.inc already exists.				 #"
	echo -e "\t# Nothing was changed on this file for your configuration.				 #"
	echo -e "\t# Possible changes at sample configuration will be ignored.				 #"
	echo -e "\t# You should check local configuration and modify your configuration if required.	 #"
	echo -e "\t# \033[37;1m$BASEPATH/local.conf.common.inc\033[0m						 #"
	echo -e "\t##########################################################################################"
fi


# function to create configuration for box types
function create_local_config () {
	CLC_ARG1=$1
	if [ "$CLC_ARG1" != "all" ]; then
		BOX_BUILD_DIR=$BUILD_ROOT_DIR/$CLC_ARG1

		# generate default config
		if test ! -d $BOX_BUILD_DIR/conf; then
			echo -e "\033[37;1m\tcreate directory for $CLC_ARG1 environment ...\033[0m"
			do_exec "cd $BUILD_ROOT_DIR"
			do_exec ". ./oe-init-build-env $CLC_ARG1"
			do_exec "cd $BASEPATH"
		fi

		# move config files into conf directory
		if test -f $BASEPATH/local.conf.common.inc; then
			if test ! -f $BOX_BUILD_DIR/conf/local.conf.$BACKUP_SUFFIX; then
				echo -e "\tset base configuration for $CLC_ARG1 ... "
				do_exec "mv -v $BOX_BUILD_DIR/conf/local.conf $BOX_BUILD_DIR/conf/local.conf.$BACKUP_SUFFIX"
				echo 'MACHINE ?= "'$CLC_ARG1'"' > $BOX_BUILD_DIR/conf/local.conf
				echo "include $BASEPATH/local.conf.common.inc" >> $BOX_BUILD_DIR/conf/local.conf
			fi
		else
			echo -e "\033[31;1mERROR:\033[0m:\ttemplate $BASEPATH/local.conf.common.inc not found..."
			exit 1
		fi

		if test ! -f $BOX_BUILD_DIR/conf/bblayers.conf.$BACKUP_SUFFIX; then
			echo -e "\033[37;1m\tset base bblayer configuration for $CLC_ARG1...\033[0m"
			do_exec "cp -v $BOX_BUILD_DIR/conf/bblayers.conf $BOX_BUILD_DIR/conf/bblayers.conf.$BACKUP_SUFFIX"
			META_MACHINE_LAYER=meta-`get_metaname $CLC_ARG1`
			echo 'BBLAYERS += " \
			'$BUILD_ROOT_DIR'/meta-neutrino \
			'$BUILD_ROOT_DIR'/'$META_MACHINE_LAYER' \
			"' >> $BOX_BUILD_DIR/conf/bblayers.conf
			if test -d $BUILD_ROOT_DIR/$META_MACHINE_LAYER/recipes-multimedia/kodi; then
				echo 'BBLAYERS += " \
				'$BUILD_ROOT_DIR'/'$PYTHON2_LAYER_NAME' \
				"' >> $BOX_BUILD_DIR/conf/bblayers.conf
			fi
			if test -d $BUILD_ROOT_DIR/$QT5_LAYER_NAME; then
				echo 'BBLAYERS += " \
				'$BUILD_ROOT_DIR'/'$QT5_LAYER_NAME' \
				"' >> $BOX_BUILD_DIR/conf/bblayers.conf
			fi
		fi
	fi
}

# function create local dist directory to prepare for web access
function create_dist_tree () {
	PAR1=$1
	if [ "$PAR1" != "all" ]; then

		DIST_BASEDIR="$BASEPATH/dist/$IMAGE_VERSION"
		DIST_LINK=$DIST_BASEDIR/$PAR1
		DIST_LINK_IMAGES=$DIST_BASEDIR/$PAR1/images
		DIST_LINK_IPK=$DIST_BASEDIR/$PAR1/ipk
		DIST_LINK_LICENSE=$DIST_BASEDIR/$PAR1/licenses

		if test ! -d "$DIST_LINK"; then
			echo -e "\n\033[37;1mcreate directory:\033[0m   $DIST_LINK"
			do_exec "mkdir -p $DIST_LINK"
		fi

		DEPLOY_DIR=$BUILD_ROOT_DIR/$PAR1/tmp/deploy
		DEPLOY_DIR_IMAGES=$DEPLOY_DIR/images/$PAR1
		DEPLOY_DIR_IPK=$DEPLOY_DIR/ipk
		DEPLOY_DIR_LICENSE=$DEPLOY_DIR/licenses

		if test ! -L "$DIST_LINK_IMAGES"; then
			echo -e "\033[37;1mcreate symlink:\033[0m     $DIST_LINK_IMAGES"
			do_exec "ln -sf $DEPLOY_DIR_IMAGES $DIST_LINK_IMAGES"
		fi

		if test ! -L "$DIST_LINK_IPK"; then
			echo -e "\033[37;1mcreate symlink:\033[0m     $DIST_LINK_IPK"
			do_exec "ln -sf $DEPLOY_DIR_IPK $DIST_LINK_IPK"
		fi

		if test ! -L "$DIST_LINK_LICENSE"; then
			echo -e "\033[37;1mcreate symlink:\033[0m     $DIST_LINK_LICENSE"
			do_exec "ln -sf $DEPLOY_DIR_LICENSE $DIST_LINK_LICENSE"
		fi
	fi
}

# create configuration for machine
if [ "$MACHINE" == "all" ]; then
	for M in  $MACHINES ; do
		create_local_config $M;
		create_dist_tree $M;
	done
else
	create_local_config $MACHINE;
	create_dist_tree $MACHINE;
fi

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
