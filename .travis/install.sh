#!/bin/bash

set -e -u -x

# The default build branch for all repositories. This defaults to
# TRAVIS_BRANCH unless set in the Travis build environment.
WTSI_NPG_BUILD_BRANCH=$1

WTSI_NPG_GITHUB_URL=$2

CONDA_TEST_ENV=$3

TRAVIS_PYTHON_VERSION=$4

CONDA_CHANNEL=$5

# testing adding conda stuff here TODO
wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-4.5.11-Linux-x86_64.sh -O miniconda.sh

/bin/bash miniconda.sh -b -p "$HOME/miniconda"
export PATH="$HOME/miniconda/bin:$PATH"
hash -r

conda config --set always_yes yes
conda config --set changeps1 no
conda config --set show_channel_urls true
#conda update -q conda # temp remove TODO

#check conda environments
conda info --envs
#

conda config --add channels $CONDA_CHANNEL

# Useful for debugging any issues with conda
conda info -a


# CPAN as in npg_npg_deploy
cpanm --notest --reinstall App::cpanminus
cpanm --quiet --notest Alien::Tidyp
cpanm --quiet --notest LWP::Protocol::https
cpanm --quiet --notest https://github.com/chapmanb/vcftools-cpan/archive/v0.953.tar.gz

# Conda
export PATH="$HOME/miniconda/bin:$PATH"
conda create -q --name "$CONDA_TEST_ENV" python=$TRAVIS_PYTHON_VERSION
conda install --name "$CONDA_TEST_ENV" npg_qc_utils
conda install --name "$CONDA_TEST_ENV" baton

#activating created conda environment
export PATH="$HOME/miniconda/bin:$PATH"
source activate "$CONDA_TEST_ENV"

#TODO adding in perl5lib location for npg_qc locations
export PERL5LIB=${WTSI_NPG_BUILD_BRANCH}/lib/npg_qc/:$PERL5LIB

 #WTSI NPG Perl repo dependencies
repos=""
for repo in perl-dnap-utilities ml_warehouse npg_tracking npg_seq_common perl-irods-wrap; do
    cd /tmp
    # Always clone master when using depth 1 to get current tag
    git clone --branch master --depth 1 ${WTSI_NPG_GITHUB_URL}/${repo}.git ${repo}.git
    cd /tmp/${repo}.git
    # Shift off master to appropriate branch (if possible)
    git ls-remote --heads --exit-code origin ${WTSI_NPG_BUILD_BRANCH} && git pull origin ${WTSI_NPG_BUILD_BRANCH} && echo "Switched to branch ${WTSI_NPG_BUILD_BRANCH}"
    repos=$repos" /tmp/${repo}.git"
done

# Finally, bring any common dependencies up to the latest version and
# install

for repo in $repos
do
    cd $repo
    cpanm --quiet --notest --installdeps . || find /home/travis/.cpanm/work -cmin -1 -name '*.log' -exec tail -n20  {} \;		
    perl Build.PL
    ./Build		
    ./Build install
done

cd
