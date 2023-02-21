#!/bin/bash

TIMESTAMP=$(date +"%Y-%m-%d %T")
JETY_VERSION=1.0.0

echo "[JETyDEBUG] Resource folder at $SCRIPT_INPUT_FILE_0"

jety_folder="$(dirname $SCRIPT_INPUT_FILE_0)/JETy"

header="// Automatically generated at $TIMESTAMP by JETy $JETY_VERSION - Mauricio Torres Mejia (mauricio.torresmejia@justeattakeaway.com)\n"

# Create JETy folder
mkdir $jety_folder
echo "[JETyDEBUG] Create JETy folder at $jety_folder"

# Create JETy.swift
echo "[JETyDEBUG] Create JETy.swift if it doesn't exist"
jety_file="$jety_folder/JETy.swift"

if ! [ -e "$jety_file" ]; then
    echo -e "$header" > $jety_file
	echo "enum JETy {" >> $jety_file
	echo "	// Use this file for customization, this file doesn't get overwritten" >> $jety_file
	echo "}" >> $jety_file
else
    echo "[JETyDEBUG] JETy.swift already exists"
fi

# Create JETyTranslations.swift
echo "[JETyDEBUG] Create JETyTranslations.swift"
jety_translations_file="$jety_folder/JETyTranslations.swift"
echo -e "$header" > $jety_translations_file
echo "import Foundation" >> $jety_translations_file
echo "" >> $jety_translations_file
echo "extension JETy {" >> $jety_translations_file
echo "    enum Translations {" >> $jety_translations_file

# Find Base.lproj folder
echo "[JETyDEBUG] Find Base.lproj folder in $SCRIPT_INPUT_FILE_0"
base_folder=$(find "$SCRIPT_INPUT_FILE_0" -name "Base.lproj")
strings_file="$base_folder/Localizable.strings"
echo "[JETyDEBUG] Assuming $strings_file as strings file location"

# Read each key-value in strings file using a regular expression
regex="\"(.*?)\"(.*?)=(.*?)\"(.*?)\";"
echo "[JETyDEBUG] Read each key-value in strings file"
grep -Eo "$regex" "$strings_file" | while read -r line; do

    # Get key and value
    key=$(echo $line | cut -d '=' -f 1 | tr -d '\";')
    value=$(echo $line | cut -d '=' -f 2 | tr -d '\";')

    # Trimming values
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"

	# Convert key from snake_case to camelCase
    camel_key=$(echo "${key//./_}" | awk -F "_" '{for (i=1; i<=NF; i++) {if (i == 1) {printf "%s", tolower($i)} else {printf "%s%s", toupper(substr($i,1,1)), substr($i,2)}}}')

	# Clean special characters
    camel_key=$(echo "$camel_key" | tr -d '[:punct:]')

    localization_comment=$(echo "$value" | sed -E 's/%([0-9]*[.][0-9]*f)/_FLOAT_/g; s/%d/_INT_/g; s/%@/_STRING_/g; s/%s/_STRING_/g; s/%[^fdis@%]*[fdis@%]/_INPUT_/g')
    localization_comment=$(echo "$localization_comment" | sed 's/\\//g')

    # Check if value has format specifiers
    if [[ $value =~ %((\.\d*)?f|[@diouxXfFeEgGaAcspn]) ]]; then

		echo "        static func $camel_key(_ args: CVarArg...) -> String {" >> $jety_translations_file
  		echo "        	let format = NSLocalizedString(\"$key\", comment: \"$localization_comment\")" >> $jety_translations_file
    	echo "        	return String(format: format, arguments: args)" >> $jety_translations_file
     	echo "        }" >> $jety_translations_file

    else
        # If value doesn't have format specifiers, create a static variable
    	echo "        static var $camel_key: String { NSLocalizedString(\"$key\", comment:\"$localization_comment\")}" >> $jety_translations_file
    fi
done

# Close JETyTranslations.swift
echo "[JETyDEBUG] Close JETyTranslations.swift"
echo "    }" >> $jety_translations_file
echo "}" >> $jety_translations_file

# Create JETyImages.swift
echo "[JETyDEBUG] Create JETyImages.swift"
jety_images_file="$jety_folder/JETyImages.swift"
echo -e "$header" > $jety_images_file
echo "import UIKit" >> $jety_images_file
echo "" >> $jety_images_file
echo "extension JETy {" >> $jety_images_file

# Find all the xcassets
echo "[JETyDEBUG] Find all the xcassets in resources folder"
assets_files=($(find "$SCRIPT_INPUT_FILE_0" -name "*.xcassets"))

# The number of xcassets files
assets_count=${#assets_files[@]}
echo "[JETyDEBUG] Found $assets_count xcassets files"

# Loop through each xcassets file and extract the image sets
echo "[JETyDEBUG] Iterate over every xcassets file"
for ((index=0; index < assets_count; index++)); do

	echo "" >> $jety_images_file
	xcassets_file=${assets_files[$index]}

	echo "[JETyDEBUG] Found $xcassets_file"
	enum_name=$(basename "$xcassets_file" .xcassets)

	echo "[JETyDEBUG] Map $enum_name"
 	echo "	enum $enum_name {" >> $jety_images_file

  	for iconset in $(find "$xcassets_file" -maxdepth 1 -type d -name "*.appiconset"); do
   		icon_name=$(basename "$iconset" .appiconset)
     	curated_icon_name=$(echo "$icon_name" | tr '-' '_' | sed 's/^[[:upper:]]/\L&/' | tr -dc '[:alnum:][:upper:]\n\r')
     	curated_icon_name=$(echo "${curated_icon_name//./_}" | awk -F "_" '{for (i=1; i<=NF; i++) {if (i == 1) {printf "%s", tolower($i)} else {printf "%s%s", toupper(substr($i,1,1)), substr($i,2)}}}')

    	echo "		static var $curated_icon_name: UIImage { return UIImage(named: \"$icon_name\")! }" >> $jety_images_file
    done

    for imageset in $(find "$xcassets_file" -maxdepth 1 -type d -name "*.imageset"); do
   		image_name=$(basename "$imageset" .imageset)
     	curated_image_name=$(echo "$image_name" | tr '-' '_' | sed 's/^[[:upper:]]/\L&/' | tr -dc '[:alnum:][:upper:]\n\r')
     	curated_image_name=$(echo "${curated_image_name//./_}" | awk -F "_" '{for (i=1; i<=NF; i++) {if (i == 1) {printf "%s", tolower($i)} else {printf "%s%s", toupper(substr($i,1,1)), substr($i,2)}}}')
    	echo "		static var $curated_image_name: UIImage { return UIImage(named: \"$image_name\")! }" >> $jety_images_file
    done

    for group in $(find "$xcassets_file" -maxdepth 1 -type d -name "*"); do

        group_name=$(basename "$group")
        extension=${group_name##*.}

		echo "[JETyDEBUG] Verify is a group $group_name $extension"

        if test "$extension" = "$group_name"; then

			echo "" >> $jety_images_file
            curated_group_name=$(echo "$group_name" | tr -dc '[:alnum:]\n\r' | tr '-' '_')
        	echo "		enum $curated_group_name {" >> $jety_images_file

			for subiconset in $(find "$xcassets_file/$group_name" -maxdepth 1 -type d -name "*.appiconset"); do
   				subicon_name=$(basename "$subiconset" .appiconset)
       			curated_subicon_name=$(echo "$subicon_name" | tr '-' '_' | sed 's/^[[:upper:]]/\L&/' | tr -dc '[:alnum:][:upper:]\n\r')
       			curated_subicon_name=$(echo "${curated_subicon_name//./_}" | awk -F "_" '{for (i=1; i<=NF; i++) {if (i == 1) {printf "%s", tolower($i)} else {printf "%s%s", toupper(substr($i,1,1)), substr($i,2)}}}')
    			echo "			static var $curated_subicon_name: UIImage { return UIImage(named: \"$subicon_name\")! }" >> $jety_images_file
    		done

            for subimageset in $(find "$xcassets_file/$group_name" -maxdepth 1 -type d -name "*.imageset"); do
   				subimage_name=$(basename "$subimageset" .imageset)
       			curated_subimage_name=$(echo "$subimage_name" | tr '-' '_' | sed 's/^[[:upper:]]/\L&/' | tr -dc '[:alnum:][:upper:]\n\r')
       			curated_subimage_name=$(echo "${curated_subimage_name//./_}" | awk -F "_" '{for (i=1; i<=NF; i++) {if (i == 1) {printf "%s", tolower($i)} else {printf "%s%s", toupper(substr($i,1,1)), substr($i,2)}}}')
    			echo "			static var $curated_subimage_name: UIImage { return UIImage(named: \"$subimage_name\")! }" >> $jety_images_file
    		done

         	echo "		}" >> $jety_images_file
        fi
    done

    # Close the xcassets-level enum
	echo "	}" >> $jety_images_file
done

# Close the top-level enum
echo "}" >> $jety_images_file
