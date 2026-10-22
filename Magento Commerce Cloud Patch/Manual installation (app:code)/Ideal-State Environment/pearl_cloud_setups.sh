#!/bin/bash

# usage: ./pearl_cloud_setups.sh
#
# Run it from the project root in the build hook, after
#   php ./vendor/bin/ece-tools build:generate
#   php ./vendor/bin/ece-tools build:transfer
#
# app/code, vendor and the deployed static content are read-only once the
# application is deployed, so the folders Pearl regenerates are replaced with
# symlinks into pub/media/css_weltpixel, which is a writable mount.
#
# Files are placed in init/pub/media/css_weltpixel and not in pub/media:
# build:transfer has already copied pub/media to init/pub/media, and on every
# deploy ece-tools copies init/pub/media into the pub/media mount. Anything
# written to pub/media after build:transfer would be hidden by the mount.

set -euo pipefail

## Pearl modules that generate LESS from the theme options
modules=(
    "CategoryPage"
    "CustomHeader"
    "FrontendOptions"
    "ProductPage"
    "CustomFooter"
)

## Define here all themes and locales that use Pearl (no commas between them)
PearlThemes=(
    "Pearl/weltpixel_custom/en_US"
)

MEDIA_DIR="pub/media/css_weltpixel"
INIT_MEDIA_DIR="init/$MEDIA_DIR"

fail() {
    echo "Pearl Cloud patch: ERROR: $*" >&2
    exit 1
}

warn() {
    echo "Pearl Cloud patch: WARNING: $*" >&2
}

## The module folder of a Pearl module
module_dir() {
    echo "app/code/WeltPixel/$1"
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

## Whether the application declares a pub/static mount, read the same way as ece-tools
has_pub_static_mount() {
    local result=2
    if [ -n "${MAGENTO_CLOUD_APPLICATION:-}" ]; then
        result=$(php -r '
            $app = json_decode(base64_decode(getenv("MAGENTO_CLOUD_APPLICATION")), true);
            if (!is_array($app) || !isset($app["mounts"])) { echo 2; exit; }
            echo (isset($app["mounts"]["pub/static"]) || isset($app["mounts"]["/pub/static"])) ? 0 : 1;
        ')
    fi
    if [ "$result" = "2" ] && [ -f .magento.app.yaml ]; then
        if grep -Eq "^[[:space:]]+[\"']?/?pub/static[\"']?[[:space:]]*:" .magento.app.yaml; then
            result=0
        else
            result=1
        fi
    fi
    [ "$result" = "0" ]
}

## Replace a static css folder with a symlink into the media mount; its files go to init/ so deploy restores them
link_static_css() {
    local cssDir="$1"
    local mediaPath="$2"

    rm -rf "${INIT_MEDIA_DIR:?}/$mediaPath"
    mkdir -p "$INIT_MEDIA_DIR/$mediaPath"
    if [ -d "$cssDir" ] && [ ! -L "$cssDir" ]; then
        cp -R "$cssDir/." "$INIT_MEDIA_DIR/$mediaPath/"
    fi

    mkdir -p "$(dirname "$cssDir")"
    rm -rf "$cssDir"
    ln -s "$(to_root "$(dirname "$cssDir")")$MEDIA_DIR/$mediaPath" "$cssDir"
}

[ -f bin/magento ] || fail "run the script from the project root"
[ -d init ] || fail "init/ not found: run the script after php ./vendor/bin/ece-tools build:transfer"

## Modules: the generated LESS is written to the module css folder
for MODULENAME in "${modules[@]}"; do
    webDir="$(module_dir "$MODULENAME")/view/frontend/web"
    if [ ! -d "$webDir" ]; then
        warn "$webDir not found, the $MODULENAME module is skipped"
        continue
    fi

    ## the installed module files are the starting point, so they always match the module version
    rm -rf "${INIT_MEDIA_DIR:?}/$MODULENAME/css"
    mkdir -p "$INIT_MEDIA_DIR/$MODULENAME/css"
    if [ -d "$webDir/css" ] && [ ! -L "$webDir/css" ]; then
        cp -R "$webDir/css/." "$INIT_MEDIA_DIR/$MODULENAME/css/"
    elif [ -d "$MEDIA_DIR/$MODULENAME/css" ]; then
        cp -R "$MEDIA_DIR/$MODULENAME/css/." "$INIT_MEDIA_DIR/$MODULENAME/css/"
    fi

    rm -rf "${webDir:?}/css"
    ln -s "$(to_root "$webDir")$MEDIA_DIR/$MODULENAME/css" "$webDir/css"
    echo "Symlink was successfully applied for $MODULENAME module."
done

## Themes: the generated CSS is written to the deployed static content
if has_pub_static_mount; then
    STATIC_DIR="init/pub/static"
    [ -d "$STATIC_DIR/frontend" ] || fail "$STATIC_DIR/frontend not found: static content has to be deployed in the build phase and the script run after build:transfer"
else
    STATIC_DIR="pub/static"
    [ -d "$STATIC_DIR/frontend" ] || fail "$STATIC_DIR/frontend not found: static content has to be deployed in the build phase"
fi
echo "Using the static content in $STATIC_DIR."

for THEMEPATH in "${PearlThemes[@]}"; do
    themeDir="$STATIC_DIR/frontend/$THEMEPATH"
    if [ ! -d "$themeDir" ]; then
        warn "$themeDir not found: check the theme and locale in PearlThemes, $THEMEPATH is skipped"
        continue
    fi

    link_static_css "$themeDir/css" "static/$THEMEPATH/css"
    for MODULENAME in "${modules[@]}"; do
        link_static_css "$themeDir/WeltPixel_$MODULENAME/css" "static/$THEMEPATH/$MODULENAME/css"
    done
    echo "Symlinks were successfully applied for $THEMEPATH."
done

if [ -d "$STATIC_DIR/frontend/Pearl/weltpixel/default/css" ]; then
    link_static_css "$STATIC_DIR/frontend/Pearl/weltpixel/default/css" "static/Pearl/weltpixel/default/css"
fi

echo "Patch was successfully applied."
