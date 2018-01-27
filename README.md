This is a quick and dirty working environment to get
zenbuild going on Softiron.

Prerequisites:
Requires at least docker, git and gnu make to be installed on the host
machine.

Put the following in your .profile or equivalent:

export ALPINE_SDK_DIR=$HOME/..../zdk #Path where you're reading this file.
export PATH=$PATH:$ALPINE_SDK_DIR



Now you can invoke the 'zmake' script from the zenbuild directory:

host:~/.../zenbuild$ 'zmake pkgs'

... and off you go!
