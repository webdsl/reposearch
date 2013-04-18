targetdir=reposearch-app

echo -e "appname=reposearch\ndb=h2\ndbfile=reposearch.db\nindexdir=index\ndbmode=update" > application.ini
webdsl build
webdsl check-web
mkdir $targetdir
cp -r .servletapp/ $targetdir/app-files
echo -e "cd app-files\njava -cp "WEB-INF/classes/:WEB-INF/lib/*" utils.TestRun" > $targetdir/run.sh
chmod +x $targetdir/run.sh
cp $targetdir/run.sh $targetdir/run.bat