#!/usr/bin/env sh

# Tool to install/remove commands to a-Shell
#
# options:
# install packageName: pull server/packageName.pkg, execute script packageName.pkg, create .pkg/packageName
# remove packageName: execute .pkg/packageName
# list: show all installed packages
# search + regexp: pull list from server, grep with regexp

# main url. Can be overidden by environment variable
if [ -z "$PKG_SERVER" ]
then
	server=https://raw.githubusercontent.com/holzschu/a-Shell-commands/master/
else
	server=$PKG_SERVER
fi

usage() {
cat << 'EOF'
Usage: pkg [install name] [remove name] [list] [search expression]
  install: installs package "name"
  remove: removes package "name"
  list: list all installed packages
  search: lists packages matching expression

  pkg will search for packages on $PKG_SERVER, if it set, and https://raw.githubusercontent.com/holzschu/a-Shell-commands/master/ otherwise
EOF
}

list() {
	if [ -d ~/Documents/.pkg ]
	then
		ls -1 ~/Documents/.pkg/	
	else
		echo No packages installed yet
	fi
}

search() {
	echo Packages available:
	if [ -z $1 ]
	then
		curl -L $server/list --silent
	else
		expression=$1
		curl -L $server/list --silent | grep $expression
	fi
}

install() {
	for name in $@
	do
		if [ $# -ge 2 ]
		then
			echo Processing $name
		fi
		curl -L $server/list --silent | grep ^$name > ~/tmp/packageList
		length=`wc -l < ~/tmp/packageList`
		if [ $length -eq 0 ]
		then
			echo Package $name not found
		elif [ $length -eq 1 ]
		then
			packageName=`cat ~/tmp/packageList`
			echo Downloading $packageName
			curl -L $server/packages/$packageName -o ~/tmp/$packageName --silent
			chmod +x ~/tmp/$packageName
			sh ~/tmp/$packageName
			rm ~/tmp/$packageName
			rehash
			echo Done
		else
			packageFound=0
			for packageName in `cat ~/tmp/packageList`
			do
				if [ $packageName = $name ]
				then
					echo Downloading $packageName
					curl -L $server/packages/$packageName -o ~/tmp/$packageName --silent
					chmod +x ~/tmp/$packageName
					sh ~/tmp/$packageName
					rm ~/tmp/$packageName
					rehash
					packageFound=1
					echo Done
					break
				fi
			done
			if [ $packageFound -eq 0 ]
			then
				echo Package name $name unclear. Did you mean:
				cat ~/tmp/packageList
			fi
		fi
		rm ~/tmp/packageList
	done
}

remove() {
	for name in $@
	do
		if [ $# -ge 2 ]
		then
			echo Processing $name
		fi
		if [ -f ~/Documents/.pkg/$name ]
		then
			echo Removing $name
			sh ~/Documents/.pkg/$name
			rm ~/Documents/.pkg/$name
			mandocdb ~/Library/man
			rehash
			echo Done
		else
			echo Package $name was not installed by pkg. Cannot remove it.
		fi
	done
}

case $1 in
	install|update|upgrade) 
	    shift
	    install $@
	    ;;
	list) list;;
	remove|uninstall) 
	    shift
	    remove $@
	    ;;
	search) search $2;;
	*) usage
esac
