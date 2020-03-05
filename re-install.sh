#!/bin/bash

# NodeJS Settings
NODE_VERSION=7.6.0

# Database Settings
PSQL_VERSION=9.6
PSQL_USERNAME=yara_guardian
PSQL_PASSWORD=yara_guardian_password
PSQL_DATABASE=yara_guardian
PSQL_HOST=127.0.0.1
PSQL_PORT=5432

if [ "$1" = "vagrant" ]; then
    INSTALL_DIR="/vagrant"
    HOME_PROFILE="/home/ubuntu/.profile"

    # Set environment variables
    echo "export DEBUG=True" >> ${HOME_PROFILE}
    echo "export SECRET_KEY=DEVELOPMENT_MODE" >> ${HOME_PROFILE}

    echo "export DATABASE_NAME=${PSQL_DATABASE}" >> ${HOME_PROFILE}
    echo "export DATABASE_USER=${PSQL_USERNAME}" >> ${HOME_PROFILE}
    echo "export DATABASE_PASS=${PSQL_PASSWORD}" >> ${HOME_PROFILE}
    echo "export DATABASE_HOST=${PSQL_HOST}" >> ${HOME_PROFILE}
    echo "export DATABASE_PORT=${PSQL_PORT}" >> ${HOME_PROFILE}

    echo "export GUEST_REGISTRATION=INVITE" >> ${HOME_PROFILE}
else
    INSTALL_DIR=${PWD}
fi

sudo apt-get update
sudo apt-get -y upgrade

####################################
### Install Python3 dependencies ###
####################################
echo "Installing Python 3 and other system dependencies"
sudo apt-get install -y python3-all-dev libpq-dev python3-pip

#####################################
### Add PostgreSQL Apt Repository ###
#####################################
sudo echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > \
  /etc/apt/sources.list.d/pgdg.list

wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
  sudo apt-key add -

sudo apt-get update

#################################################
### Install and configure PostgreSQL database ###
#################################################
echo "Installing Postgresql Database ${PSQL_VERSION}"
sudo apt-get install -y postgresql-${PSQL_VERSION} postgresql-server-dev-${PSQL_VERSION}

echo "Starting Postgresql Server"
sudo systemctl start postgresql

echo "Configuring Postgresql Database"
sudo -u postgres psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS hstore"
sudo -u postgres psql -c "CREATE DATABASE ${PSQL_DATABASE}"
sudo -u postgres psql -c "CREATE USER ${PSQL_USERNAME} WITH PASSWORD '${PSQL_PASSWORD}' CREATEDB"


###################################################
### Install and configure Yarn package manager ###
###################################################
echo "Installing and Configuring yarn"
sudo apt-get install -y git npm

# Get Specified Version of Node
sudo npm cache clean -f
sudo npm install -g n
n ${NODE_VERSION}
sudo ln -sf /usr/local/n/versions/node/${NODE_VERSION}/bin/node /usr/bin/node

#################################################
### Install Python and front-end dependencies ###
#################################################
cd ${INSTALL_DIR}

echo "Installing Python dependencies"
export PIPENV_VENV_IN_PROJECT=true
pip3 install pipenv
# Remove any old already existing pipenv to avoid clutter and other silent issues.
pipenv --rm

pipenv install --deploy

# Replace django-angular with forked (fixed) version.
pipenv run pip install -U git+https://github.com/BluABK/django-angular.git


# Install dependencies
echo "Installing front-end dependencies"
npm install
npm install yarn -g
yarn
yarn webpack
