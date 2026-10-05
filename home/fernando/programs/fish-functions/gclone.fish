set -l name (path change-extension '' $argv | path basename)
echo -e '\n'
git clone $argv; or return $status
cd $name
