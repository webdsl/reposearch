targetdir=reposearch-app

echo -e "appname=reposearch\ndb=h2\ndbfile=reposearch.db\nindexdir=index\ndbmode=update\nsearchstats=true" > application.ini
webdsl build war
ant -f .servletapp/build.xml copy-clean-tomcat
mkdir $targetdir
mkdir $targetdir/app-files
cp -r .servletapp/tomcat/tomcat $targetdir/app-files/tomcat
cp .servletapp/reposearch.war $targetdir/app-files/tomcat/webapps/reposearch.war
echo -e "sh ./app-files/tomcat/bin/catalina.sh run" > $targetdir/run.sh
echo -e "./app-files/tomcat/bin/catalina.bat run" > $targetdir/run.bat
chmod +x $targetdir/app-files/tomcat/bin/*.sh
chmod +x $targetdir/run.sh
