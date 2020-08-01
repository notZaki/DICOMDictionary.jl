#!/bin/sh
# Adapted from: https://gist.github.com/willprice/e07efd73fb7f13f917ea

setup_git() {
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis CI"
}

send_to_github() {
  git checkout --orphan dcm_dict
  git rm -rf .
  git remote add origin-pages https://${GH_TOKEN}@github.com/notZaki/DICOM_Dictionary.jl > /dev/null 2>&1
  git pull origin-pages dcm_dict
  cp test/dcm_dict.jl ./dcm_dict.jl
  git add dcm_dict.jl
  git commit --message "Travis build: $TRAVIS_BUILD_NUMBER"
  git push --quiet --set-upstream origin-pages dcm_dict
}


setup_git
send_to_github
