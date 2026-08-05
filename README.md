Here are my dotfiles.  Very specific to my world.

## Installing
Haven't tried this for real but I think you want to do something like this.

``` bash
mkdir -p ~/code
cd ~code
git clone git@github.com:demian0311/dotfiles.git
ln -s /Users/demian/code/dotfiles/.bashrc .bashrc
ln -s /Users/demian/code/dotfiles/.vimrc .vimrc 
ln -s /Users/demian/code/dotfiles/.ideavimrc .ideavimrc 
```

## Config files

`config/` mirrors `~/.config/`, symlinked in. cmux and Ghostty read the live
paths; the repo holds the only copy.

``` bash
mkdir -p ~/.config/cmux ~/.config/ghostty
ln -s ~/code/dotfiles/config/cmux/cmux.json      ~/.config/cmux/cmux.json
ln -s ~/code/dotfiles/config/ghostty/config      ~/.config/ghostty/config
ln -s ~/code/dotfiles/config/ghostty/themes      ~/.config/ghostty/themes
```

`claude/` works the same way, one symlink per file into `~/.claude/`. Run the
linker instead of doing it by hand:

``` bash
~/code/dotfiles/claude/install.sh
```

It is idempotent, so re-running it is the fix for drift. That matters because
Claude Code rewrites `settings.json` when settings change, and a rewrite that
replaces the file leaves a regular file where the symlink was — edits then land
in `~/.claude` and never reach the repo. `install.sh` copies such a file back
into the repo before re-linking, so the newer version wins; the displaced file
is kept as `~/.claude/<name>.bak-<timestamp>`. Check `git status` here after
changing Claude settings.
-- 

- [ ] Need to commit Nord color for vim
