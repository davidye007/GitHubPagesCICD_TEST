#!/bin/bash -e

install() {
  set -e
  python -m pip install --upgrade pip
  pip install flake8
  pip install wheel
  cd trails-viz-app
  npm install
  cd ..
  cd trails-viz-api
  pip install -r requirements.txt
  cd ..
  exit 0
}

package() {
  set -e
  cd trails-viz-app
  npm run lint
  npm run build
  cd ..
  cd trails-viz-api
  flake8 . --count --max-line-length=119 --exclude trailsvizapi/__init__.py --show-source --statistics
  python setup.py bdist_wheel
  cd ..
  exit 0
}


update_version() {
  set -e
  commit_message=$(git log -1 --pretty=%B)  # Get commit message
  # get the version bump part from commit message
  echo "Updating version..."
  if [[ "$commit_message" == *"release=major"* ]]; then
    version_bump="major"
  elif [[ "$commit_message" == *"release=minor"* ]]; then
    version_bump="minor"
  elif [[ "$commit_message" == *"release=patch"* ]]; then
    version_bump="patch"
  else
    version_bump="patch"
  fi

  # update the version in package.json as it's the easiest thing to do using npm
  git checkout master
  cd frontend_stuff
  new_version=$(npm version $version_bump)  # this returs the new version number with 'v' as prefix
  # new_version=$(echo "$new_version" | awk -Fv '{print $2}')
  # cd ..
  # cd trails-viz-api
  # sed -i "s/__version__.*/__version__ = '$new_version'/" trailsvizapi/__init__.py
  cd ..
  echo "local version bump successful $new_version"

  git add frontend_stuff/package.json
  git add frontend_stuff/package-lock.json
  git add trails-viz-api/trailsvizapi/__init__.py
  git commit -m "Auto update version to $new_version"
  echo "commited after version update"
  git push origin master
  git tag v"$new_version"
  git push origin --tags
  echo "pushed new version to master"
}

deploy() {
  set -e
  update_version
}

if [ $# -eq 0 ]
  then
    echo "no command line argument passed, required one of: install | package | deploy"
    exit 1
fi

action=$1
if [ "$action" = "install" ]; then
  install
elif [ "$action" = "package" ]; then
  package
elif [ "$action" = "deploy" ]; then
  deploy
else
  echo "invalid command line argument $action, required one of install | package | deploy"
  exit 1
fi