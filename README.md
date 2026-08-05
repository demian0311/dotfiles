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

`claude/` goes into `~/.claude/` two different ways, because the two kinds of
file behave differently. Run the installer rather than doing it by hand:

``` bash
~/code/dotfiles/claude/install.sh          # --quiet reports repairs only
```

`CLAUDE.md` uses Claude Code's own memory-import syntax: `~/.claude/CLAUDE.md`
is a regular one-line file reading `@/Users/demian/code/dotfiles/claude/CLAUDE.md`.
Nothing is linked, so nothing can be replaced. If Claude Code appends a memory to
the global file, it lands in the pointer, and the installer moves those lines into
the tracked copy instead of dropping them.

Everything else is symlinked. `settings.json` has no import mechanism, so it has
to be, and a settings write that replaces the file would leave a plain file where
the link was. The installer adopts such a file back into the repo before
re-linking, so the newer version wins instead of being clobbered by a stale repo
copy; the displaced file is kept as `~/.claude/<name>.bak-<timestamp>`.

A `SessionStart` hook runs `install.sh --quiet`, so drift is repaired at the start
of every Claude session and prints nothing unless something needed fixing. Still
worth a `git status` here after changing settings — a repair updates the repo but
does not commit it.
-- 

- [ ] Need to commit Nord color for vim
