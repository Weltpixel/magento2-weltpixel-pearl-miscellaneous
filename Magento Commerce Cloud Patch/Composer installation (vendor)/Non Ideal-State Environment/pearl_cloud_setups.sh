
#!/bin/bash

#usage ./pearl_cloud_setups.sh

# Module name to vendor package name mapping
declare -A module_packages
module_packages["CategoryPage"]="m2-weltpixel-category-page"
module_packages["CustomHeader"]="m2-weltpixel-custom-header"
module_packages["FrontendOptions"]="m2-weltpixel-frontend-options"
module_packages["ProductPage"]="m2-weltpixel-product-page"
module_packages["CustomFooter"]="m2-weltpixel-custom-footer"

modules=(
    "CategoryPage"
    "CustomHeader"
    "FrontendOptions"
    "ProductPage"
    "CustomFooter"
);


for index in "${modules[@]}"
do
    MODULENAME="${index%%::*}";
    PACKAGENAME=${module_packages[$MODULENAME]};
    cd vendor/weltpixel/$PACKAGENAME/view/frontend/web/;
    if [ -L css ]
    then
        unlink css;
    fi
    if [ -d css ]
    then
        rm -rf  css;
    fi
    ln -s ../../../../../../../pub/media/css_weltpixel/$MODULENAME/css/ css;
    cd ../../../../../../../;
    echo "Symlink was successfully applied for $MODULENAME module ($PACKAGENAME).";
done


echo "Patch was successfully applied.";

