#!/bin/bash

set -e -u -x

TRAVIS_NODE_VERSION=$1

WTSI_NPG_BUILD_BRANCH=$2

unset PERL5LIB

export PATH=/home/travis/.nvm/versions/node/v${TRAVIS_NODE_VERSION}/bin:$PATH
export TEST_AUTHOR=1
export WTSI_NPG_iRODS_Test_irodsEnvFile=$HOME/.irods/.irodsEnv
export WTSI_NPG_iRODS_Test_IRODS_ENVIRONMENT_FILE=$HOME/.irods/irods_environment.json
export WTSI_NPG_iRODS_Test_Resource=testResc

export PERL5LIB=${WTSI_NPG_BUILD_BRANCH}/lib/ #added
eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib) #added

#localib npg
#localib ext

cpanm --notest --installdeps . || find /home/travis/.cpanm/work -cmin -1 -name '*.log' -exec tail -n20  {} \;
perl Build.PL
./Build
./Build test --verbose

#locallib npg
./Build install

#localib ext
pushd npg_qc_viewer
cpanm --notest --installdeps . || find /home/travis/.cpanm/work -cmin -1 -name '*.log' -exec tail -n20  {} \;
perl Build.PL --installjsdeps
./Build
./Build test --verbose
$(npm bin)/grunt -v
popd
