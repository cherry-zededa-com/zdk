zdk contains the basic set of tools required to build
zenbuild. In order to use zdk, the host computing environment needs to
have the following tools installed by default:

     - docker
     - git
     - GNU make

Put the following in your .profile or equivalent:

export ALPINE_SDK_DIR=$HOME/..../zdk #Path where you're reading this file.
export PATH=$PATH:$ALPINE_SDK_DIR
export ALPINE_SDK_USER=root	     #This prevents permissions
       				      related issues. If you want to
				      run as the user+group you run as
				      on the host machine, then do not
				      use this line

Now you can invoke the 'zmake' script from the zenbuild directory:

host:~/.../zenbuild$ 'zmake pkgs'

... and off you go!
