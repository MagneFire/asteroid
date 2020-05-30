
#!/bin/bash
# Copyright (C) 2015 Florent Revest <revestflo@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

function pull_dir {
    if [ -d $1/.git/ ] ; then
        [ "$1" != "." ]   && pushd $1 > /dev/null
        git symbolic-ref HEAD &> /dev/null
        if [ $? -eq 0 ] ; then
            echo -e "\e[32mPulling $1\e[39m"
            git pull --rebase
            [ $? -ne 0 ] && echo -e "\e[91mError pulling $1\e[39m"
        else
            echo -e "\e[35mSkipping $1\e[39m"
        fi
        [ "$1" != "." ]   && popd > /dev/null
    fi
}

function clone_dir {
    if [ ! -d $1 ] ; then
        echo -e "\e[32mCloning branch $3 of $2 in $1\e[39m"
        git clone -b $3 $2 $1
        [ $? -ne 0 ] &&  echo -e "\e[91mError cloning $1\e[39m"
        if [ $# -eq 4 ]
        then
            pushd $1
            git checkout $4
            popd
        fi
    fi
}

# Update layers in src/
if [[ "$1" == "update" ]]; then
    pull_dir .
    for d in src/*/ ; do
        pull_dir $d
    done
    pull_dir src/oe-core/bitbake
elif [[ "$1" == "git-"* ]]; then
    base=$(dirname $0)
    gitcmd=${1:4} # drop git-
    shift
    for d in $base $base/src/* $base/src/oe-core/bitbake; do
        if [ $(git -C $d $gitcmd "$@" | wc -c) -ne 0 ]; then
            echo -e "\e[35mgit -C $d $gitcmd $@ \e[39m"
            git -C $d $gitcmd "$@"
        fi
    done
# Prepare bitbake
else
    mkdir -p src build/conf

    if [ "$#" -gt 0 ]; then
        export MACHINE=${1}
    else
        export MACHINE=dory
    fi

    # Fetch all the needed layers in src/
    clone_dir src/oe-core              https://github.com/openembedded/openembedded-core.git warrior
    clone_dir src/oe-core/bitbake      https://github.com/openembedded/bitbake.git           1.42
    clone_dir src/meta-openembedded    https://github.com/openembedded/meta-openembedded.git warrior
    clone_dir src/meta-qt5             https://github.com/meta-qt5/meta-qt5                  master 8bc72a78b13f2f4c5e1cebebaef9e98b9abbb056
    clone_dir src/meta-smartphone      https://github.com/shr-distribution/meta-smartphone   warrior
    clone_dir src/meta-anthias-hybris  https://github.com/AsteroidOS/meta-anthias-hybris     master
    clone_dir src/meta-bass-hybris     https://github.com/AsteroidOS/meta-bass-hybris        master
    clone_dir src/meta-dory-hybris     https://github.com/AsteroidOS/meta-dory-hybris        master
    clone_dir src/meta-lenok-hybris    https://github.com/AsteroidOS/meta-lenok-hybris       master
    clone_dir src/meta-mtk6580-hybris  https://github.com/AsteroidOS/meta-mtk6580-hybris     master
    clone_dir src/meta-mooneye-hybris  https://github.com/AsteroidOS/meta-mooneye-hybris     master
    clone_dir src/meta-sparrow-hybris  https://github.com/AsteroidOS/meta-sparrow-hybris     master
    clone_dir src/meta-sprat-hybris    https://github.com/AsteroidOS/meta-sprat-hybris       master
    clone_dir src/meta-swift-hybris    https://github.com/AsteroidOS/meta-swift-hybris       master
    clone_dir src/meta-tetra-hybris    https://github.com/AsteroidOS/meta-tetra-hybris       master
    clone_dir src/meta-wren-hybris     https://github.com/AsteroidOS/meta-wren-hybris        master
    clone_dir src/meta-asteroid        https://github.com/MagneFire/meta-asteroid            master
    clone_dir src/meta-sturgeon-hybris https://github.com/MagneFire/meta-sturgeon-hybris     master
    clone_dir src/meta-games           https://github.com/MagneFire/meta-games               master

    # Create local.conf and bblayers.conf on first run
    if [ ! -e build/conf/local.conf ]; then
        echo -e "\e[32mWriting build/conf/local.conf\e[39m"
        echo 'DISTRO = "asteroid"
PACKAGE_CLASSES = "package_ipk"' >> build/conf/local.conf
    fi

    if [ ! -e build/conf/bblayers.conf ]; then
        echo -e "\e[32mWriting build/conf/bblayers.conf\e[39m"
        echo 'BBPATH = "${TOPDIR}"
SRCDIR = "${@os.path.abspath(os.path.join("${TOPDIR}", "../src/"))}"

BBLAYERS = " \
  ${SRCDIR}/meta-qt5 \
  ${SRCDIR}/oe-core/meta \
  ${SRCDIR}/meta-asteroid \
  ${SRCDIR}/meta-openembedded/meta-oe \
  ${SRCDIR}/meta-openembedded/meta-multimedia \
  ${SRCDIR}/meta-openembedded/meta-gnome \
  ${SRCDIR}/meta-openembedded/meta-networking \
  ${SRCDIR}/meta-smartphone/meta-android \
  ${SRCDIR}/meta-openembedded/meta-python \
  ${SRCDIR}/meta-openembedded/meta-filesystems \
  ${SRCDIR}/meta-anthias-hybris \
  ${SRCDIR}/meta-sparrow-hybris \
  ${SRCDIR}/meta-sprat-hybris \
  ${SRCDIR}/meta-tetra-hybris \
  ${SRCDIR}/meta-bass-hybris \
  ${SRCDIR}/meta-dory-hybris \
  ${SRCDIR}/meta-lenok-hybris \
  ${SRCDIR}/meta-sturgeon-hybris \
  ${SRCDIR}/meta-mtk6580-hybris \
  ${SRCDIR}/meta-mooneye-hybris \
  ${SRCDIR}/meta-swift-hybris \
  ${SRCDIR}/meta-wren-hybris \
  ${SRCDIR}/meta-games \
  "' > build/conf/bblayers.conf
    fi

    # Init build env
    cd src/oe-core
    . ./oe-init-build-env ../../build > /dev/null

    echo "Welcome to the Asteroid compilation script.

If you meet any issue you can report it to the project's github page:
    https://github.com/AsteroidOS

You can now run the following command to get started with the compilation:
    bitbake asteroid-image

Have fun!"
fi
