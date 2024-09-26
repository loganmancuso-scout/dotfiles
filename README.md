# DotFiles

```bash
git clone git@gitlab.com:loganmancuso_personal/dotfiles.git $HOME/SourceControl/Personal/dotfiles
pushd $HOME/SourceControl/Personal/dotfiles
./stow-dotfiles.sh --stow
git reset --hard
popd
```