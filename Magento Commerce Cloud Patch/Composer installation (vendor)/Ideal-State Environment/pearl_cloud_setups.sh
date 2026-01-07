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
    MODULENAME=$index;
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

## Define here all themes and locales that use Pearl
PearlThemes=(
    "Pearl/weltpixel_custom/en_US"
);

for i in "${PearlThemes[@]}"
do
    THEMEPATH=$i

    if [ -d pub/media/css_weltpixel/static/$THEMEPATH ]
    then
        rm -rf  pub/media/css_weltpixel/static/$THEMEPATH;
    fi

    if [ -d init/pub/static/frontend/$THEMEPATH/css ]
    then
        rm -rf  init/pub/static/frontend/$THEMEPATH/css;
    fi

    mkdir -p init/pub/static/frontend/$THEMEPATH/css
    mkdir -p pub/media/css_weltpixel/static/$THEMEPATH/css
    mv init/pub/static/frontend/$THEMEPATH/css pub/media/css_weltpixel/static/$THEMEPATH

    cd init/pub/static/frontend/$THEMEPATH
    ln -s ../../../../../../../pub/media/css_weltpixel/static/$THEMEPATH/css css
    cd ../../../../../../../

    for index in "${modules[@]}"
    do
        MODULENAME=$index
        mkdir -p pub/media/css_weltpixel/static/$THEMEPATH/$MODULENAME/css
        mkdir -p init/pub/static/frontend/$THEMEPATH/WeltPixel_$MODULENAME/css
        mv init/pub/static/frontend/$THEMEPATH/WeltPixel_$MODULENAME/css pub/media/css_weltpixel/static/$THEMEPATH/$MODULENAME
    done

    for index in "${modules[@]}"
    do
        MODULENAME=$index
        cd init/pub/static/frontend/$THEMEPATH/WeltPixel_$MODULENAME
        ln -s ../../../../../../../../pub/media/css_weltpixel/static/$THEMEPATH/$MODULENAME/css css
        cd ../../../../../../../../
    done
done

if [ -d init/pub/static/frontend/Pearl/weltpixel/default ]
then
    if [ -d pub/media/css_weltpixel/static/Pearl/weltpixel/default ]
    then
        rm -rf  pub/media/css_weltpixel/static/Pearl/weltpixel/default;
    fi

    mkdir -p pub/media/css_weltpixel/static/Pearl/weltpixel/default
    mv init/pub/static/frontend/Pearl/weltpixel/default/css pub/media/css_weltpixel/static/Pearl/weltpixel/default
    cd init/pub/static/frontend/Pearl/weltpixel/default
    ln -s ../../../../../../../pub/media/css_weltpixel/static/Pearl/weltpixel/default/css css
    cd ../../../../../../../
fi

echo "Patch was successfully applied.";

