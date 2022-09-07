#!/bin/bash

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

# function to create file enrties into a file, already existing entry will be ignored
function set_file_entry () {
	FILE_NAME=$1
	FILE_SEARCH_ENTRY=$2
	FILE_NEW_ENTRY=$3
	if test ! -f $FILE_NAME; then
		echo $FILE_NEW_ENTRY > $FILE_NAME
	else
		HAS_ENTRY=`grep -c -w $FILE_SEARCH_ENTRY $FILE_NAME`
		if [ "$HAS_ENTRY" == "0" ] ; then
			echo $FILE_NEW_ENTRY >> $FILE_NAME
		fi
	fi
}

# function to create configuration for box types
function create_local_config () {
	CLC_ARG1=$1

	if [ "$CLC_ARG1" != "all" ]; then

		MACHINE_BUILD_DIR=$BUILD_ROOT/$CLC_ARG1
		mkdir -p $BUILD_ROOT

		BACKUP_CONFIG_DIR="$BACKUP_PATH/$CLC_ARG1/conf"
		mkdir -p $BACKUP_CONFIG_DIR

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

			echo -e "\tmodify $LOCAL_CONFIG_FILE_PATH for $CLC_ARG1 ... "

			if test -f $LOCAL_CONFIG_FILE_PATH; then
				do_exec "cp -v $LOCAL_CONFIG_FILE_PATH $BACKUP_CONFIG_DIR/local.conf.$TIMESTAMP.$BACKUP_SUFFIX"
			fi

			set_file_entry $LOCAL_CONFIG_FILE_PATH "generated" "# auto generated entries by init script"

			# add line 1, include for local.conf.common.inc
			set_file_entry $LOCAL_CONFIG_FILE_PATH "$BASEPATH/local.conf.common.inc" "include $BASEPATH/local.conf.common.inc"

			# add line 2, machine type
			M_TYPE='MACHINE = "'`get_real_machine_type $CLC_ARG1`'"'
			set_file_entry $LOCAL_CONFIG_FILE_PATH "MACHINE" "$M_TYPE"

			# add line 3, machine build
			M_ID='MACHINEBUILD = "'`get_real_machine_id $CLC_ARG1`'"'
			set_file_entry $LOCAL_CONFIG_FILE_PATH "MACHINEBUILD" "$M_ID"
		else
			echo -e "\033[31;1mERROR:\033[0m:\ttemplate $BASEPATH/local.conf.common.inc not found..."
			exit 1
		fi

		BBLAYER_CONF_FILE="$MACHINE_BUILD_DIR/conf/bblayers.conf"
		echo -e "\tmodify $BBLAYER_CONF_FILE for $CLC_ARG1..."

		# craete backup for bblayer.conf
		if test -f $BBLAYER_CONF_FILE; then
			do_exec "cp -v $BBLAYER_CONF_FILE $BACKUP_CONFIG_DIR/bblayer.conf.$TIMESTAMP.$BACKUP_SUFFIX"
		fi

		META_MACHINE_LAYER=meta-`get_metaname $CLC_ARG1`

		# add layer entries into bblayer.conf
		set_file_entry $BBLAYER_CONF_FILE "generated" '# auto generated entries by init script'
		LAYER_LIST=" $TUXBOX_LAYER_NAME $META_MACHINE_LAYER $OE_LAYER_NAME/meta-oe $OE_LAYER_NAME/meta-networking $PYTHON2_LAYER_NAME $QT5_LAYER_NAME "
		for LL in $LAYER_LIST ; do
			set_file_entry $BBLAYER_CONF_FILE $LL 'BBLAYERS += " '$BUILD_ROOT_DIR'/'$LL' "'
		done
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
