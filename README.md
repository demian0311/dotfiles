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
-- 

- [ ] Need to commit Nord color for vim
