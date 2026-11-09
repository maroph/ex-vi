#!/bin/bash
#
#
##############################################
# Copyright (c) 2023 by Manfred Rosenboom    #
#                                            #
# This work is licensed under a MIT License. #
# https://choosealicense.com/licenses/mit/   #
##############################################
#
declare -r SCRIPT_NAME=`basename $0`
declare -r VERSION="${SCRIPT_NAME}  1  (09-AUG-2023)"
#
###############################################################################
#
SCRIPT_DIR=`dirname $0`
cwd=`pwd`
if [ "${SCRIPT_DIR}" = "." ]
then
    SCRIPT_DIR=$cwd
else
    cd ${SCRIPT_DIR}
    SCRIPT_DIR=`pwd`
    cd $cwd
fi
cwd=
unset cwd
declare -r SCRIPT_DIR
#
###############################################################################
#
export LANG="en_US.UTF-8"
#
check=1
checkOnly=0
force=0
#
###############################################################################
#
print_usage() {
    cat - <<EOT

Usage: ${SCRIPT_NAME} [option(s)] [venv|deploy|serve]
       Call mkdocs to build the site related files

Options:
  -h|--help       : show this help and exit
  -V|--version    : show version information and exit
  -c|--check-only : check for needed Python3 modules and exit
  -f|--force      : use option --no-strict for mkdocs build
  -n|--no-check   : no check for needed Python3 modules

  Arguments
  venv          : create the required virtual environment and exit
  deploy        : create the site and push all data to branch gh-pages
                  (mkdocs gh-deploy)
  serve         : Run the MkDocs builtin development server
                  (mkdocs serve)

  Default: call 'mkdocs build'

EOT
}
#
###############################################################################
#
while :
do
    option=$1
    case "$1" in
        -h | --help)    
            print_usage
            exit 0
            ;;
        -V | --version)
            echo ${VERSION}
            exit 0
            ;;
        -c | --check-only)
            checkOnly=1
            ;;
        -f | --force)
            force=1
            ;;
        -n | --no-check)
            check=0
            ;;
        --)
            shift 1
            break
            ;;
        --*)
            echo "${SCRIPT_NAME}: '$1' : unknown option"
            exit 1
            ;;
        -*)
            echo "${SCRIPT_NAME}: '$1' : unknown option"
            exit 1
            ;;
        *)  break;;
    esac
#
    shift 1
done
#
###############################################################################
#
if [ "$1" != "" ]
then
    case "$1" in
        venv)   ;;
        deploy) ;;
        serve)  ;;
        *)
            echo "${SCRIPT_NAME}: '$1' : unknown argument"
            exit 1
            ;;
    esac
fi
#
###############################################################################
#
cd ${SCRIPT_DIR} || exit 1
#
###############################################################################
#
if [ "$1" = "venv" ]
then
    if [ "${VIRTUAL_ENV}" != "" ]
    then
        echo "${SCRIPT_NAME}: deactivate the current virtual environment"
        echo "${SCRIPT_NAME}: \$VIRTUAL_ENV : ${VIRTUAL_ENV}"
        exit 1
    fi
#
    rm -fr ${SCRIPT_DIR}/venv
    echo "${SCRIPT_NAME}: python3 -m venv v --prompt ven venv"
    python3 -m venv --prompt venv ${SCRIPT_DIR}/venv || exit 1
    echo "${SCRIPT_NAME}: . venv/bin/activate"
    . ${SCRIPT_DIR}/venv/bin/activate
#
    echo "${SCRIPT_NAME}: python -m pip install --upgrade pip"
    python -m pip install --upgrade pip || exit 1
    echo "${SCRIPT_NAME}: python -m pip install --upgrade setuptools"
    python -m pip install --upgrade setuptools || exit 1
    echo "${SCRIPT_NAME}: python -m pip install --upgrade wheel"
    python -m pip install --upgrade wheel || exit 1
    echo "${SCRIPT_NAME}: python -m pip install --upgrade mkdocs-material"
    python -m pip install --upgrade mkdocs-material || exit 1
    echo "${SCRIPT_NAME}: python -m pip install --upgrade mkdocs-git-revision-date-localized-plugin"
    python -m pip install --upgrade mkdocs-git-revision-date-localized-plugin || exit 1
#
    echo "${SCRIPT_NAME}: python -m pip freeze >requirements.txt"
    python -m pip freeze >${SCRIPT_DIR}/venv/requirements.txt || exit 1
#
    echo ""
    echo ""
    echo "----------"
    grep -E 'mkdocs' ${SCRIPT_DIR}/venv/requirements.txt
    echo "----------"
    echo ""
#
    exit 0
fi
#
###############################################################################
#
if [ "${VIRTUAL_ENV}" = "" ]
then
    echo "${SCRIPT_NAME}: no virtual environment active"
    if [ ! -d ${SCRIPT_DIR}/venv ]
    then
        echo "${SCRIPT_NAME}: directory ${SCRIPT_DIR}/venv missing"
        echo "${SCRIPT_NAME}: call first 'build venv'"
        exit 1
    fi
#
    if [ ! -r ${SCRIPT_DIR}/venv/bin/activate ]
    then
        echo "${SCRIPT_NAME}: script ${SCRIPT_DIR}/venv/bin/activate missing"
        exit 1
    fi
    . ${SCRIPT_DIR}/venv/bin/activate
fi
#
###############################################################################
#
if [ ${check} -eq 1 ]
then
#
    echo "${SCRIPT_NAME}: check for needed Python modules"
    echo "----------"
    data=$(python -m pip show mkdocs 2>/dev/null)
    if [ $? -ne 0 ]
    then
        echo "${SCRIPT_NAME}: Python module mkdocs not available"
        exit 1
    fi
    echo ${data} | awk '{ printf "%s %s\n%s %s\n", $1, $2, $3, $4;}'
    echo ""
#
    data=$(python -m pip show mkdocs-material 2>/dev/null)
    if [ $? -ne 0 ]
    then
        echo "${SCRIPT_NAME}: Python module mkdocs-material not available"
        exit 1
    fi
    echo ${data} | awk '{ printf "%s %s\n%s %s\n", $1, $2, $3, $4;}'
    echo ""
#
    data=$(python -m pip show mkdocs-git-revision-date-localized-plugin 2>/dev/null)
    if [ $? -ne 0 ]
    then
        echo "${SCRIPT_NAME}: Python module mkdocs-git-revision-date-localized-plugin not available"
        exit 1
    fi
    echo ${data} | awk '{ printf "%s %s\n%s %s\n", $1, $2, $3, $4;}'
    echo "----------"
    echo ""
#
    if [ ${checkOnly} -eq 1 ]
    then
        exit 0
    fi
#
fi
#
###############################################################################
#
if [ "$1" = "deploy" ]
then
    echo "${SCRIPT_NAME}: mkdocs gh-deploy"
    mkdocs gh-deploy || exit 1
    echo ""
    exit 0
fi
#
###############################################################################
#
if [ "$1" = "serve" ]
then
    if [ ${force} -eq 1 ]
    then
        echo "${SCRIPT_NAME}: mkdocs serve --no-strict ..."
        mkdocs serve --no-strict &
    else
        echo "${SCRIPT_NAME}: mkdocs serve ..."
        mkdocs serve &
    fi
    echo "#!/bin/bash" >./mkdocs.shut
    echo "kill -15 $!" >>./mkdocs.shut
    echo "rm ./mkdocs.shut" >>./mkdocs.shut
    chmod 700 ./mkdocs.shut
    sleep 1
    echo ""
    echo "shutdown MkDocs server: ./mkdocs.shut"
    echo ""
    exit 0
fi
#
###############################################################################
#
if [ ${force} -eq 1 ]
then
    echo "${SCRIPT_NAME}: mkdocs build --clean --no-strict"
    mkdocs build --clean --no-strict || exit 1
else
    echo "${SCRIPT_NAME}: mkdocs build --clean"
    mkdocs build --clean || exit 1
fi
echo ""
#
if [ -d ${SCRIPT_DIR}/.git ]
then
    echo "${SCRIPT_NAME}: git status"
    git status
fi
#
###############################################################################
#
exit 0

