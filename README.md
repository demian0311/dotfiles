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

`claude/` works the same way, one symlink per file into `~/.claude/` — except
`settings.json`, which Claude Code rewrites itself, so the repo keeps a copy
that has to be re-recorded by hand after settings changes.
-- 

- [ ] Need to commit Nord color for vim
