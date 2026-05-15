#!/bin/bash
echo "Downloading Hel-Chobby..."

# Download and extract
wget -q --show-progress -O luaui.zip 'https://github.com/Helwor/Hel-Chobby/archive/main.zip' && echo "" || {
    echo "Download failed. Aborting."
    exit 1
}

unzip -qo chobby.zip || {
	echo "Failed to extract package. Aborting."
	rm -f chobby.zip
	exit 1
}
rm -f chobby.zip

[ -f "Hel-Chobby-main/.gitignore" ] && rm "Hel-Chobby-main/.gitignore"

if [ ! -d "Hel-Chobby-main" ]; then
	echo "Failed to extract package. Aborting."
	exit 1
fi

# Handle removed files

if [ -f "helchobby_manifest.txt" ]; then
	echo "Checking removed files..."
	while IFS= read -r f; do
		new_path="Hel-Chobby-main/$f"
		if [ ! -f "$new_path" ] && [ -f "$f" ]; then
			n=1
			while [ -f "${f}.removed${n}" ]; do
				n=$((n + 1))
			done
			mv "$f" "${f}.removed${n}"
			echo -e "\e[31mREMOVED: $f\e[0m"
		fi
	done < helchobby_manifest.txt
fi

# Update files
echo "Checking existing files..."
find Hel-Chobby-main -type f | while read -r src; do
	rel="${src#Hel-Chobby-main/}"
	if [ -f "$rel" ]; then
		if ! cmp -s <(tr -d '\r' < "$src") <(tr -d '\r' < "$rel"); then
			n=1
			while [ -f "${rel}.backup${n}" ]; do
				n=$((n + 1))
			done
			mv "$rel" "${rel}.backup${n}"
			cp "$src" "$rel"
			echo -e "\e[33mUPDATED: $rel (created backup $n)\e[0m"
		fi
	else
		dir=$(dirname "$rel")
		[ -n "$dir" ] && mkdir -p "$dir"
		cp "$src" "$rel"
		echo -e "\e[32mNEW: $rel\e[0m"
	fi
done

# Generate manifest
find Hel-Chobby-main -type f | while read -r f; do
	echo "${f#Hel-Chobby-main/}"
done > helchobby_manifest.txt

# Cleanup
rm -rf Hel-Chobby-main
read -n 1 -s -r -p "Done!"