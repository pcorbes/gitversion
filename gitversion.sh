#!/bin/sh
# Git version script for Linux to extract and update source files
# Copyright (c) 2023 Philippe Corbes released under the MIT license


Usage()
{
	echo -e "-------------------------------------------------------------------------------------------"
	echo -e " Usage: gitversion.sh [folder_with_git_repo [inputfile outputfile]]"
	echo -e " example: gitversion.sh c:\my_git_repo version_input.h version.h"
	echo -e " -"
	echo -e " Important note: This expects tags to be in format: Anything else won't work. "
	echo -e " v1.0.123 where 1 is major, 0 is minor and 123 is revision"
	echo -e " -"
	echo -e " Tags replaced in input file:"
	echo -e "    [MAJOR_VERSION]     - the major version number"
	echo -e "    [MINOR_VERSION]     - the minor version number"
	echo -e "    [REVISION]          - the revision number"
	echo -e "    [GIT_TAG_ONLY]      - only the last git tag"
	echo -e "    [GIT_TAG_HASH]      - git hash for the last git tag"
	echo -e "    [COMMITS_SINCE_TAG] - number of commits since last tag"
	echo -e "    [GIT_CURRENT_TAG]   - git current tag"
	echo -e "    [GIT_CURRENT_HASH]  - the current git tag hash"
	echo -e "                          (will be same as GIT_TAG_HASH if the current tag is checked out)"
	echo -e "    [GIT_COMMITS_FLAG]  - Empty or +number_of_commits_since_last_tag"
	echo -e "    [GIT_DIRTY_FLAG]    - Empty or '-dirty' if not synchronized"
}

Finish()
{
	echo "-------------------------------------------------------------------------------------------"
	exit ${exit_code}
}

# verify if the git command is available
if [ "x`whereis git | sed "s,.*: \(.*\) .*,\1,"`x" == "xx" ]; then
	echo "ERROR: No git command found. Please install it first!"
	return 1
fi

# Preprocessing parameters

# Preprocessing parameter 1
if [ "x$1x" == "xx" ]; then
	root_dir=.
else
	root_dir=$1
fi

echo "-------------------------------------------------------------------------------------------"

# verify that .git exists within given directory
if [ -d $root_dir ]; then
	cd $root_dir
	git describe --tags 1>/dev/null
	if [ $? != 0 ]; then
		echo "ERROR: No git repository in given directory!"
		exit_code=1
		Finish
	fi
else
	echo "ERROR: Missing Git repo directory!"
	exit_code=1
	Usage
	Finish
fi

# To get latest abbriviated hash from git
# git log -n 1  --pretty="format:%h"
# To get current tag
# git describe --tags
# git describe --tags --long | sed "s,v\([0-9]*\).*,\1,"
# git describe --tags --long --dirty | sed "s,v\([0-9]*\).*,\1,"

# current_tag 
current_tag=`git describe --tags --long --dirty`
tag_only=`echo ${current_tag} | sed "s,\(v[0-9]*\.[0-9]*\.[0-9]*\)-[0-9]*-g.*,\1,"`
major_version=`echo ${current_tag} | sed "s,v\([0-9]*\).*,\1,"`
minor_version=`echo ${current_tag} | sed "s,v[0-9]*\.\([0-9]*\).*,\1,"`
revision=`echo ${current_tag} | sed "s,v[0-9]*\.[0-9]*\.\([0-9]*\).*,\1,"`
commits_since_tag=`echo ${current_tag} | sed "s,v[0-9]*\.[0-9]*\.[0-9]*-\([0-9]*\).*,\1,"`
git_hash=`echo ${current_tag} | sed "s,v[0-9]*\.[0-9]*\.[0-9]*-[0-9]*-g\([0-9a-f]*\).*,\1,"`
if [ "x$git_hash" == "x" ]; then
	git_hash=" ="
fi
if [ "${commits_since_tag}" == "0" ]; then
	git_commits=
else
	git_commits="+${commits_since_tag}"
fi

# git_tag_complete_with_hash
git_tag_complete_with_hash=`git describe ${tag_only} --tags --long`
git_tag_hash=`echo ${git_tag_complete_with_hash} | sed "s,v[0-9]*\.[0-9]*\.[0-9]*-[0-9]*-g\(.*\),\1,"`
if [ "x$git_tag_hash" == "x" ]; then
	git_tag_hash=" ="
fi

# dirty_tag
git_dirty=`echo ${current_tag} | tr -d " \r\n" | sed "s,.*\(-dirty\).*,\1,"`
if [ "x${git_dirty}" != "x-dirty" ]; then
	git_dirty=
fi

echo -e "* Tags replaced in input file:"
echo -e "  [MAJOR_VERSION]:     '${major_version}'"
echo -e "  [MINOR_VERSION]:     '${minor_version}'"
echo -e "  [REVISION]:          '${revision}'"
echo -e "  [GIT_TAG_ONLY]:      '${tag_only}'"
echo -e "  [GIT_TAG_HASH]:      '${git_tag_hash}'"
echo -e "  [COMMITS_SINCE_TAG]: '${commits_since_tag}'"
echo -e "  [GIT_CURRENT_TAG]:   '${current_tag}'"
echo -e "  [GIT_CURRENT_HASH]:  '${git_hash}'"
echo -e "  [GIT_COMMITS_FLAG]:  '${git_commits}'"
echo -e "  [GIT_DIRTY_FLAG]:    '${git_dirty}'"

# skip the file transformation if no more parameters
if [ "x$2x" != "xx" ] || [ "x$3x" != "xx" ]; then

	echo "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"

	# Preprocessing parameter 2
	if [ "x$2" != "x" ]; then
		# verify that input file exists
		if [ -e "$2" ]; then

			# Preprocessing parameter 3
			if [ "x$3" != "x" ]; then

				# Check that input != output
				if [ "$3" != "$2" ]; then

					# get the old tag if exist
					if [ -f "$3.tag" ]; then
						old_tag=`cat $3.tag`
					fi
					if [ -f "$3" ] && [ -f "$3.tag" ] && [ "x${old_tag}x" == "x${current_tag}x" ]; then
						echo "* No need to update the output file: $3"
					else
						echo "* Updating git version"
						echo "-   Using git repository : ${root_dir}"
						echo "-   using input file     : $2"
						echo "-   output to file       : $3"

						# if output file exists, just warn about it
						if [ -f "$3" ]; then
							echo "WARNING: output file exists. Will overwrite it..."
						fi

						# Replace parameters in file using sed
						sed \
							-e "s,\[MAJOR_VERSION\],${major_version},g" \
							-e "s,\[MINOR_VERSION\],${minor_version},g" \
							-e "s,\[REVISION\],${revision},g" \
							-e "s,\[GIT_TAG_ONLY\],${tag_only},g" \
							-e "s,\[GIT_TAG_HASH\],${git_tag_hash},g" \
							-e "s,\[COMMITS_SINCE_TAG\],${commits_since_tag},g" \
							-e "s,\[GIT_CURRENT_TAG\],${current_tag},g" \
							-e "s,\[GIT_CURRENT_HASH\],${git_hash},g" \
							-e "s,\[GIT_COMMITS_FLAG\],${git_commits},g" \
							-e "s,\[GIT_DIRTY_FLAG\],${git_dirty},g" \
							<$2 >$3

						 # record the actual curent tag
						 echo -n "${current_tag}" > $3.tag
					 fi
				else
					echo "ERROR: Input and ouput filename is equal!"
					exit_code=1
				fi
			else
				echo "ERROR: Missing the outputfile parameter!"
				exit_code=1
			fi
		else
			echo "ERROR: Input file does not exist!"
			exit_code=1
		fi
	fi
fi

Finish

