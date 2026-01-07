
#!/bin/bash

#usage ./pearl_cloud_setups.sh

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
    cd app/code/WeltPixel/$MODULENAME/view/frontend/web/;
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
    echo "Symlink was successfully applied for $MODULENAME module.";
done


echo "Patch was successfully applied.";