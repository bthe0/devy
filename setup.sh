#!/bin/bash

echo "Setting up development environment..."

# Install required packages
brew install \
    clipy \
    ffmpeg \
    imagemagick \
    pandoc \
    ghostscript \
    duti

# Set up VS Code first
echo "Setting up VS Code to show ALL hidden files and folders..."

# Install VS Code extensions
code --install-extension dbaeumer.vscode-eslint
code --install-extension esbenp.prettier-vscode

# Create VS Code settings
mkdir -p ~/Library/Application\ Support/Code/User/
cat > ~/Library/Application\ Support/Code/User/settings.json << 'EOL'
{
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.fixAll.eslint": true
    },
    "files.excludes": {},
    "files.showHiddenFiles": true,
    "explorer.excludeGitIgnore": false,
    "explorer.autoReveal": true,
    "explorer.compactFolders": false,
    
    "files.exclude": {
        "**/.git": false,
        "**/.svn": false,
        "**/.hg": false,
        "**/CVS": false,
        "**/.DS_Store": false,
        "**/Thumbs.db": false,
        "**/.vscode": false,
        "**/node_modules": false,
        "**/.idea": false,
        "**/.next": false,
        "**/.env": false,
        "**/.env.*": false,
        "**/build": false,
        "**/dist": false,
        "**/.gitignore": false,
        "**/.gitattributes": false,
        "**/.eslintrc": false,
        "**/.prettierrc": false,
        "**/package-lock.json": false,
        "**/yarn.lock": false
    },

    "prettier.singleQuote": true,
    "prettier.trailingComma": "es5",
    "[javascript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[typescript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[json]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    
    "telemetry.telemetryLevel": "off"
}
EOL

# Set VS Code as default text editor and for development files
echo "Setting VS Code as default text editor and for development files..."

# VS Code bundle identifier
VSCODE_ID="com.microsoft.VSCode"

# Set VS Code as default text editor
defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerContentType=public.plain-text;LSHandlerRoleAll=com.microsoft.VSCode;}'
defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerContentType=public.unix-executable;LSHandlerRoleAll=com.microsoft.VSCode;}'
defaults write com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers -array-add '{LSHandlerContentType=public.source-code;LSHandlerRoleAll=com.microsoft.VSCode;}'

# Common development file extensions
declare -a extensions=(
    # Basic text files
    "txt" "text" "rtf" "json" "csv" "log"
    
    # Web development
    "html" "htm" "css" "js" "jsx" "ts" "tsx" "json" "xml" "svg"
    "vue" "svelte" "php" "asp" "aspx" "jsp"
    
    # Config files
    "env" "gitignore" "yml" "yaml" "toml" "conf" "config" "ini"
    "properties" "prefs" "htaccess" "lock" "npmrc" "nvmrc"
    
    # Documentation
    "md" "markdown" "rst" "asciidoc" "adoc" "textile"
    
    # Programming languages
    "py" "java" "cpp" "c" "hpp" "h" "cs" "php" "rb" "go" "rs" "swift"
    "scala" "pl" "pm" "r" "rake" "coffee" "elm" "ex" "exs"
    
    # Shell scripts
    "sh" "bash" "zsh" "fish" "command" "bat" "cmd"
    
    # Development configs
    "eslintrc" "prettierrc" "babelrc" "editorconfig"
    "dockerignore" "nginx" "prisma" "graphql"
    "stylelintrc" "prettierignore" "eslintignore"
    
    # Data formats
    "xml" "xsl" "xslt" "dtd" "sql" "plist"
)

for ext in "${extensions[@]}"; do
    # Set VS Code as default for the extension
    duti -s $VSCODE_ID .$ext all 2>/dev/null
    
    # Verify the change
    current_handler=$(duti -x .$ext 2>/dev/null)
    if [[ $current_handler == *"Visual Studio Code"* ]]; then
        echo "✓ .$ext → VS Code"
    else
        echo "⚠️  Failed to set VS Code as default for .$ext"
    fi
done

# Force update Launch Services
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user

# Set up functions and aliases
cat >> ~/.zshrc << 'EOL'

# Directory shortcuts
alias dev='cd ~/Development'
alias doc='cd ~/Documents'
alias dl='cd ~/Downloads'

# Kill process on port
killport() {
    if [ -z "$1" ]; then
        echo "Usage: killport <port_number>"
        return 1
    fi
    
    local pid=$(lsof -ti:$1)
    if [ -n "$pid" ]; then
        echo "Killing process on port $1 (PID: $pid)"
        kill -9 $pid
        echo "Process killed"
    else
        echo "No process found on port $1"
    fi
}

# File converter utility
x() {
    local recursive=false

    # Parse options
    while getopts "r" opt; do
        case $opt in
            r) recursive=true ;;
            \?) echo "Invalid option: -$OPTARG" >&2; return 1 ;;
        esac
    done
    shift $((OPTIND-1))

    if [ "$#" -lt 2 ]; then
        echo "Usage: x [-r] <input_file/directory> <from_extension> <to_extension>"
        echo "Options:"
        echo "  -r : Recursive (process subdirectories)"
        echo "Examples:"
        echo "  x file.jpg png          # Convert single image"
        echo "  x folder jpg png        # Convert all jpg files in folder to png"
        echo "  x -r folder jpg png     # Convert all jpg files in folder and subfolders"
        echo "  x document.docx pdf     # Convert document to PDF"
        echo "  x audio.mp3 wav         # Convert audio format"
        echo "  x video.mp4 mkv         # Convert video format"
        return 1
    fi

    input="$1"
    from_ext="${2#.}"
    to_ext="${3#.}"

    # Function to convert a single file
    convert_file() {
        local input="$1"
        local to_ext="$2"
        local output="${input%.*}.$to_ext"

        case "$to_ext" in
            # Image conversions
            jpg|jpeg|png|gif|webp|bmp|tiff)
                convert "$input" "$output"
                ;;
            
            # Document conversions
            pdf)
                case "${input##*.}" in
                    docx|doc) pandoc "$input" -o "$output" ;;
                    *) convert "$input" "$output" ;;
                esac
                ;;
            
            # Audio conversions
            mp3|wav|ogg|flac|m4a|aac)
                ffmpeg -i "$input" -y "$output"
                ;;
            
            # Video conversions
            mp4|mkv|avi|mov|webm)
                ffmpeg -i "$input" -y "$output"
                ;;
            
            *)
                echo "Unsupported conversion format: $to_ext"
                return 1
                ;;
        esac

        if [ $? -eq 0 ]; then
            echo "Converted: $input → $output"
        else
            echo "Failed to convert: $input"
        fi
    }

    # Handle directory or single file
    if [ -d "$input" ]; then
        if [ -z "$to_ext" ]; then
            echo "Error: When converting a directory, both from and to extensions are required"
            return 1
        fi
        if [ "$recursive" = true ]; then
            find "$input" -type f -name "*.$from_ext" | while read file; do
                convert_file "$file" "$to_ext"
            done
        else
            for file in "$input"/*."$from_ext"; do
                if [ -f "$file" ]; then
                    convert_file "$file" "$to_ext"
                fi
            done
        fi
    elif [ -f "$input" ]; then
        convert_file "$input" "$from_ext"  # for single file, second argument is the target extension
    else
        echo "Error: Input '$input' is not a valid file or directory"
        return 1
    fi
}

# Password generator
pass() {
    length="${1:-32}"
    openssl rand -base64 48 | cut -c1-$length
}

# Universal archive extractor
extract() {
    if [ -z "$1" ]; then
        echo "Usage: extract <file>"
        return 1
    fi
    
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"   ;;
            *.7z)        7z x "$1"        ;;
            *)          echo "'$1' cannot be extracted via extract" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Universal compression
compress() {
    if [ -z "$1" ]; then
        echo "Usage: compress <file/directory> [output_name]"
        return 1
    fi
    
    local input="$1"
    local output="${2:-${1%/}}.zip"
    
    if [ -f "$input" ] || [ -d "$input" ]; then
        zip -r "$output" "$input"
    else
        echo "'$input' is not a valid file or directory"
    fi
}
EOL

# Set better macOS defaults
echo "Setting macOS defaults..."

# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show all hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show path bar in Finder
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar in Finder
defaults write com.apple.finder ShowStatusBar -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Save screenshots to Downloads folder
defaults write com.apple.screencapture location ~/Downloads

# Show battery percentage in menu bar
defaults write com.apple.menuextra.battery ShowPercent -string "YES"

# Enable key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Set faster key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Create Development directory
mkdir -p ~/Development

# Restart Finder for changes to take effect
killall Finder

echo "Setup complete! Please restart your terminal and computer for all changes to take effect."
echo ""
echo "Available commands:"
echo "- x [-r] file.jpg png     : Convert single file to another format"
echo "                            Use -r for recursive directory conversion"
echo "- pass [length]           : Generate secure password (default 32 characters)"
echo "- extract file            : Extract any archive type"
echo "- compress file/dir       : Create zip archive"
echo "- killport <port>         : Kill process running on specified port"
echo "- dev                     : Go to Development directory"
echo "- doc                     : Go to Documents directory"
echo "- dl                      : Go to Downloads directory"
echo ""
echo "VS Code has been configured to:"
echo "- Show ALL hidden files and folders"
echo "- Format on save with Prettier"
echo "- Fix ESLint issues on save"
echo "- Be the default text editor for all supported files"
echo ""
echo "Supported conversions:"
echo "- Images: jpg, png, gif, webp, bmp, tiff"
echo "- Documents: doc/docx to pdf"
echo "- Audio: mp3, wav, ogg, flac, m4a, aac"
echo "- Video: mp4, mkv, avi, mov, webm"
echo ""
echo "Note: You may need to restart your computer for all file associations to take effect."