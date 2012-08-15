#!/bin/zsh
if ! [ -w /usr/local ] || ! [ -d /usr/local ]
then
  echo "\033[0;31mYou don't have a /usr/local directory or it is not writable, please create it and make sure you have write permissions to it before running this script again.\033[0m"
  exit
fi

if [ -d ~/Tranquil ]
then
  echo "\033[0;31mYou already have something in ~/Tranquil.\033[0m\nYou'll need to rename that directory before you use this installation script."
  exit
fi

# Just for install count stats for me; completely anonymous.
curl "http://d.asgeirsson.is/JX9I"

echo "\033[0;32mI'm about to retrieve and compile Tranquil for you. This shouldn't take more than a few minutes,\ndepending on your connection.\n"

echo "\033[0;34mInstalling LLVM...\033[0m"
if [ -d /usr/local/llvm ]
then
  echo "\033[0;32mYou already have llvm installed to /usr/local/llvm.\033[0m\n\033[0;31mIf it's not version 3.1, you might have compatibility problems.\033[0m"
else
    curl http://llvm.org/releases/3.1/clang+llvm-3.1-x86_64-apple-darwin11.tar.gz -o /tmp/llvm3.1.tgz
    tar -C /usr/local -xzf /tmp/llvm3.1.tgz
    mv /usr/local/clang+llvm-3.1-x86_64-apple-darwin11 /usr/local/llvm
fi

echo "\n\033[0;34mInstalling Greg the parser generator...\033[0m"
if [ -d /usr/local/greg ]
then
  echo "\033[0;32mYou already have greg installed.\033[0m"
else
    git clone https://github.com/nddrylliog/greg.git /tmp/greg-git
    pushd /tmp/greg-git
    make
    mkdir -p /usr/local/greg/bin
    cp greg /usr/local/greg/bin
fi

echo "\n\033[0;34mCloning Tranquil from GitHub...\033[0m"

hash git >/dev/null && /usr/bin/env git clone git://github.com/fjolnir/Tranquil.git ~/Tranquil || {
  echo "\033[0;31mgit not installed\033[0m"
  exit
}

echo "\033[0;34mCompiling...\033[0m"
pushd ~/Tranquil
rake
popd

echo "\n\033[0;32mCongratulations!\n\033[0;33mYou can now find the Tranquil binary at '\033[0m~/Tranquil/Build/tranquil\033[0;33m'\033[0m"


