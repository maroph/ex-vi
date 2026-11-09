#!/bin/bash
#
####################################################
# Copyright (c) 2026 by Manfred Rosenboom          #
# https://maroph.github.io/ (maroph@pm.me)         #
#                                                  #
# This work is licensed under a CC-BY 4.0 License. #
# https://creativecommons.org/licenses/by/4.0/     #
####################################################
declare -r COPYRIGHT="Copyright (C) 2026 Manfred Rosenboom"
declare -r LICENSE="License: CC-BY 4.0 <https://creativecommons.org/licenses/by/4.0/>"
#
declare -r SCRIPT_NAME=$(basename $0)
declare -r VERSION="0.1.0"
declare -r VERSION_DATE="05-NOV-2026"
declare -r VERSION_STRING="${SCRIPT_NAME}  ${VERSION}  (${VERSION_DATE})"
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
###############################################################################
#
# This script is based on
# https://github.com/maroph/zensical_sample/blob/main/build.bash
#
# CONFIG_EDIT_BEGIN
# -----------------
# show some environment data with option -V/--version
declare -r show_env_data=0
#
# 1: show use_ values with option -V/--version
declare -r show_use_variables=0
#
# show URL of buid.bash template file with option -V/--version
declare -r show_template_url=0
#
#
# needed by Zensical plugin [project.plugins.markdown-exec]
# hint: the module markdown-exec must be installed in your virtual environment
# python -m pip install --upgrade markdown-exec
declare -r use_module_markdown_exec=0

# needed by Zensical plugin [project.plugins.optimize]
# For JPG optimization you need the module Pillow
# python -m pip install --upgrade Pillow
# else set
# optimize_jpg = false
declare -r use_module_pillow=0
#
# use command deploy for direct GitHub Page deployment with the module ghp-import
# if set to 0, the command deploy can't be executed
# hint: the module ghp-import must be installed in your virtual environment
# python -m pip install --upgrade ghp-import
declare -r use_module_ghp_import=0
#
# use the Zensical plugin [project.plugins.macros] to save the
# the Zensical version in the variable/macro zensical_version
declare -r use_zensical_version=0
# ---------------
# CONFIG_EDIT_END
#
###############################################################################
###############################################################################
#
if [ -d ${SCRIPT_DIR}/.git ]
then
    gitrepo=1
else
    gitrepo=0
fi
declare -r gitrepo
#
GHP_IMPORT=""
if [ ${use_module_ghp_import} -eq 1 ]
then
    if [ -x $HOME/bin/ghp-import.bash ]
    then
        GHP_IMPORT="$HOME/bin/ghp-import.bash"
    fi
fi
#
###############################################################################
#
export LANG="en_US.UTF-8"
umask 0027
#
###############################################################################
#
check=0
checkOnly=0
cleanup=0
force=0
port=8000
git_trace=0
#
###############################################################################
#
print_usage() {
    cat - <<EOT

Usage: ${SCRIPT_NAME} [option(s)] [command]
       Call zensical to build the site related files
       Zensical: https://zensical.org/docs/get-started/

Option:
  -h|--help        : show this help and exit
  -V|--version     : show version information and exit
  -c|--check       : check for needed Python3 modules
  --check-only     : check for needed Python3 modules and exit
  --cleanup        : build|serve: remove all data from directories .cache and site
  -f|--force       : don't use option --strict for zensical build
  -p|--port <port> : serve: change port (default: ${port})
  --git-trace      : deploy: trace git commands

Command:
  venv          : create the required virtual environment and exit
  build         : create the site (default)
                  (zensical build)
  deploy        : create the site and push all data to GitHub repository branch gh-pages
                  (zensical build ; ghp-import - similar to: mkdocs gh-deploy)
  serve         : Run the Zensical builtin development server
                  (zensical serve)
                  Default URL: http://localhost:${port}
  shut          : shutdown Zensical development web server
  status        : show status of  Zensical development web server

  Default (no command): call 'zensical build'

EOT
}
#
print_ext_usage() {
    cat - <<EOT

Extended Help: ${SCRIPT_NAME}

Command:
  cleanup      : remove data from directories .cache and site
                 remove directory reproduction
  curver       : get the current Zensical version from the GitHub repository
  reproduction : create a Zensical issue reproduction base configuration
                 (https://zensical.org/docs/guides/reproduction/)

EOT
}
#
###############################################################################
#
getpid() {
    pid=$(ps -opid,cmd | grep '/zensical' | grep -v grep | awk '{ print $1; }')
    echo "${pid}"
}
#
print_environment() {
    type zensical >/dev/null 2>/dev/null
    if [ $? -eq 0 ]
    then
        echo "Zensical         : $(zensical --version)"
    else
        echo "Zensical         : zensical not found in PATH"
    fi
    echo "Python           : $(python3 --version)"
    echo "Operation System : $(uname -s) $(uname -r) $(uname -m) $(uname -o)"
    echo "                   $(uname -v)"
    if [ -r /etc/debian_version ]
    then
        echo "                   Debian $(head -1 /etc/debian_version)"
    fi
    if [ "${WSL_DISTRO_NAME}" != "" ]
    then
        echo "                   Running on Windows Subsystem for Linux (WSL)"
    fi
}
#
show_version() {
    echo "${VERSION_STRING}"
    echo "${COPYRIGHT}"
    echo "${LICENSE}"
    if [ ${show_env_data} -eq 1 ]
    then
        echo "---"
        echo "Environment:"
        print_environment
    fi
    if [ ${show_use_variables} -eq 1 ]
    then
        echo "---"
        echo "use_module_ghp_import    : ${use_module_ghp_import}"
        echo "use_module_markdown_exec : ${use_module_markdown_exec}"
        echo "use_module_pillow        : ${use_module_pillow}"
        echo "use_zensical_version     : ${use_zensical_version}"
    fi
    if [ ${show_template_url} -eq 1 ]
    then
        echo "---"
        echo "This script is based on"
        echo "https://github.com/maroph/zensical_sample/blob/main/build.bash"
    fi
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
        --ext-help)    
            print_ext_usage
            exit 0
            ;;
        -V | --version)
            show_version
            exit 0
            ;;
        -c | --check)
            check=1
            checkOnly=0
            ;;
        --check-only)
            check=1
            checkOnly=1
            ;;
        --cleanup)
            cleanup=1
            ;;
        -f | --force)
            force=1
            ;;
        -p | --port)
            shift
            if [ "$1" = "" ]
            then
                echo "${SCRIPT_NAME}: option ${option} : port number missing"
                exit 1
            fi
            if ! [[ "$1" =~ ^[1-9][0-9]*$ ]]
            then
                echo "${SCRIPT_NAME}: option ${option}: value is not a positive integer number"
                exit 1
            fi
            port=$1
            ;;
        --git-trace)
            git_trace=1
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
cmd="build"
if [ "$1" != "" ]
then
    cmd="$1"
fi
#
case "${cmd}" in
    venv) ;;
    build) ;;
    deploy) ;;
    serve) ;;
    shut)
        pid=$(getpid)
        if [ "${pid}" != "" ]
        then
            echo "${SCRIPT_NAME}: shutdown Zensical development web server"
            pkill -15 zensical || exit 1
        else
            echo "${SCRIPT_NAME}: Zensical server not running"
        fi
        exit 0
        ;;
    status)
        pid=$(getpid)
        if [ "${pid}" != "" ]
        then
            echo "${SCRIPT_NAME}: Zensical server running, pid: ${pid}"
        else
            echo "${SCRIPT_NAME}: Zensical server not running"
        fi
        exit 0
        ;;
    reproduction) ;;
    curver)
        curl -sL https://github.com/zensical/zensical/releases/latest | grep '<title>' | sed -e 's/<\/\?[^>]\+>//g' -e 's/^.*Release/Release/' -e 's/ · zensical.*$//'
        exit $?
        ;;
    cleanup)
        set -x
        cd ${SCRIPT_DIR}
        rm -fr ./.cache
        rm -fr ./site
        rm -fr ./reproduction
        mkdir ./.cache || exit 1
        mkdir ./site || exit 1
        exit 0
        ;;
    *)
        echo "${SCRIPT_NAME}: '${cmd}' : unknown command"
        exit 1
        ;;
esac
#
###############################################################################
#
cd ${SCRIPT_DIR} || exit 1
#
###############################################################################
#
if [ "${cmd}" = "venv" ]
then
    pid=$(getpid)
    if [ "${pid}" != "" ]
    then
        echo "${SCRIPT_NAME}: Zensical server running, pid: ${pid}"
        exit 1
    fi
    #
    if [ "${VIRTUAL_ENV}" != "" ]
    then
        echo "${SCRIPT_NAME}: deactivate the current virtual environment"
        echo "${SCRIPT_NAME}: \$VIRTUAL_ENV : ${VIRTUAL_ENV}"
        exit 1
    fi
#
    rm -fr venv
    echo "${SCRIPT_NAME}: python3 -m venv --prompt venv venv"
    python3 -m venv --prompt venv venv || exit 1
    echo "${SCRIPT_NAME}: chmod 700 venv"
    chmod 700 venv || exit 1
    echo "${SCRIPT_NAME}: source venv/bin/activate"
    source venv/bin/activate
#
    script_file="venv/venv_create.bash"
    echo "#!/bin/bash" >${script_file}
    dt=$(date +"%Y-%m-%dT%H:%M:%S.%3N%z")
    echo "# Creation Date : ${dt}" >>${script_file}
    echo "# Call Location : ${SCRIPT_DIR}" >>${script_file}
    echo "cd ${SCRIPT_DIR} || exit 1" >>${script_file}
    echo "#" >>${script_file}
    echo "python3 -m venv --prompt venv venv || exit 1" >>${script_file}
    echo "chmod 700 venv || exit 1" >>${script_file}
    echo "source venv/bin/activate" >>${script_file}
    echo "#" >>${script_file}
#
    echo "${SCRIPT_NAME}: python -m pip install --upgrade pip"
    python -m pip install --upgrade pip || exit 1
    echo "python -m pip install --upgrade pip || exit 1" >>${script_file}
    echo "${SCRIPT_NAME}: python -m pip install --upgrade setuptools"
    python -m pip install --upgrade setuptools || exit 1
    echo "python -m pip install --upgrade setuptools || exit 1" >>${script_file}
    echo "${SCRIPT_NAME}: python -m pip install --upgrade wheel"
    python -m pip install --upgrade wheel || exit 1
    echo "python -m pip install --upgrade wheel || exit 1" >>${script_file}
#
    echo "${SCRIPT_NAME}: python -m pip install --upgrade zensical"
    python -m pip install --upgrade zensical || exit 1
    echo "python -m pip install --upgrade zensical || exit 1" >>${script_file}
#
    if [ ${use_module_pillow} -eq 1 ]
    then
        echo "${SCRIPT_NAME}: python -m pip install --upgrade Pillow"
        python -m pip install --upgrade Pillow || exit 1
        echo "python -m pip install --upgrade Pillow || exit 1" >>${script_file}
    fi
#
    if [ ${use_module_markdown_exec} -eq 1 ]
    then
        echo "${SCRIPT_NAME}: python -m pip install --upgrade markdown-exec"
        python -m pip install --upgrade markdown-exec || exit 1
        echo "python -m pip install --upgrade markdown-exec || exit 1" >>${script_file}
    fi
#
    if [ ${use_module_ghp_import} -eq 1 ]
    then
        echo "${SCRIPT_NAME}: python -m pip install --upgrade ghp-import"
        python -m pip install --upgrade ghp-import || exit 1
        echo "python -m pip install --upgrade ghp-import || exit 1" >>${script_file}
    fi
#
# ----------------------------------------------------------------------
#
# add here more modules
#
#    echo "${SCRIPT_NAME}: python -m pip install --upgrade MODULE"
#    python -m pip install --upgrade MODULE || exit 1
#    echo "python -m pip install --upgrade MODULE || exit 1" >>${script_file}
#
# ----------------------------------------------------------------------
#
    echo "${SCRIPT_NAME}: python -m pip freeze >requirements.txt"
    python -m pip freeze >${SCRIPT_DIR}/venv/requirements.txt || exit 1
    echo "#" >>${script_file}
    echo "python -m pip freeze >venv/requirements.txt || exit 1" >>${script_file}
    chmod 600 venv/requirements.txt || exit 1
    echo "chmod 600 venv/requirements.txt || exit 1" >>${script_file}
    echo "#" >>${script_file}
#
    echo ""
    echo ""
    echo "----------"
    cat venv/requirements.txt | sort
    echo "cat venv/requirements.txt | sort" >>${script_file}
    echo "#" >>${script_file}
    echo "----------"
    echo ""
#
    echo "exit 0" >>${script_file}
    chmod 700 ${script_file} || exit 1
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
    data=$(python -m pip show zensical 2>/dev/null)
    if [ $? -ne 0 ]
    then
        echo "${SCRIPT_NAME}: Python module zensical not available"
        exit 1
    fi
    echo ${data} | awk '{ printf "%s %s\n%s %s\n", $1, $2, $3, $4;}'
    echo ""
#
    if [ ${use_module_ghp_import} -eq 1 ]
    then
        data=$(python -m pip show ghp-import 2>/dev/null)
        if [ $? -ne 0 ]
        then
            echo "${SCRIPT_NAME}: Python module ghp-import not available"
            exit 1
        fi
        echo ${data} | awk '{ printf "%s %s\n%s %s\n", $1, $2, $3, $4;}'
        echo "----------"
        echo ""
    fi
#
    if [ ${use_module_markdown_exec} -eq 1 ]
    then
        data=$(python -m pip show markdown-exec 2>/dev/null)
        if [ $? -ne 0 ]
        then
            echo "${SCRIPT_NAME}: Python module markdown-exec not available"
            exit 1
        fi
        echo ${data} | awk '{ printf "%s %s\n%s %s\n", $1, $2, $3, $4;}'
        echo "----------"
        echo ""
    fi
#
    if [ ${use_module_pillow} -eq 1 ]
    then
        data=$(python -m pip show Pillow 2>/dev/null)
        if [ $? -ne 0 ]
        then
            echo "${SCRIPT_NAME}: Python module Pillow not available"
            exit 1
        fi
        echo ${data} | awk '{ printf "%s %s\n%s %s\n", $1, $2, $3, $4;}'
        echo "----------"
        echo ""
    fi
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
# https://zensical.org/docs/guides/reproduction/
if [ "${cmd}" = "reproduction" ]
then
    rm -fr reproduction
    zensical new reproduction || exit 1
    mkdir reproduction/issue_info || exit 1
    pip freeze > reproduction/issue_info/requirements.txt || exit 1
    find reproduction -type d -exec chmod 755 {} \; || exit 1
    find reproduction -type f -exec chmod 644 {} \; || exit 1
    cd reproduction/issue_info || exit 1
#
    info_file="README.md"
    echo "# Reproduction Info" >${info_file}
    chmod 644 ${info_file} || exit 1
    echo "## Environment" >>${info_file}
    echo '```' >>${info_file}
    print_environment >>${info_file}
    echo '```' >>${info_file}
#
    echo "" >>${info_file}
    echo "## Virtual Environment" >>${info_file}
    echo "* [requirements.txt](./requirements.txt)" >>${info_file}
    if [ -r ${SCRIPT_DIR}/venv/venv_create.bash ]
    then
        cp ${SCRIPT_DIR}/venv/venv_create.bash . || exit 1
        chmod 755 venv_create.bash || exit 1
        echo "* [venv_create.bash](venv_create.bash)" >>${info_file}
        echo "" >>${info_file}
    fi
#
    echo "${SCRIPT_NAME}: Zensical issue reproduction base configuration created"
    echo "${SCRIPT_NAME}: Add further information to file reproduction/issue_info/${info_file}"
    echo "${SCRIPT_NAME}: Pack reproduction configuration as ZIP file:"
    echo "${SCRIPT_NAME}: zip -r reproduction.zip reproduction"
    exit 0
fi
#
###############################################################################
#
if [ "${cmd}" = "deploy" ]
then
    if [ ${use_module_ghp_import} -eq 0 ]
    then
        echo "${SCRIPT_NAME}: ghp-import not supported"
        exit 1
    fi
#
    if [ ${gitrepo} -eq 0 ]
    then
        echo "${SCRIPT_NAME}: current directory is not a Git repository"
        exit 1
    fi
#
    if [ "${GHP_IMPORT}" = "" ]
    then
        python3 -m pip show ghp-import >/dev/null 2>/dev/null
        if [ $? -ne 0 ]
        then
            echo "${SCRIPT_NAME}: Python module ghp-import not available"
            exit 1
        fi

#
        GHP_IMPORT="ghp-import"
    fi
#
    pid=$(getpid)
    if [ "${pid}" != "" ]
    then
        echo "${SCRIPT_NAME}: Zensical server running, pid: ${pid}"
        exit 1
    fi
#
    rm -fr ./.cache
    rm -fr ./site
    mkdir ./.cache || exit 1
    mkdir ./site || exit 1
#
    echo "${SCRIPT_NAME}: zensical build --clean --strict"
    zensical build --clean --strict || exit 1
    echo ""
#
    if [ ${git_trace} -eq 1 ]
    then
        export GIT_TRACE=1
        export GIT_CURL_VERBOSE=1
    fi
#
    echo "${SCRIPT_NAME}: ghp-import --no-jekyll --push --no-history ./site"
    ${GHP_IMPORT} --no-jekyll --push --no-history ./site || exit 1
    echo ""
    exit 0
fi
#
###############################################################################
#
if [ "${cmd}" = "serve" ]
then
    pid=$(getpid)
    if [ "${pid}" != "" ]
    then
        echo "${SCRIPT_NAME}: Zensical server already running, pid: ${pid}"
        exit 1
    fi
    #
    # File Watcher
    # see: https://github.com/zensical/zensical/releases/tag/v0.0.28
    #
    # You can now opt into using a polling-based file watcher, 
    # which is particularly useful when running Docker on 
    # Windows, where filesystem event limitations (e.g., inotify 
    # constraints) can cause issues.
    ##### export ZENSICAL_POLL_WATCHER=1
    # The polling interval is configurable and defaults to 
    # 500 milliseconds (aligned with MkDocs behavior)
    ##### export ZENSICAL_POLL_INTERVAL=500
    #
    if [ ${cleanup} -eq 1 ]
    then
        rm -fr ./.cache
        rm -fr ./site
        mkdir ./.cache || exit 1
        mkdir ./site || exit 1
    fi
    echo "${SCRIPT_NAME}: zensical serve --dev-addr "localhost:${port}" ..."
    zensical serve --dev-addr "localhost:${port}" &
    exit 0
fi
#
###############################################################################
###############################################################################
#
if [ "${cmd}" != "build" ]
then
    echo "${SCRIPT_NAME}: ERROR: ${cmd} : unknown command"
    exit 1
fi
#
###############################################################################
#
if [ ${use_zensical_version} -eq 1 ]
then
    if [ ! -r data/variables.yml ]
    then
        echo "${SCRIPT_NAME}: ERROR: missing file data/variables.yml"
        echo "${SCRIPT_NAME}: ERROR: variable zensical_version is expected in this file"
    else
        grep zensical_version data/variables.yml >/dev/null 2>/dev/null
        if [ $? -ne 0 ]
        then
            echo "${SCRIPT_NAME}: ERROR: variable zensical_version missing in file data/variables.yml"
        else
            grep zensical_version data/variables.yml | grep $(zensical --version) >/dev/null 2>/dev/null
            if [ $? -ne 0 ]
            then
                echo "${SCRIPT_NAME}: WARN: update Zensical version in variable zensical_version in file data/variables.yml"
                echo "${SCRIPT_NAME}: WARN: current Zensical version: $(zensical --version)"
            fi
        fi
    fi
fi
#
###############################################################################
#
pid=$(getpid)
if [ "${pid}" != "" ]
then
    echo "${SCRIPT_NAME}: Zensical server running, pid: ${pid}"
    exit 1
fi
#
#
if [ ${cleanup} -eq 1 ]
then
    rm -fr ./.cache
    rm -fr ./site
    mkdir ./.cache || exit 1
    mkdir ./site || exit 1
fi
if [ ${force} -eq 1 ]
then
    echo "${SCRIPT_NAME}: zensical build --clean"
    zensical build --clean || exit 1
else
    echo "${SCRIPT_NAME}: zensical build --clean --strict"
    zensical build --clean --strict || exit 1
fi
echo ""
#
#
if [ ${gitrepo} -eq 1 ]
then
    echo "${SCRIPT_NAME}: git status"
    git status
fi
#
###############################################################################
#
exit 0

