#!/bin/sh

if [ -n "${DEBUG+1}" ]; then
	set -x
fi

set -a

BASE_DIR="$(dirname "$(readlink -f "$0")")"
BUILD_DIR="$(readlink -f "$BASE_DIR/build")"
FONTS_DIR="$(readlink -f "$BASE_DIR/nerd-fonts")"

set_action() {
	if [ -n "${action+x}" ] && [ "$action" != "$1" ]; then
		printf "Running %s with %s...\n" "$1" "$action"
		printf "Incompatible options given. Only one action may be specified per run.\n"
		exit 1
	else
		action="$1"
	fi
}

contains() {
	[ "${1#*"$2"}" != "$1" ] && return 0 || return 1
}

get_stretch() {
	{ contains "$1" "UltraCondensed" || contains "$1" "Ultra Condensed"; } &&
		printf "ultra-condensed\\n" && return 0

	{ contains "$1" "ExtraCondensed" || contains "$1" "Extra Condensed"; } &&
		printf "extra-condensed\\n" && return 0

	{ contains "$1" "SemiCondensed" || contains "$1" "Semi Condensed"; } &&
		printf "semi-condensed\\n" && return 0

	contains "$1" "Condensed" && printf "condensed\\n" && return 0

	{ contains "$1" "SemiExpanded" || contains "$1" "Semi Expanded"; } &&
		printf "semi-expanded\\n" && return 0

	{ contains "$1" "ExtraExpanded" || contains "$1" "Extra Expanded"; } &&
		printf "extra-expanded\\n" && return 0

	{ contains "$1" "UltraExpanded" || contains "$1" "Ultra Expanded"; } &&
		printf "ultra-expanded\\n" && return 0

	contains "$1" "Expanded" && printf "expanded\\n" && return 0

	printf "normal\\n" && return 0
}

get_style() {
	contains "$1" "Italic" && printf "italic\\n" && return 0

	contains "$1" "Oblique" && printf "oblique\\n" && return 0

	printf "normal\\n" && return 0
}

get_weight() {
	{ contains "$1" "Thin" || contains "$1" "Hairline"; } &&
		printf "100\\n" && return 0

	{ contains "$1" "ExtraLight" || contains "$1" "Extra Light" || contains "$1" "UltraLight" || contains "$1" "Ultra Light"; } &&
		printf "200\\n" && return 0

	contains "$1" "Light" && printf "300\\n" && return 0

	contains "$1" "Medium" && printf "500\\n" && return 0

	{ contains "$1" "SemiBold" || contains "$1" "Semi Bold" || contains "$1" "DemiBold" || contains "$1" "Demi Bold"; } &&
		printf "600\\n" && return 0

	contains "$1" "Bold" && printf "700\\n" && return 0

	{ contains "$1" "ExtraBold" || contains "$1" "Extra Bold" || contains "$1" "UltraBold" || contains "$1" "Ultra Bold"; } &&
		printf "800\\n" && return 0

	{ contains "$1" "Black" || contains "$1" Heavy; } &&
		printf "900\\n" && return 0

	printf "400\\n" && return 0
}

upgrade() {
	if [ ! -d "$FONTS_DIR" ]; then
		mkdir "$FONTS_DIR"
	fi
	cd "$FONTS_DIR" || exit 1

	if [ -z "$gh_token" ]; then
		fonts_data=$(curl -Ls https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest)
	else
		fonts_data=$(curl -H "Authorization: token $gh_token" -Ls https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest)
	fi

	nf_fonts=$(printf "%s" "$fonts_data" | jq -r '.assets | map(select(.name | contains(".tar.xz"))) | map(.browser_download_url) | @sh')
	fonts_urls=$(printf "%s" "$nf_fonts" | tr -d "'" | sed 's/ / -: -LO /g')
	# shellcheck disable=SC2086
	curl -LO $fonts_urls

	cd "-" >/dev/null || exit 1
}

extract() {
	cd "$FONTS_DIR" || exit 1

	count=$(find . -maxdepth 1 -type f | wc -l)
	i=0
	for file in ./*.tar.xz; do
		i=$((i + 1))
		basename=$(printf "%s" "$file" | sed 's/.tar.xz//g')
		[ ! -d "$basename" ] && mkdir "$basename"
		printf "[%d/%d] %s...\n" "$i" "$count" "$basename"
		# shellcheck disable=SC2046
		tar -x -f "$file" -C "$basename" $(tar -t -f "$file" | grep '.*\.[ot]tf')
	done

	cd "-" >/dev/null || exit 1
}

convert() {
	cd "$FONTS_DIR" || exit 1

	font_files=$(find . -depth 2 -type f | sort)
	# shellcheck disable=SC2086
	parallel --progress "fontforge -lang=ff -c 'Open(\$1); Generate(\$1:r + \".woff2\");' {} 2>/dev/null" ::: $font_files

	cd "-" >/dev/null || exit 1
}

generate() {
	cd "$FONTS_DIR" || exit 1

	font_files=$(find . -depth 2 -type f | sort)
	count=$(printf "%s" "$font_files" | wc -l)
	i=0
	for file in $font_files; do
		i=$((i + 1))
		printf "[%d/%d] %s...\n" "$i" "$count" "$file"
		basen="$(basename "$file")"
		font="$(basename "$(dirname "$file")")"
		family="$(fontforge -lang=ff -c "Open(\$1); Print(\$familyname);" "$file" 2>/dev/null)"
		stretch="$(get_stretch "$file")"
		style="$(get_style "$file")"
		weight="$(get_weight "$file")"

		css="$(
			cat <<EOF
@font-face {
    font-family: "$family";
    src:    local("${basen%.*}"),
            url("fonts/${basen%.*}.woff2") format("woff2");
    font-stretch: $stretch;
    font-style: $style;
    font-weight: $weight;
}
EOF
		)"

		printf "%s\\n" "$css" >>"$BUILD_DIR/nerdfont-webfonts.css"
		printf "%s\\n" "$css" >>"$BUILD_DIR/$(printf "%s" "$font" | tr '[:upper:] ' '[:lower:]-').css"
		printf "%s\\n" "$css" >>"$BUILD_DIR/$(printf "%s" "$family" | tr '[:upper:] ' '[:lower:]-').css"
	done

	cd "-" >/dev/null || exit 1
}

docfonts() {
	cd "$FONTS_DIR" || exit 1

	cat >"$BASE_DIR/fonts.md" <<EOF
# Fonts

| Superfamily | CSS File |
| ----------- | -------- |
EOF

	font_dirs=$(find . -depth 1 -type d | sort)
	count=$(printf "%s" "$font_dirs" | wc -l)
	i=0
	for dir in $font_dirs; do
		i=$((i + 1))
		printf "[%d/%d] %s...\n" "$i" "$count" "$dir"
		font="$(basename "$dir")"
		file="$(printf "%s" "$font" | tr '[:upper:] ' '[:lower:]-').css"

		md="$(
			cat <<EOF
| $font | [\`$file\`](./build/$file) |
EOF
		)"

		printf "%s\\n" "$md" >>"$BASE_DIR/fonts.md"
	done
}

info() {
	cat <<EOF
nfwf: Nerd Font Web Fonts

Actions:
  -c    Convert local nerd fonts to woff2
  -d    Generate fonts.md
  -e    Extract local archives
  -g    Generate font face at-rules
  -u    Fetch latest nerd fonts from upstream

Options:
  -f    Fonts directory
  -t    GitHub API Token

Dependencies:
  curl          $(which curl)
  fontforge     $(which fontforge)
  jq            $(which jq)
  parallel      $(which parallel)
  tar           $(which tar)
EOF
}

while getopts "cdeght:u" o; do
	case "$o" in
	c) set_action convert ;;
	d) set_action docfonts ;;
	e) set_action extract ;;
	g) set_action generate ;;
	h) set_action info ;;
	t) gh_token="$OPTARG" ;;
	u) set_action upgrade ;;
	\?)
		printf "See \`%s -h\` for possible options and help.\n" "$(basename "$0")"
		exit 1
		;;
	esac
done

[ -z "$action" ] && action="info"

case "$action" in
convert) convert ;;
docfonts) docfonts ;;
extract) extract ;;
generate) generate ;;
upgrade) upgrade ;;
info)
	info
	exit 1
	;;
esac
