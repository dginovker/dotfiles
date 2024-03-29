# Check if Java is installed
if ! java -version 2> /dev/null; then
    # echo "Java is not installed, skipping Java version aliasing"
    return
fi

# Only run if we're running on MacOS 
if uname 2> /dev/null | grep -q Darwin ; then 
  alias j12="export JAVA_HOME=`/usr/libexec/java_home -v 12`; java -version" 
  alias j11="export JAVA_HOME=`/usr/libexec/java_home -v 11`; java -version" 
  alias j10="export JAVA_HOME=`/usr/libexec/java_home -v 10`; java -version" 
  alias j9="export JAVA_HOME=`/usr/libexec/java_home -v 9`; java -version" 
  alias j8="export JAVA_HOME=`/usr/libexec/java_home -v 1.8`; java -version" 
  alias j7="export JAVA_HOME=`/usr/libexec/java_home -v 1.7`; java -version" 
fi
