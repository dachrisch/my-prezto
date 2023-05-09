#!/bin/bash
# encrypt with ssh
# https://www.bjornjohansen.com/encrypt-file-using-ssh-key

set -e

if [ -z "$1" ]; then
	echo "usage: $0 <file-to-encrypt>"
	exit 1
fi

secretfile=$1
secretkeyfile=$(mktemp /tmp/"$(basename $secretfile)".XXXXXX)

encryptedfile=$(basename "$secretfile").enc
encryptedkeyfile=$(basename "$secretfile").key.enc
publickey="$HOME/.ssh/id_rsa.pub"

openssl rand -out "$secretkeyfile" 32

openssl aes-256-cbc -pbkdf2 -in "$secretfile" -out "$encryptedfile" -pass file:"$secretkeyfile"

openssl pkeyutl -encrypt -pkeyopt rsa_padding_mode:oaep -pubin -inkey <(ssh-keygen -e -f "$publickey" -m PKCS8) -in "$secretkeyfile" -out "$encryptedkeyfile"

echo "encrypted [$secretfile] to [$encryptedfile] using encrypted key [$encryptedkeyfile]"