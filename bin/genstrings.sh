#/bin/bash

export SDK_DIR="`dirname $PROJECT_FILE_PATH`/Source"

rm -f Localizable.strings

echo "Generating strings…"
for file in $SDK_DIR/**.swift $SDK_DIR/**/*.swift; do
    echo "Processing $file"
    case "$file" in
    "./Source/Localization.swift")
    echo "Ignoring file."
    ;;
    *)
    genstrings -a -u -s LocalizedString "$file"
    ;;
    esac
done

echo "Copying strings as default to English localization…"
mkdir -p en.lproj
cp -f Localizable.strings en.lproj/Kwizzad.strings

echo "Converting files to UTF-8 if necessary…"
for file in *.strings *.lproj/*.strings; do
  encoding=`file -I $file | cut -f 2 -d";" | cut -f 2 -d=`
  case $encoding in
    utf-16le)
    echo "Converting $file to UTF-8..."
    iconv -f utf-16 -t utf-8 "$file" >> "$file.utf8"
    rm "$file"
    mv "$file.utf8" "$file"
    ;;
  esac
done

rm -f Localizable.strings
rm -f Kwizzad.strings
