#!/bin/bash
# decrypt with ssh
# https://www.bjornjohansen.com/encrypt-file-using-ssh-key

set -e

if [ -z "$1" ]; then
	echo "usage: $0 <file-to-decrypt>"
	exit 1
fi

encryptedfile=$1
encryptedkeyfile=${encryptedfile/.enc/}.key.enc

secretkeyfile=$(mktemp /tmp/$(basename $encryptedfile).XXXXXX)

decryptedfile=${encryptedfile/.enc/}
privatekey="$HOME/.ssh/id_rsa"

openssl pkeyutl -decrypt -pkeyopt rsa_padding_mode:oaep -inkey $privatekey -in $encryptedkeyfile -out $secretkeyfile

openssl aes-256-cbc -pbkdf2 -d -in $encryptedfile -out $decryptedfile -pass file:$secretkeyfile

rm -f $secretkeyfile
echo "decrypted [$encryptedfile] to [$decryptedfile]"