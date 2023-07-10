# Lazy typing, very useful
sui () {
  cd Assets/StandardUI 2>/dev/null || cd Assets/standardui
}

# Lazy typing, less useful
sm () {
  cd Assets/StandardModules 2>/dev/null || cd Assets/standardmodules
}

bumpversion() {
  appversionline=$(grep AppVersion Assets/Resources/PhotonServerSettings.asset)
  text=`echo $appversionline | sed "s/\([^0-9]*\)\([\.0-9]*\)/\1/"`
  num=`echo $appversionline | sed "s/\([^0-9]*\)\([\.0-9]*\)/\2/"` ; num=$( printf "%.1f\n" $(echo $(( num + 0.1 )) ) )
  sed -i '' -re "s/.*    AppVersion: [\.0-9].*/$text$num/" Assets/Resources/PhotonServerSettings.asset
  
  bundleversionline=$(grep bundleVersion ProjectSettings/ProjectSettings.asset)
  text=`echo $bundleversionline | sed "s/\([^0-9]*\)\([\.0-9]*\)/\1/"`
  num=`echo $bundleversionline | sed "s/\([^0-9]*\)\([\.0-9]*\)/\2/"` ; num=$( printf "%.1f\n" $(echo $(( num + 0.1 )) ) )
  sed -i '' -re "s/.*  bundleVersion: [\.0-9].*/$text$num/" ProjectSettings/ProjectSettings.asset
  
  androidversioncode=$(grep AndroidBundleVersionCode ProjectSettings/ProjectSettings.asset)
  text=`echo $androidversioncode | sed "s/\([^0-9]*\)\([\.0-9]*\)/\1/"`
  num=`echo $androidversioncode | sed "s/\([^0-9]*\)\([\.0-9]*\)/\2/"` ; num=$( printf "%.0f\n" $(echo $(( num + 1 )) ) )
  sed -i '' -re "s/.*  AndroidBundleVersionCode: [\.0-9].*/$text$num/" ProjectSettings/ProjectSettings.asset

  git add Assets/Resources/PhotonServerSettings.asset ProjectSettings/ProjectSettings.asset
  gdc
  echo "Press enter to commit"
  read
  git commit -m "Bump Project and Photon settings version number"
  git push
}

# Updates StandardUI and StandardModules repos. Use this in the project root folder!
# Usage:
# updatesuism
updatesuism () {
  BRANCH="$*"
  echo ${BRANCH-development}
  veryclean ${BRANCH-development}
  git add Assets/StandardUI Assets/StandardModules
  git commit -m "Update StandardUI and StandardModules"
  git push
}

# Clears all your changes
# All of them
# Very useful when finishing a task
veryclean() {
  BRANCH="$*"
  echo ${BRANCH-development}
  git rebase --abort
  git restore --staged .
  git checkout .
  git clean -fd 
  git bisect reset
  git checkout .
  git clean -fd 
  git checkout ${BRANCH-development}
  git reset --hard origin/${BRANCH-development}
  git pull
  git submodule update --remote --force
  git submodule foreach git checkout .
  git submodule foreach git clean -fd
  git submodule foreach git checkout master
  git submodule foreach git pull
}

build () {
  branch_name="$(git symbolic-ref HEAD 2>/dev/null)" 
  branch_name=${branch_name##refs/heads/}
  git pull ; git checkout build ; git  reset --hard ${branch_name} ; git push -f ; git checkout ${branch_name}     
}

puzzlecats() {
  cd ~/Projects/puzzlecats 2>/dev/null || cd ~/Projects/Puzzlecats
}
