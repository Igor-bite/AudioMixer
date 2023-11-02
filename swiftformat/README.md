# What is it?
It's a ***SwiftFormat*** for pre-commit git hook.
It's purpose is to format staged code along commit. 

# Preparations:
1. Open terminal on ***project root*** directory.
2. Execute the commands: 
```
./buildscript/utils/setup.sh
```
4. ***.swiftformat*** config file is already in the project root directory.
5. ***git-format-staged*** is used to process only staged files.
6. You can add another .swiftformat to subdirectories to override root config rules and options.
7. Now all your staged swift files will be checked with rules defined in .swiftformat file on commit. And in case formatting is not in accordance with rules you'll see a warning.
