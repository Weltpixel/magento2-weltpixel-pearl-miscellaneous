#!/bin/bash

# usage: ./pearl_cloud_setups.sh
#
# Run it from the project root. app/code and vendor are read-only once the
# application is deployed, so the css folder of each Pearl module that generates
# LESS is replaced with a symlink into pub/media/css_weltpixel, which is a
# writable mount.

set -euo pipefail

## Pearl modules that generate LESS from the theme options
modules=(
    "CategoryPage"
    "CustomHeader"
    "FrontendOptions"
    "ProductPage"
    "CustomFooter"
)

MEDIA_DIR="pub/media/css_weltpixel"

fail() {
    echo "Pearl Cloud patch: ERROR: $*" >&2
    exit 1
}

warn() {
    echo "Pearl Cloud patch: WARNING: $*" >&2
}

## The module folder of a Pearl module, installed by Composer
module_dir() {
    case "$1" in
        CategoryPage) echo "vendor/weltpixel/m2-weltpixel-category-page" ;;
        CustomHeader) echo "vendor/weltpixel/m2-weltpixel-custom-header" ;;
        FrontendOptions) echo "vendor/weltpixel/m2-weltpixel-frontend-options" ;;
        ProductPage) echo "vendor/weltpixel/m2-weltpixel-product-page" ;;
        CustomFooter) echo "vendor/weltpixel/m2-weltpixel-custom-footer" ;;
        *) fail "no Composer package is known for the $1 module" ;;
    esac
}

## The relative path from a folder (given relative to the project root) back to the project root
to_root() {
    local up=""
    local part
    local parts
    IFS='/' read -r -a parts <<< "$1"
    for part in "${parts[@]}"; do
        up="../$up"
    done
    echo "$up"
}

[ -f bin/magento ] || fail "run the script from the project root"

for MODULENAME in "${modules[@]}"; do
    webDir="$(module_dir "$MODULENAME")/view/frontend/web"
    if [ ! -d "$webDir" ]; then
        warn "$webDir not found, the $MODULENAME module is skipped"
        continue
    fi
    [ -d "$MEDIA_DIR/$MODULENAME/css" ] || warn "$MEDIA_DIR/$MODULENAME/css not found: copy the patch pub folder into the project root"

    rm -rf "${webDir:?}/css"
    ln -s "$(to_root "$webDir")$MEDIA_DIR/$MODULENAME/css" "$webDir/css"
    echo "Symlink was successfully applied for $MODULENAME module."
done

echo "Patch was successfully applied."
