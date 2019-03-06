#!/usr/bin/env bash
#
# SIMON installation script
#
clear

title="Welcome to SIMON installation"

## Basic requirements by module
deps_missing=n

declare -A DEPS
DEPS[simon_api]="php composer git"
DEPS[simon_cron]="node yarn java git flock gfortran openssl"
DEPS[simon_plots]="node yarn nginx git"
DEPS[simon_analysis]="node yarn nginx git"
DEPS[simon_database]="mysql"
DEPS[simon_frontend]="node yarn nginx git"

declare -A MODS
MODS[simon_api]=y
MODS[simon_cron]=y
MODS[simon_plots]=y
MODS[simon_analysis]=y
MODS[simon_database]=y
MODS[simon_frontend]=y

## Defaults
declare -A B_CONF
B_CONF[salt]=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\$\%\^\&\*\(\)-+= < /dev/urandom | head -c 8)
B_CONF[secret]=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\$\%\^\&\*\(\)-+= < /dev/urandom | head -c 16)

B_CONF[details_title]="genular"
B_CONF[details_email]="support@genular.com"

B_CONF[data_path]="/tmp"

B_CONF[database_host]="localhost"
B_CONF[database_port]=3306
B_CONF[database_user]="genular"
B_CONF[database_password]="genular"
B_CONF[database_dbname]="genular"

# B_CONF[analysis_url]="http://analysis.api.genular.localhost"
# B_CONF[plots_url]="http://plots.api.genular.localhost"
# B_CONF[backend_url]="http://backend.api.genular.localhost"
# B_CONF[frontend_url]="http://dashboard.genular.localhost"

B_CONF[analysis_url]="http://localhost"
B_CONF[plots_url]="http://localhost"
B_CONF[backend_url]="http://localhost"
B_CONF[frontend_url]="http://localhost"

yellow=$(tput setaf 3)
green=$(tput setaf 2)
clear=$(tput sgr0)
red=$(tput setaf 1)
COLUMNS=$(tput cols)

GIT_FRONTEND="https://github.com/genular/simon-frontend.git"
GIT_BACKEND="https://github.com/genular/simon-backend.git"

## Defaults
GIT_FRONTEND_LOCAL="/var/www/genular/simon-frontend"
GIT_BACKEND_LOCAL="/var/www/genular/simon-backend"

echo "${green}"
printf "%*s\n" $(((${#title}+$COLUMNS)/2)) "$title"
echo "This script will try to guide you via installation of simon and all its dependencies."
echo "Please make sure that all dependencies are successfully installed."
echo "${clear}"
echo ""

# -----------------------------------------------------------------------------
# Check OS Type, currently only Linux is supported
# -----------------------------------------------------------------------------
if [[ "$OSTYPE" != "linux-gnu" ]]; then
    echo "${red}[$OSTYPE] not supported. Only linux-gnu is supported by this installation helper.${clear}"
    exit 1
fi

# -----------------------------------------------------------------------------
# => Check what modules we want to have on this machine
# -----------------------------------------------------------------------------
for MODULE in "${!MODS[@]}"; do 
    echo "${yellow}Do you want to host ${MODULE} on this machine? (y/n) Enter y${clear}"
    read -e MODS["$MODULE"]

    if [ "${MODS[$MODULE]}" != y ] || [ "${MODS[$MODULE]}" != n ] ; then
        MODS["$MODULE"]=y
    fi
done

# -----------------------------------------------------------------------------
# => Check main dependencies
# -----------------------------------------------------------------------------
echo "${green}"
echo "Checking dependencies:"
for DEP in "${!DEPS[@]}"; do
    if [ "${MODS[$DEP]}" == y ] ; then

        for DEP_MOD in ${DEPS[$DEP]}; do
            if ! type "$DEP_MOD" > /dev/null; then
              echo "${red}[$DEP] not found: $DEP_MOD${clear}"
              deps_missing=y
            else
                echo "${green}[$DEP] found: $DEP_MOD${clear}"
            fi
        done
    fi
done

## Check specific dependencies
if [ "${MODS[simon_cron]}" == y ] ; then
    check_blas=$(ldconfig -p | grep openblas)
    if [ -z "$check_blas" ] ; then
        install_dep=n
        echo "${red}OpenBLAS is missing. OpenBLAS, ATLAS or MKL package or needed. Should we install OpenBLAS now? (y/n) Enter y${clear}";
        read -e install_dep
        if [ "${install_dep}" == "" ] ; then
            install_dep=y
        fi
        if [ "$install_dep" == y ] ; then
            sudo apt-get install libopenblas-dev
        else
            echo "${red}Please install this dependency manually${clear}";
            exit 1
        fi
    fi

    check_opencv=$(ldconfig -p | grep opencv)
    if [ -z "$check_opencv" ] ; then
        install_dep=n
        echo "${red}OpenCV is missing. Should we install it now? (y/n) Enter y${clear}";
        read -e install_dep
        if [ "${install_dep}" == "" ] ; then
            install_dep=y
        fi
        if [ "$install_dep" == y ] ; then
            sudo apt-get install libopencv-dev
        else
            echo "${red}Please install this dependency manually${clear}";
            exit 1
        fi
    fi

    check_libssl=$(ldconfig -p | grep libssl)
    if [ -z "$check_libssl" ] ; then
        install_dep=n
        echo "${red}libssl is missing. Should we install it now? (y/n) Enter y${clear}";
        read -e install_dep
        if [ "${install_dep}" == "" ] ; then
            install_dep=y
        fi
        if [ "$install_dep" == y ] ; then
            sudo apt-get install libssl-dev
        else
            echo "${red}Please install this dependency manually${clear}";
            exit 1
        fi
    fi

    check_libssh=$(ldconfig -p | grep libssh)
    if [ -z "$check_libssh" ] ; then
        install_dep=n
        echo "${red}libssh is missing. Should we install it now? (y/n) Enter y${clear}";
        read -e install_dep
        if [ "${install_dep}" == "" ] ; then
            install_dep=y
        fi
        if [ "$install_dep" == y ] ; then
            sudo apt-get install libssh2-1-dev
        else
            echo "${red}Please install this dependency manually${clear}";
            exit 1
        fi
    fi

    check_libmariadbclient=$(ldconfig -p | grep libmariadbclient)
    if [ -z "$check_libmariadbclient" ] ; then
        install_dep=n
        echo "${red}libmariadbclient is missing. Should we install it now? (y/n) Enter y${clear}";
        read -e install_dep
        if [ "${install_dep}" == "" ] ; then
            install_dep=y
        fi
        if [ "$install_dep" == y ] ; then
            sudo apt-get install libmariadbclient-dev
        else
            echo "${red}Please install this dependency manually${clear}";
            exit 1
        fi
    fi

    check_libxml2=$(ldconfig -p | grep libxml2)
    if [ -z "$check_libxml2" ] ; then
        install_dep=n
        echo "${red}libxml2 is missing. Should we install it now? (y/n) Enter y${clear}";
        read -e install_dep
        if [ "${install_dep}" == "" ] ; then
            install_dep=y
        fi
        if [ "$install_dep" == y ] ; then
            sudo apt-get install libxml2-dev
        else
            echo "${red}Please install this dependency manually${clear}";
            exit 1
        fi
    fi
fi

echo "${clear}"

if [ "$deps_missing" == y ] ; then
    echo "Please install missing dependencies first, and re-run this script. Exiting..";
    exit 1
fi

# -----------------------------------------------------------------------------
# => Install R by version and its dependencies from source
# -----------------------------------------------------------------------------
if [ "${MODS[simon_cron]}" == y ] || [ "${MODS[simon_plots]}" == y ] || [ "${MODS[simon_analysis]}" == y ] ; then

    r_installed=y
    install_r=n

    if ! type "R" > /dev/null; then
      r_installed=n
    fi

    if [ "${r_installed}" == n ] ; then
        echo "${yellow}Do you want to install R or its dependencies? (y/n) Enter y${clear}"
        read -e install_r
        if [ "${install_r}" == "" ] ; then
            install_r=y
        fi
    else
        echo "${yellow}R installation found on system. Do you want to install another R verion? (y/n) Enter n${clear}"
        read -e install_r
        if [ "${install_r}" == "" ] ; then
            install_r=n
        fi
    fi

    echo ""

    if [ "$install_r" == y ] ; then

        echo "${yellow}Enabling Source code repositories in /etc/apt/sources.list${clear}"
        sudo sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list

        sudo apt-get update

        echo "${yellow}Should we build essential package dependencies? (y/n) Enter y${clear}"
        read -e build_deps
        if [ "${build_deps}" == "" ] ; then
            build_deps=y
        fi
        if [ "$build_deps" == y ] ; then
            ## Get some libraries and other utilities
            sudo apt-get install build-essential
            ## (configure: error: missing required header GL/gl.h) in some R cron libs
            sudo apt-get install libglu1-mesa-dev freeglut3-dev mesa-common-dev
        fi

        echo "${yellow}Should we try to build R specific dependencies? (y/n) Enter y${clear}"
        read -e build_deps
        if [ "${build_deps}" == "" ] ; then
            build_deps=y
        fi
        if [ "$build_deps" == y ] ; then
            ## Build R dependencies
            sudo apt-get build-dep r-base
        fi


        # accept the name of our website
        echo "${yellow}R Version (eg. 3.5.1/n) Enter 3.5.1${clear}"
        read -e R_VERSION

        if [ "${R_VERSION}" == "" ] ; then
            R_VERSION="3.5.1"
        fi

        echo ""

        if [ "$R_VERSION" != n ] ; then
            R_URL="https://cloud.r-project.org/src/base/R-3/R-${R_VERSION}.tar.gz"
            if curl --head --fail --silent "$R_URL" >/dev/null; then
                # Create temporary directory
                mkdir -p "$HOME/R_tmp"
                cd "$HOME/R_tmp" || exit 1

                wget $R_URL
                tar xvzf R-${R_VERSION}.tar.gz
                rm R-${R_VERSION}.tar.gz

                # Configure and make
                cd R-${R_VERSION} || exit 1
                ./configure --prefix=/usr/local/R/${R_VERSION} --enable-R-shlib --with-blas --with-lapack
                make
                sudo make install

                # Cleanup
                cd ../.. || exit 1
                rm -rf "$HOME/R_tmp"

                # Create symbolic links to the installed version
                sudo ln -s /usr/local/R/${R_VERSION}/bin/R /usr/bin/R-${R_VERSION}
                sudo ln -s /usr/local/R/${R_VERSION}/bin/Rscript /usr/bin/Rscript-${R_VERSION}

                # Adjust permissions
                sudo chmod o+w /usr/local/R/${R_VERSION}/lib64/R/library && sudo chmod o+w /usr/local/R/${R_VERSION}/lib64/R/doc -R

                # Set as default system version
                install_r_default=y
                echo "${yellow}Do you want set this R version as default system one? (y/n) Enter y${clear}"
                read -e install_r_default

                if [ "${install_r_default}" == "" ] ; then
                    install_r_default=y
                fi

                echo ""
                if [ "$install_r_default" == y ] ; then
                    sudo ln -s /usr/bin/R-${R_VERSION} /usr/bin/R
                    sudo ln -s /usr/bin/Rscript-${R_VERSION} /usr/bin/Rscript
                fi

                ## Configure R with system java
                ## Should we also set java home?: 
                ## https://gist.githubusercontent.com/djangofan/5526565/raw/b6425dba457bdbad63604b571efe85b1b3716dd4/java-setup.sh
                echo "${yellow}Configuring java to work with R${clear}"
                sudo R CMD javareconf

                echo "${green}"
                echo "================================================================="
                echo ""
                echo "R Installation is complete"
                echo ""
                echo "Version: $R_VERSION"
                echo "Prefix: /usr/local/R/$R_VERSION"
                echo ""
                echo "Please make sure that environmental variables: JAVA_HOME & LD_LIBRARY_PATH are set properly."
                echo "================================================================="
                echo "${clear}"
            else 
                echo "${red}"
                echo "================================================================="
                echo ""
                echo "R Installation failed. Remote R source file does not exist!"
                echo ""
                echo "File url: $R_URL"
                echo ""
                echo "================================================================="
                echo "${clear}"
            fi
        fi
    fi

    # -----------------------------------------------------------------------------
    # => Install global node packages
    # -----------------------------------------------------------------------------
    echo "${yellow}Do you want to install global pm2 process manager package? (y/n) Enter y${clear}"
    read -e install_pm2
    if [ "${install_pm2}" == "" ] ; then
        install_pm2=y
    fi
    echo ""

    if [ "$install_pm2" == y ] ; then
        yarn global add pm2@latest
        echo "${yellow}pm2 installation is complete.${clear}"
    fi


    # -----------------------------------------------------------------------------
    # => Install R packages
    # -----------------------------------------------------------------------------
    echo "${yellow}Do you want to install main SIMON R dependencies? (y/n) Enter y${clear}"
    read -e install_rdep
    if [ "${install_rdep}" == "" ] ; then
        install_rdep=y
    fi
    echo ""

    if [ "$install_rdep" == y ] ; then
        echo "${green}=> Installing shared dependencies${clear}"

        sudo Rscript -e "install.packages(c('devtools'), repo = 'https://cloud.r-project.org/')"
        ## server/backend/public/assets/datasets/Rdatasets.R
        sudo Rscript -e "devtools::install_github('trinker/pacman')"
        sudo Rscript -e "install.packages(c('BiocManager', 'plumber', 'config', 'DBI', 'RMySQL', 'pool', 'urltools', 'RMariaDB', 'PKI', 'data.table', 'RCurl', 'aws.s3'), repos='http://cran.us.r-project.org')"
        
        ## Check some shared deps
        if [ "${MODS[simon_plots]}" == y ] || [ "${MODS[simon_cron]}" == y ] ; then
            sudo Rscript -e "install.packages(c('R.utils'), repos='http://cran.us.r-project.org')"
        fi

        if [ "${MODS[simon_analysis]}" == y ] ; then
            echo "${green}=> Installing analysis server deps${clear}"
            sudo Rscript -e "BiocManager::install('impute', version = '3.8', update = FALSE, ask = FALSE)"
            sudo Rscript -e "install.packages(c('samr'), repos='http://cran.us.r-project.org')"
            # sudo Rscript -e "devtools::install_github('catboost/catboost', subdir = 'catboost/R-package', args=c('--no-multiarch', '--no-test-load'))"
            sudo Rscript -e "devtools::install_url('https://github.com/catboost/catboost/releases/download/v0.12.1.1/catboost-R-Linux-0.12.1.1.tgz', INSTALL_opts = c('--no-multiarch', '--no-test-load'))"

        fi

        if [ "${MODS[simon_plots]}" == y ] ; then
            echo "${green}=> Installing plots server deps${clear}"
            ## We need caret package to calculate resamples and display some of the plots in plots API
            sudo Rscript -e "install.packages('caret', dependencies=TRUE, repos='http://cran.us.r-project.org')"
            sudo Rscript -e "devtools::install_github('taiyun/corrplot', build_vignettes = TRUE)"
            sudo Rscript -e "devtools::install_github('raivokolde/pheatmap')"
            sudo Rscript -e "install.packages(c('ggplot2', 'lattice', 'RColorBrewer'), repos='http://cran.us.r-project.org')"
        fi

        if [ "${MODS[simon_cron]}" == y ] ; then
            echo "${green}=> Installing cron server deps${clear}"
            ## Shared cron deps
            sudo Rscript -e "install.packages(c('doMC'), repos='http://cran.us.r-project.org')"
            sudo Rscript -e "install.packages('caret', dependencies=TRUE, repos='http://cran.us.r-project.org')"

            ## Classification
            sudo Rscript -e "install.packages(c('ada', 'adabag', 'fastAdaboost', 'bnclassify', 'kohonen', 'bartMachine', 'arm', 'binda', 'bst', 'C50', 'rrcov', 'deepboost', 'deepnet', 'kerndwd', 'evtree', 'extraTrees', 'frbs', 'mboost', 'xgboost', 'wsrf', 'VGAM', 'LiblineaR', 'sparseLDA', 'snn', 'sdwd', 'sda', 'rrcovHD', 'h2o', 'glmnet', 'hda', 'HDclassif', 'RWeka', 'kknn', 'HiDimDA', 'RSNNS', 'keras', 'monmlp', 'msaenet', 'rrlda', 'RRF', 'rpartScore', 'rotationForest', 'rocc', 'robustDA', 'rFerns', 'Rborist', 'randomGLM', 'protoclass', 'supervisedPRIM', 'plsRglm', 'stepPlr', 'penalizedLDA', 'partDSA', 'obliqueRF', 'ordinalNet', 'nodeHarvest', 'naivebayes'), repos='http://cran.us.r-project.org')"

            sudo Rscript -e "install.packages('CHAID', repos='http://R-Forge.R-project.org')"
            sudo Rscript -e "BiocManager::install('vbmp', version = '3.8', update = FALSE, ask = FALSE)"
            sudo Rscript -e "BiocManager::install('gpls', version = '3.8', update = FALSE, ask = FALSE)"
            sudo Rscript -e "BiocManager::install('logicFS', version = '3.8', update = FALSE, ask = FALSE)"
            sudo Rscript -e "devtools::install_github(c('cran/adaptDA', 'ramhiser/sparsediscrim', 'cran/elmNN', 'cran/FCNN4R'))"
        fi 
    fi
fi


# -----------------------------------------------------------------------------
# => Clone SIMON front-end from git
# -----------------------------------------------------------------------------
echo "${yellow}Now when all dependencies are set lets configure system${clear}"
echo ""

if [ "${MODS[simon_frontend]}" == y ] ; then

    echo "${yellow}Do you want to clone simon-frontend repository? (y/n) Enter y${clear}"
    read -e clone_frontend
    if [ "${clone_frontend}" == "" ] ; then
        clone_frontend=y
    fi
    echo ""

    if [ "$clone_frontend" == y ] ; then
        echo "${yellow}Path to frontend root directory? (path/n) Enter default${clear}"
        echo "${yellow}eg. /var/www/genular/simon-frontend${clear}"
        read -e GIT_FRONTEND_LOCAL

        if [ "${GIT_FRONTEND_LOCAL}" == "" ] ; then
            ## TODO: TESTING
            sudo mkdir -p "/var/www/genular"
            sudo chown $USER "/var/www/genular"

            GIT_FRONTEND_LOCAL="/var/www/genular/simon-frontend"
        fi
        
        echo ""

        if [ "$GIT_FRONTEND_LOCAL" != n ] ; then
            ## make sure that directory doesn't exist
            if [ ! -d "$GIT_FRONTEND_LOCAL" ]; then
                git clone --recursive $GIT_FRONTEND "$GIT_FRONTEND_LOCAL"
                cd "$GIT_FRONTEND_LOCAL" || exit 1
                echo ""
                echo "${red}Installing front-end dependencies${clear}"
                yarn install

                echo "${red}Setting basic configuration files in './config' directory${clear}"

                ## Configure front-end configuration files
                cd "$GIT_FRONTEND_LOCAL/config" || exit 1
                cp env_development.example.json env_development.json
                cp env_production.example.json env_production.json

                sed -i 's|"frontend": "PLACEHOLDER"|"frontend": "'"${B_CONF[frontend_url]}"'"|g' "env_development.json"
                sed -i 's|"backend": "PLACEHOLDER"|"backend": "'"${B_CONF[backend_url]}"'"|g' "env_development.json"
                sed -i 's|"homepage": "PLACEHOLDER"|"homepage": "'"${B_CONF[frontend_url]}"'"|g' "env_development.json"

                sed -i 's|"frontend": "PLACEHOLDER"|"frontend": "'"${B_CONF[frontend_url]}"'"|g' "env_production.json"
                sed -i 's|"backend": "PLACEHOLDER"|"backend": "'"${B_CONF[backend_url]}"'"|g' "env_production.json"
                sed -i 's|"homepage": "PLACEHOLDER"|"homepage": "'"${B_CONF[frontend_url]}"'"|g' "env_production.json"

                ## Compile statically for web
                cd "$GIT_FRONTEND_LOCAL" || exit 1
                echo "${yellow}Building static front-end files, please wait. (yarn run webpack:web:dev)${clear}"
                yarn run webpack:web:dev

                sudo chown -hR $USER:www-data "/var/www/genular"

            else
                echo "${red}Directory already exist, stopping, please clone it manually: $GIT_FRONTEND_LOCAL ${clear}"
            fi
        fi
    fi
fi
# -----------------------------------------------------------------------------
# => Clone SIMON backend-end from git
# -----------------------------------------------------------------------------
if [ "${MODS[simon_api]}" == y ] || [ "${MODS[simon_cron]}" == y ] || [ "${MODS[simon_plots]}" == y ] || [ "${MODS[simon_analysis]}" == y ] ; then

    echo "${yellow}Do you want to clone simon-backend repository? (y/n) Enter y${clear}"
    read -e clone_backend
    if [ "${clone_backend}" == "" ] ; then
        clone_backend=y
    fi
    echo ""

    if [ "$clone_backend" == y ] ; then
        echo "${yellow}Please enter path to backend root directory? (path/n) Enter default${clear}"
        echo "${yellow}eg. /var/www/genular/simon-backend${clear}"
        read -e GIT_BACKEND_LOCAL

        if [ "${GIT_BACKEND_LOCAL}" == "" ] ; then
            ## TODO: TESTING
            sudo mkdir -p "/var/www/genular"
            sudo chown $USER "/var/www/genular"
            
            GIT_BACKEND_LOCAL="/var/www/genular/simon-backend"
        fi

        echo ""

        if [ "$GIT_BACKEND_LOCAL" != n ] ; then
            ## make sure that directory doesn't exist
            if [ ! -d "$GIT_BACKEND_LOCAL" ]; then
                echo "${yellow}Installing necessarily PHP modules (php-zip, ext-simplexml, ext-curl, ext-mbstring, ext-gmp, ext-libsodium, php-imagick)${clear}"
                sudo apt-get install unzip php-zip php-simplexml php-curl php-mbstring php-gmp php-libsodium php-imagick

                git clone --recursive $GIT_BACKEND "$GIT_BACKEND_LOCAL"
                cd "$GIT_BACKEND_LOCAL" || exit 1

                cp config.example.yml config.yml
                cp ecosystem.config.example.js ecosystem.config.js

                sed -i 's|const backendPath = PLACEHOLDER|const backendPath = '"\"$GIT_BACKEND_LOCAL\""'|g' "ecosystem.config.js"

                sed -i 's|title: PLACEHOLDER|title: '"\"${B_CONF[details_title]}\""'|g' "config.yml"
                sed -i 's|email: PLACEHOLDER|email: '"\"${B_CONF[details_email]}\""'|g' "config.yml"
                sed -i 's|salt: PLACEHOLDER|salt: '"\"${B_CONF[salt]}\""'|g' "config.yml"
                
                sed -i 's|secret: SECRET_PLACEHOLDER|secret: '"\"${B_CONF[secret]}\""'|g' "config.yml"
                sed -i 's|data_path: PLACEHOLDER|data_path: '"\"${B_CONF[data_path]}\""'|g' "config.yml"

                sed -i 's|host: PLACEHOLDER|host: '"\"${B_CONF[database_host]}\""'|g' "config.yml"
                sed -i 's|port: PLACEHOLDER|port: '"${B_CONF[database_port]}"'|g' "config.yml"
                sed -i 's|user: PLACEHOLDER|user: '"\"${B_CONF[database_user]}\""'|g' "config.yml"
                sed -i 's|password: PLACEHOLDER|password: '"\"${B_CONF[database_password]}\""'|g' "config.yml"
                sed -i 's|dbname: PLACEHOLDER|dbname: '"\"${B_CONF[database_dbname]}\""'|g' "config.yml"

                sed -i 's|url: PLACEHOLDER_ANALYSIS_URL|url: '"\"${B_CONF[analysis_url]}\""'|g' "config.yml"
                sed -i 's|url: PLACEHOLDER_PLOTS_URL|url: '"\"${B_CONF[plots_url]}\""'|g' "config.yml"
                sed -i 's|url: PLACEHOLDER_BACKEND_URL|url: '"\"${B_CONF[backend_url]}\""'|g' "config.yml"
                sed -i 's|url: PLACEHOLDER_FRONTEND_URL|url: '"\"${B_CONF[frontend_url]}\""'|g' "config.yml"

                cd server/backend/ || exit 1
                echo "${red}Installing dependencies..${clear}"
                echo ""
                composer install

                ## Create logs directory
                mkdir "$GIT_BACKEND_LOCAL/server/backend/source/logs"
                touch "$GIT_BACKEND_LOCAL/server/backend/source/logs/simon.log"
                chmod -R 777 "$GIT_BACKEND_LOCAL/server/backend/source/logs"

                touch "/var/log/simon-cron.log"
                chmod -R 777 "$GIT_BACKEND_LOCAL/cron/main.R"

                sudo chown -hR $USER:www-data "/var/www/genular"

                echo ""
                echo "${red}Backend installation is successful.${clear}"
                echo "${red}Please adjust configuration variables in './config.yml' file.${clear}"
                echo "${red}Also you need to create necessary vhosts in your nginx/apache. There is a template in './documentation/installation/nginx/vhosts.example.conf'${clear}"
                echo ""

            else
                echo "${red}Directory already exist, stopping, please clone it manually: $GIT_BACKEND_LOCAL ${clear}"
            fi
        fi
    fi
    echo "${red}"
    echo "# Since you will run analysis here on shared server you need to create cron task that will check for any new queues to process"
    echo "# We suggest creating crontab task like this"
    echo "chmod 777 /var/www/genular/simon-backend/cron/main.R"
    echo "*/2 * * * * /usr/bin/flock -n ${B_CONF[data_path]}/simon_cron.pid /var/www/genular/simon-backend/cron/main.R > /var/log/simon-cron.log 2>&1"
    echo "${clear}"
fi

### Database installation
echo "${green}"
echo "================================================================="
echo ""
echo "Should we try to import database schema using credentials you provided? (y/n) Enter y"
echo ""
echo "Host: ${B_CONF[database_host]}:${B_CONF[database_port]}"
echo "Username: ${B_CONF[database_user]}"
echo "Password: *********"
echo "DB name: ${B_CONF[database_dbname]}"
echo ""
echo "Please make sure that blank database and database user are created on the server and that mysql is started before continuing..."
echo ""
echo "================================================================="
echo "${clear}"

read -e install_database
if [ "${install_database}" == "" ] ; then
    install_database=y
fi
echo ""

if [ "$install_database" == y ] ; then
    if [ -d "$GIT_BACKEND_LOCAL" ]; then
        echo "${yellow}Starting database import${clear}"
        mysql -u ${B_CONF[database_user]} -p${B_CONF[database_password]} -h ${B_CONF[database_host]} ${B_CONF[database_dbname]} < "$GIT_BACKEND_LOCAL/documentation/installation/schema.sql"
        echo "${yellow}Database import done${clear}"
    else
        echo "${red}Cannot locate simon-backend directory! Exiting..${clear}"
    fi
fi