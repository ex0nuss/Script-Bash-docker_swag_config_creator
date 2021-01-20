#!/bin/bash

#################################################
# Functions
#################################################

#Searches $1 and replaces with $2 in $file
function search_and_replace {
  sed -i 's|'$1'|'$2'|g' "$3"
}

# Tests and reloads reverseproxy
function swag_reload {
  # Asks if SWAG needs to be reloaded
  read -p "Do you want to reload the reverse proxy (SWAG)? (y/n)? " choice

  case "$choice" in
    y|Y )
      docker exec $swagContainerName nginx -c /config/nginx/nginx.conf -t &&\
      docker exec $swagContainerName nginx -c /config/nginx/nginx.conf -s reload &&\
      echo "SWAG reloaded" ;;

    n|N ) echo "SWAG was not reloaded" ;;

    * ) ;;
  esac
  echo ""
}

# Asks if you wanna edit a config file, opens edit, and asks if your dont with editing afterwards
function edit_config_file {
  # Asks if config file needs to be edited
  read -p "Do you want to edit the config file? (y/n)? " choice

  case "$choice" in
    y|Y )
      # case insensitive comparison, for done editing question
      while [ "${choiceDoneEditing,,}" != 'y' ]; do
        nano "$1"
        read -p "Are you done editing? (y/n)? " choiceDoneEditing
      done ;;

    n|N ) ;;

      * ) echo "Invalid answer";;
  esac
  echo ""
}



#################################################
# Variables
#################################################

# Static vars
baseDir='/sharedfolders/appdata/backend/swg/data-swag/nginx/conf.d'
pwd_old=$(pwd)
domain='exonuss.de'
swagContainerName='backend-swg-swag'

# Dynamic load vars
read -p "Subdomain: " subdomain

# File and folder vars
fileSitesAvailable="$baseDir/sites-available/$subdomain.conf"
folderSitesEnabled="$baseDir/sites-enabled/"
fileSitesEnabled="$folderSitesEnabled/$subdomain.conf"



#################################################
# Script
#################################################

# Creates new config from template
if [[ ! -f $fileSitesAvailable ]]; then
  read -p "Port of service: " port
  echo ""

  sudo cp -a "$baseDir/sites-available/_template.conf" "$fileSitesAvailable"
  echo "Created config file from template: $fileSitesAvailable"

  # Replaces subdomain and port
  search_and_replace REPLACE_SUBDOMAIN $subdomain $fileSitesAvailable
  search_and_replace REPLACE_PORT $port $fileSitesAvailable

  edit_config_file "$fileSitesAvailable"

  # If config file in sites-available already exists
else
  echo "Config file already exists: $fileSitesAvailable"
  echo ""
fi


# if link in sites-enabled not exists
if [[ ! -f $fileSitesEnabled ]]; then
  read -p "Do you want to link (activate) the domain $subdomain.$domain? (y/n)? " choice

  case "$choice" in
    y|Y )
      # Creates link in sites-enabled
      cd "$folderSitesEnabled" &&\
      sudo ln -s "../sites-available/$subdomain.conf" &&\
      echo "$subdomain.$domain linked in $folderSitesEnabled" &&\
      echo "" &&\

      swag_reload ;;

    n|N )
     echo "No link opperation was made.";;

    * ) echo "Invalid answer";;
  esac

# if link in sites-enabled exists
else
  echo "The domain $subdomain.$domain is already linked (activated)!"

  read -p "Do you want to unlink (deactivate) the subdomain $subdomain.$domain? (y/n)? " choice

  case "$choice" in
    y|Y )
      sudo unlink $fileSitesEnabled &&\
      echo "$subdomain.$domain got unlinked." &&\
      echo "" &&\
      swag_reload ;;

    n|N )
      echo "No unlink opperation was made."
      echo ""
      edit_config_file $fileSitesEnabled &&\
      swag_reload ;;

    * ) echo "Invalid answer";;
  esac
fi

echo ""
echo "All done, Bye!"
cd "$pwd_old"
