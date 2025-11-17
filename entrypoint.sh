#!/bin/sh
# shellcheck disable=SC2016

HELP='Usage: /entrypoint.sh [COMMAND [PARAMS..]]

Commands:
    add-user NAME [PASS]    Add a new user
    del-user NAME           Delete an existing user
    start                   Start the dante server
                            [container command]

Parameters:
    NAME                    A username
                            [default: "socks" or ENV USERNAME]
    PASS                    A password
                            [default: random or ENV PASSWORD]
'

function adduserFn(){
    
    USER="$1"
    if [ -z "$USER" ]; then
        USER="$USERNAME"
        if [ -z "$USER" ]; then
            echo "No user"
            return 1
        else    
            echo "Using username from env $USER"
        fi
    else
        echo "Using username from arg $USER"
    fi
    

    PASS=$(echo "$2" | xargs)
    if [ -z "$PASS" ]; then
        PASS="$PASSWORD"
        if [ -z "$PASS" ]; then
            PASS=$(openssl rand -base64 16)
            echo "Using random password from $PASS"
        else
            echo "Using password from env ****"
        fi
    else
        echo "Using password from arg"
    fi
    
    echo "Adding user $USER"
    adduser --quiet --system --no-create-home "$USER"
    echo "$USER:$PASS" | chpasswd

    echo 'SOCKS5 connection parameters:'
    echo "- Server:   HOST:1080"
    echo "- Username: $USER"
    echo "- Password: ****"
    echo
    echo 'Test it using the following command:'
    echo "curl --socks5 $USER:****@$HOST:1080 -L <URL>"
}


case "$1" in
    'add-user-start')
        echo "Calling adduserFn"

        adduserFn $2 $3
        if [ $? -ne 0 ]; then
            echo "Adding user failed"
            exit 1
        fi

        danted -N "$WORKERS" -f "$CONFIG"
        ;;
    'add-user')
        adduserFn $2 $3
        if [ $? -ne 0 ]; then
            echo "Adding user failed"
            exit 1
        fi
        ;;
    'del-user')
        deluser --quiet --system "$2" 2> /dev/null
        ;;
    'start')
        danted -N "$WORKERS" -f "$CONFIG"
        ;;
    *)
        echo "$HELP"
        ;;
esac
