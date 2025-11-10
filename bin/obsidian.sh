#sudo nohup /Applications/Obsidian.app/Contents/MacOS/Obsidian
#sudo nohup /Applications/Obsidian.app/Contents/MacOS/Obsidian \
#  > "/tmp/obsidian.log" 2>&1 &

sudo -b nohup /Applications/Obsidian.app/Contents/MacOS/Obsidian > /tmp/obsidian.log 2>&1

# Optional: Save PID to kill later
echo $! > "$HOME/obsidian.pid"

