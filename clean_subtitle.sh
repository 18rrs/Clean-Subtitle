#!/bin/bash
# Cleans SRT-formatted subtitles of common unwanted ads or texts.
# Useful as a post-process script for Bazarr, Sub-Zero, or other subtitle managers.
# Please retain or modify the regex to give proper credit to the hard work of subtitle providers.

### Usage:
# Download this file:
#   curl -O /sub-clean.sh && chmod +x sub-clean.sh
# Run the script across a media library:
#   find /path/to/library -name '*.srt' -exec /path/to/sub-clean.sh "{}" \;
# Use in Bazarr:
#   /path/to/sub-clean.sh "{{subtitles}}" --
# Use in Sub-Zero:
#   /path/to/sub-clean.sh %(subtitle_path)s

# Specify file permissions
CHMOD=644

# Input file
SUB_FILEPATH="$1"

# Ensure a valid input file
if [ ! -f "$SUB_FILEPATH" ]; then
    echo "Error: Subtitle file does not exist or was not provided."
    echo "Usage: sub-clean.sh [FILE]"
    exit 1
fi

# Ensure the file has a .srt extension
if [[ "$SUB_FILEPATH" != *.srt ]]; then
    echo "Error: Provided file must have a .srt extension."
    exit 1
fi

# Define regex patterns for removal
REGEX_TO_REMOVE='(br|dvd|web).?(rip|scr)|english (- )?us|sdh|srt|(yahoo|mail|book|fb|4m|hd)\. ?com|(sub(title)?(bed)?(s)?(fix)?|encode(d)?|correct(ed|ion(s)?)|caption(s|ed)|sync(ed|hroniz(ation|ed))?|english)(.pr(esented|oduced))?.?(by|&)|[^a-z]www\.|http|\. ?(co|pl|link|org|net|mp4|mkv|avi|pdf)([^a-z]|$)|\u00A9|\u2122'
REGEX_TO_REMOVE2='subs\.ro|subtitrari-noi|opensubtitles|sub(scene|rip)|podnapisi|addic7ed|titlovi|bozxphd|sazu489|psagmeno|normita|anoxmous|isubdb|americascardroom'

# Convert DOS line endings to UNIX
awk '{ sub("\r$", ""); print }' "$SUB_FILEPATH" > "${SUB_FILEPATH}.tmp" && mv "${SUB_FILEPATH}.tmp" "$SUB_FILEPATH"

# Function to clean subtitles with regex
clean_subtitles() {
    local file="$1"
    local regex="$2"

    awk -v RS='' -v FS='\n' -v OFS='\n' -v ORS='\n\n' -v VAR=1 -v TRASH="${file}.trash.tmp" \
        'tolower($0) !~ /'"$regex"'/ {
            $1 = VAR++ ; print ; next
        } {
            print >> TRASH
        }' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
}

# Clean subtitles using the defined regex patterns
clean_subtitles "$SUB_FILEPATH" "$REGEX_TO_REMOVE"
clean_subtitles "$SUB_FILEPATH" "$REGEX_TO_REMOVE2"

# Apply specified permissions to the cleaned file
chmod "$CHMOD" "$SUB_FILEPATH"

# Display removed lines, if any
if [ -f "${SUB_FILEPATH}.trash.tmp" ]; then
    REMOVED_LINES=$(<"${SUB_FILEPATH}.trash.tmp")
    rm "${SUB_FILEPATH}.trash.tmp"

    if [ "$REMOVED_LINES" ]; then
        echo "The following lines were removed:"
        echo "$REMOVED_LINES"
    fi
fi

# Success message
echo "sub-clean.sh successfully processed $SUB_FILEPATH"
