#!/bin/sh

_contains() {
	[ "${1#*$2}" != "$1" ] && return 0 || return 1
}

_get_stretch() {
	{ _contains "$1" "UltraCondensed" || _contains "$1" "Ultra Condensed" ;} &&
		printf "ultra-condensed\\n" && return 0

	{ _contains "$1" "ExtraCondensed" || _contains "$1" "Extra Condensed" ;} &&
		printf "extra-condensed\\n" && return 0

	{ _contains "$1" "SemiCondensed" || _contains "$1" "Semi Condensed" ;} &&
		printf "semi-condensed\\n" && return 0

	_contains "$1" "Condensed" && printf "condensed\\n" && return 0

	{ _contains "$1" "SemiExpanded" || _contains "$1" "Semi Expanded" ;} &&
		printf "semi-expanded\\n" && return 0

	{ _contains "$1" "ExtraExpanded" || _contains "$1" "Extra Expanded" ;} &&
		printf "extra-expanded\\n" && return 0

	{ _contains "$1" "UltraExpanded" || _contains "$1" "Ultra Expanded" ;} &&
		printf "ultra-expanded\\n" && return 0

	_contains "$1" "Expanded" && printf "expanded\\n" && return 0

	printf "normal\\n" && return 0
}

_get_style() {
	_contains "$1" "Italic" && printf "italic\\n" && return 0

	_contains "$1" "Oblique" && printf "oblique\\n" && return 0

	printf "normal\\n" && return 0
}

_get_weight() {
	{ _contains "$1" "Thin" || _contains "$1" "Hairline" ;} &&
		printf "100\\n" && return 0

	{ _contains "$1" "ExtraLight" || _contains "$1" "Extra Light" ||
	  _contains "$1" "UltraLight" || _contains "$1" "Ultra Light" ;} &&
		printf "200\\n" && return 0

	_contains "$1" "Light" && printf "300\\n" && return 0

	_contains "$1" "Medium" && printf "500\\n" && return 0

	{ _contains "$1" "SemiBold" || _contains "$1" "Semi Bold" ||
	  _contains "$1" "DemiBold" || _contains "$1" "Demi Bold" ;} &&
		printf "600\\n" && return 0

	{ _contains "$1" "ExtraBold" || _contains "$1" "Extra Bold" ||
	  _contains "$1" "UltraBold" || _contains "$1" "Ultra Bold" ;} &&
		printf "800\\n" && return 0

	_contains "$1" "Bold" && printf "700\\n" && return 0

	{ _contains "$1" "Black" || _contains "$1" "Heavy" ;} &&
		printf "900\\n" && return 0

	printf "400\\n" && return 0
}

_main() {
	if [ -z "$TOKEN" ]
	then
		fonts=$(curl -Ls https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | jq -r '.assets | map(.browser_download_url) | @sh')
	else
		fonts=$(curl -H "Authorization: token $TOKEN" -Ls https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | jq -r '.assets | map(.browser_download_url) | @sh')
	fi

	for f in $fonts
	do
		url=$(echo $f | tr -d "'")
		name=${url##*/}
		base=${name%.*}

		[ -n "$UPGRADE" ] && curl -LO "$url"

		if [ -n "$EXTRACT" ]
		then
			aunpack "$name"
			find "$name" -type f -iname "*Windows Compatible*" -delete
			find "$name" -type f -iname "*.otf" -delete
		fi

		if [ -n "$CONVERT" ] || [ -n "$GENERATE" ]
		then
			cd "$base"
			for file in ./*.ttf
			do
				if [ -f "$file" ]
				then
					if [ -n "$CONVERT" ]
					then
						printf "Converting $file...\\n"
						fontforge -quiet -lang=ff -c "Open(\$1); Generate(\$1:r + \".woff2\")" "$file" 2>/dev/null
					fi

					if [ -n "$GENERATE" ]
					then
						printf "Generating CSS for ${file%.*}...\\n"
						basen="$(basename "$file")"
						family="$(fontforge -lang=ff -c "Open(\$1); Print(\$familyname);" "$file" 2>/dev/null)"
						stretch="$(_get_stretch "$file")"
						style="$(_get_style "$file")"
						weight="$(_get_weight "$file")"

						awk_script="$(readlink -f "$BASEDIR/scripts/$(printf "$base" | tr '[:upper:] ' '[:lower:]-').awk")"
						[ -f "$awk_script" ] && builder="awk -f $awk_script" || builder="cat"
						css="$($builder << EOF
@font-face {
    font-family: "$family";
    src:    local(${basen%.*}),
            url("fonts/${basen%.*}.woff2") format("woff2"),
            url("fonts/$basen") format("truetype");
    font-stretch: $stretch;
    font-style: $style;
    font-weight: $weight;
}
EOF
)"
						printf "$css\\n" >> "$BUILDDIR/nerdfont-webfonts.css"
						printf "$css\\n" >> "$BUILDDIR/$(printf "$family" | tr '[:upper:] ' '[:lower:]-').css"
					fi
				fi
			done
			cd "$FONTDIR"
		fi
	done
}

while getopts 'acef:ght:u' o
do
	case "$o" in
		a) CONVERT=1; EXTRACT=1; GENERATE=1; UPGRADE=1 ;;
		c) CONVERT=1 ;;
		e) EXTRACT=1 ;;
		f) FONTDIR="$(readlink -f "$OPTARG")" ;;
		g) GENERATE=1 ;;
		t) TOKEN="$OPTARG" ;;
		u) UPGRADE=1 ;;
	esac
done


if [ -d "$FONTDIR" ]
then
	BASEDIR="$(dirname "$(readlink -f "$0")")"
	BUILDDIR="$(readlink -f "$BASEDIR/build")"
	cd "$FONTDIR"
	_main
else
	cat << EOF
nfwf: Nerd Font Web Fonts

Flags:
  -a	Enable all actions
  -c	Enable convert action
  -e	Enable extract action
  -f	Fonts directory
  -g	Enable generate action
  -h	Display this help menu
  -t	GitHub API Token
  -u	Enable upgrade action
EOF
	exit 1
fi
