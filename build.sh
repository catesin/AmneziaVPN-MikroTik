#!/bin/bash

function func_die() {
    echo "Build needs at least target architecture:"
    echo "    amd64, arm or arm64."
    echo "Other params are:"
    echo "    no_nat (compile without nat support to reduce footprint)."
    echo "    3.20 (build with Alpine Linux 3.20)."i
    echo "\n"
    echo "Example: ./build.sh amd64 no_nat 3.20"

    exit
}


function func_main() {
    ###
    # Test for params existance
    ###
    if [ -z "$1" ]; then
        func_die
    fi

    ###
    # No more then 3 params
    ###
    if [ $# -gt 3 ]; then
        func_die
    fi

    ARCH=""
    NO_NAT=""
    ALPINE=""

    while [ -n "$1" ]; do
        case $1 in
	    amd64)
		if [ -z "$ARCH" ]; then
                    ARCH="amd64"
		else
                    func_die
		fi
                ;;
            arm)
		if [ -z "$ARCH" ]; then
                    ARCH="arm"
		else
                    func_die
		fi
                ;;
            arm64)
		if [ -z "$ARCH" ]; then
                    ARCH="arm64"
		else
                    func_die
		fi
                ;;
            no_nat)
		if [ -z "$NO_NAT" ]; then
                    NO_NAT="no_nat"
		else
                    func_die
		fi
	        ;;
            3.20)
		if [ -z "$ALPINE" ]; then
                    ALPINE="3.20"
		else
                    func_die
		fi
                ;;
            *)
                func_die
                ;;
        esac
        shift
    done

    ###
    # ARCH should be defined exlicitly at run
    ###
    if [ -z "$ARCH" ]; then
        func_die
    fi

    cat ./TEMPLATES/Dockerfile_template > /tmp/Dockerfile_build
    cat ./TEMPLATES/wg-quick_template > /tmp/wg-quick_build

    if [ -n "$NO_NAT" ]; then
        sed -i "s/iptables ip6tables iptables-legacy //" /tmp/Dockerfile_build
        sed -i '/sbin\/iptables/,+2d' /tmp/Dockerfile_build
	sed -i '/start_pre()/,+8d' /tmp/wg-quick_build
    else
	NO_NAT="nat"
    fi

    if [ -n "$ALPINE" ]; then
        sed -i 's/3\.21/3\.20/' /tmp/Dockerfile_build
        sed -i 's/\/usr\/libexec\/rc\/sh\/init.sh/\/lib\/rc\/sh\/init.sh/' /tmp/Dockerfile_build
    else
	ALPINE="3.21"
    fi

    mv /tmp/Dockerfile_build ./Dockerfile
    mv /tmp/wg-quick_build ./wg-quick
    chmod +x ./wg-quick

    if [ "$ARCH" != "amd64" ]; then
        #Downlad qemu emulator for target archtecture
        docker run --privileged --rm tonistiigi/binfmt --install $ARCH
        echo ""
    fi

    if [ ! -d "./images" ]; then
        mkdir ./images
    fi

    docker buildx build --no-cache --platform linux/$ARCH --output=type=docker --tag docker-awg:$ARCH-$NO_NAT-$ALPINE . && docker save docker-awg:$ARCH-$NO_NAT-$ALPINE > ./images/docker-awg-$ARCH-$NO_NAT-$ALPINE.tar
}

func_main $@
