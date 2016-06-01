
* Usage

Use
'''
. ./adm.sh install
'''
To install all *.config.sh in the directory and subdirectorys.

NOTE:
Always use

'''
. ./adm.sh "something"
'''
Or
'''
source ./adm.sh "something"
'''

rather than

'''
./adm.sh "something"
'''

Otherwise any configuration (aliases, environment variables, functions, etc) will not be exported in to the current shell. THis is because the "./adm ..." will execute the script in a subshell.
