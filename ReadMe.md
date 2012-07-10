# Tranquil

Tranquil is a programming language built on top of LLVM & the Objective-C Runtime. 

## How to build

The following will create a binary called `tranquil` in the `Build` folder.

	> brew install llvm --HEAD --jit --enable-optimized
	> git clone git://github.com/fjolnir/Tranquil.git
	> cd Tranquil
	> rake
	> build/tranquil -h

## Learning the language

To learn Tranquil you should read the [specification](https://github.com/fjolnir/Tranquil/blob/master/Docs/Tranquil%20Spec.md).