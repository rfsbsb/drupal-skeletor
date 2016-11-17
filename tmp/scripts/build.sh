#!/bin/bash

# USAGE
# Run this script as given from the root of your install profile
# To build out a specific commit, use the full 40char commit hash as the revision.
# To build a branch, use the branch as the revision.
# To build a stable production environment, exclude it.
#
# $ bash build.sh [ project ] [ /fullpath/to/build/project ] [ revision ]

# Bail if non-zero exit code
set -e

# Set from args
while [ $# -gt 0 ]; do
  case "$1" in
    --project=*)
      PROJECT="${1#*=}"
      ;;
    --destination=*)
      BUILD_DEST="${1#*=}"
      ;;
    --revision=*)
      REVISION="${1#*=}"
      ;;
    *)
      printf "***************************\n"
      printf "* Error: Invalid argument.*\n"
      printf "***************************\n"
      exit 1
  esac
  shift
done

MAKE_OPTS=" --prepare-install --y"
REVISION_PATTERN="([a-f0-9]{40}|[a-f0-9]{6,8})$"

# Configure options for production or development build.
if [[ -z "$REVISION" ]] || [[ "$REVISION" == 'false' ]]; then
  echo "::Building production environment"
  MAKE_OPTS="--no-gitinfofile ${MAKE_OPTS}"
else
  echo "::Building development environment"
  MAKE_OPTS="--working-copy ${MAKE_OPTS}"
  # Replace the last line of the build.make.yml with the revision or branch we need.
  # @todo fix this when --overrides is included in drush dev-master on packagist.

  if [[ "$REVISION" =~ $REVISION_PATTERN ]]; then
    echo "::Using commit ${REVISION}"
    echo "      revision: \"${REVISION}\"" >> build.make.yml
  else
    echo "::Using branch ${REVISION}"
    find "build.make.yml" -type f -exec sed -i '' -e '$ d' {} \;
    echo "      branch: \"${REVISION}\"" >> build.make.yml
  fi
fi

# Drush make the site structure
echo "::Running drush make"
drush make build.make.yml ${BUILD_DEST} ${MAKE_OPTS}

echo "::Renaming the profile folder"
mv ${BUILD_DEST}/profiles/skeletor ${BUILD_DEST}/profiles/${PROJECT}

# Copy the settings.yml.
cp ${BUILD_DEST}/sites/default/default.services.yml ${BUILD_DEST}/sites/default/services.yml

chmod 777 ${BUILD_DEST}/sites/default/settings.php
chmod 777 ${BUILD_DEST}/sites/default/services.yml

echo "::Appending settings.php snippets"
for f in ${BUILD_DEST}/profiles/${PROJECT}/tmp/snippets/settings.php/*.settings.php
do
  # Concatenate newline and snippet, then append to settings.php
  echo "" | cat - $f | tee -a ${BUILD_DEST}/sites/default/settings.php > /dev/null
done


echo "::Prepending .htaccess snippets at the start of file."
for f in tmp/snippets/htaccess/*.before.htaccess
do
  # Prepend a snippet and a new line to the existing .htaccess file
  echo "" | cat $f - | cat - ${BUILD_DEST}/.htaccess > htaccess.tmp
  mv htaccess.tmp ${BUILD_DEST}/.htaccess
done

echo "::Appending .htaccess snippets at the end of file..."
for f in tmp/snippets/htaccess/*.after.htaccess
do
  # Concatenate newline and snippet, then append to the existing .htaccess file
  echo "" | cat - $f | tee -a ${BUILD_DEST}/.htaccess > /dev/null
done

echo "::Appending robots.txt snippets at the end of file..."
for f in tmp/snippets/robots.txt/*.robots.txt
do
  # Concatenate newline and snippet, then append to the existing .htaccess file
  echo "" | cat - $f | tee -a ${BUILD_DEST}/robots.txt > /dev/null
done

echo "::Copying files into docroot..."
if [ -d tmp/copy_to_docroot ]; then
  # Copy files into docroot
  cp -r tmp/copy_to_docroot/. ${BUILD_DEST}/
fi

echo "::Copying files into sites/default..."
if [ -d tmp/copy_to_sites_default ]; then
  # Copy files into sites/default
  cp -r tmp/copy_to_sites_default/. ${BUILD_DEST}/sites/default/
fi

# Compile CSS
echo "::Finding custom themes"
for THEME in ${BUILD_DEST}/profiles/${PROJECT}/themes/custom/*/;
do
  if [ -d "$THEME" ]; then
    cd $THEME
    if [ -f config.rb ]; then
      DIR_NAME=${PWD##*/}
      echo "::Compiling stylesheets for '$DIR_NAME' theme"
      compass compile
    fi
  fi
done

echo "::Renaming skeletor files to the new profile name"
cd $BUILD_DEST/profiles/${PROJECT}
for i in skeletor.*;
do
  mv "$i" $(echo "$i" | sed -E "s/skeletor.([a-z.])/$PROJECT.\1/g");
  echo "Renaming $i"
done

echo "::Find and replace skeletor vars for Project"
cd $BUILD_DEST/profiles/${PROJECT}
rpl -R "skeletor" "${PROJECT}" ./

if [[ -z "$REVISION" ]] || [[ "$REVISION" == 'false' ]]; then
  echo "::Removing non-production files"
  cd $BUILD_DEST
  rm profiles/${PROJECT}/.gitignore
  rm profiles/${PROJECT}/.travis.yml
  rm profiles/${PROJECT}/README.md
  rm profiles/${PROJECT}/*.make.yml
  rm README.txt
  rm LICENSE.txt
  rm example.gitignore
fi;
