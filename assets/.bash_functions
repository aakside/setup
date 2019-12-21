npm() {
  if [[ $@ == "install" && ! -d "node_modules" ]]; then
    # https://help.dropbox.com/files-folders/restore-delete/ignored-files
    command mkdir node_modules && xattr -w com.dropbox.ignored 1 node_modules
  fi
  command npm "$@"
}
