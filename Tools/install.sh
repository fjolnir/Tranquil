#!/bin/zsh
if ! [ -w /usr/local ] || ! [ -d /usr/local ]
then
  echo "\033[0;31mYou don't have a /usr/local directory or it is not writable, please create it and make sure you have write permissions to it before running this script again.\033[0m"
  exit
fi

mkdir -p /usr/local/tranquil

# Just for install count stats for me; completely anonymous.
curl -fsSkL "http://d.asgeirsson.is/JX9I" > /dev/null

echo "\033[0;32mI'm about to retrieve and compile Tranquil for you. This shouldn't take more than a few minutes,\ndepending on your connection & hardware.\n"

echo "\033[0;34mInstalling LLVM...\033[0m"
if [ -d /usr/local/tranquil/llvm ]
then
  echo "\033[0;32mYou already have llvm installed.\033[0m"
else
    pushd /tmp
    curl http://llvm.org/releases/3.1/clang+llvm-3.1-x86_64-apple-darwin11.tar.gz -o llvm3.1.tgz
    tar -xzf llvm3.1.tgz
    mv clang+llvm-3.1-x86_64-apple-darwin11 /usr/local/tranquil/llvm
    popd
fi

echo "\n\033[0;34mInstalling Ragel\033[0m"
if [ -d /usr/local/tranquil/ragel ]
then
  echo "\033[0;32mYou already have ragel installed.\033[0m"
else
    pushd /tmp
    curl http://www.complang.org/ragel/ragel-6.7.tar.gz -o ragel-6.7.tgz
    tar -xzf ragel-6.7.tgz
    cd ragel-6.7
    ./configure --prefix=/usr/local/tranquil/ragel
    make
    make install
    popd
fi

echo "\n\033[0;34mInstalling Lemon\033[0m"
if [ -d /usr/local/tranquil/lemon ]
then
  echo "\033[0;32mYou already have lemon installed.\033[0m"
else
    pushd /tmp
    curl http://tx97.net/pub/distfiles/lemon-1.69.tar.bz2 -o lemon-1.69.tbz
    tar -xzf lemon-1.69.tbz
    cd lemon-1.69
    mkdir -p /usr/local/tranquil/lemon/bin
    /usr/local/tranquil/llvm/bin/clang lemon.c -o /usr/local/tranquil/lemon/bin/lemon
    cp lempar.c /usr/local/tranquil/lemon/bin
    popd
fi

echo "\n\033[0;34mInstalling GNU MP...\033[0m"
if [ -d /usr/local/tranquil/gmp ]
then
  echo "\033[0;32mYou already have GMP installed.\033[0m"
else
    pushd /tmp
    curl ftp://ftp.gmplib.org/pub/gmp-5.0.5/gmp-5.0.5.tar.bz2 -o gmp-5.0.5.tar.bz2
    tar xzf gmp-5.0.5.tar.bz2
    pushd gmp-5.0.5
    ./configure --with-pic --prefix=/usr/local/tranquil/gmp
    make
    make check
    make install
    popd
    popd
fi


if [ -d /usr/local/tranquil/src ]
then
    echo "\n\033[0;34mUpdating Tranquil...\033[0m"
    pushd /usr/local/tranquil/src
    git pull
    popd
else
    echo "\n\033[0;34mCloning Tranquil from GitHub...\033[0m"
    hash git >/dev/null && /usr/bin/env git clone git://github.com/fjolnir/Tranquil.git /usr/local/tranquil/src || {
      echo "\033[0;31mgit not installed\033[0m"
      exit
    }
fi

echo "\033[0;34mCompiling...\033[0m"
pushd /usr/local/tranquil/src/
rake || {
  echo "\033[0;31mError building tranquil!\033[0m"
  exit
}
popd

echo "\n\033[0;32mCongratulations!\n\033[0;33mYou can now find the Tranquil binary at '\033[0m/usr/local/tranquil/bin/tranquil\033[0;33m'\033[0m"
echo "\n\033[0;33m(You'll probably want to add /usr/local/tranquil/bin to your \033[0mPATH\033[0;33m)\033[0m"

