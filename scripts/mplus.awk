#!/bin/gawk -f

$0 !~ /font-family|src/ { print $0 }

$0 ~ /font-family/ {
	getline src
	match(src, /\((.*)\)/, a)
	split(a[1], a, " ")
	sub(/"(.*) Nerd/, "\"mplus " a[2] " Nerd")
	print $0
	print src
}
