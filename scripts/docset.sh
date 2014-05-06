# based on http://objcsharp.wordpress.com/2013/09/24/how-to-generate-beautiful-apple-style-documentation-in-xcode-5/
# check the script permissions for x
# type ./docset.sh 
# check your desktop for generated docs

APPLEDOC_PATH=`which appledoc`
if [ $APPLEDOC_PATH ]; then
$APPLEDOC_PATH \
--project-name "LightBlue Bean" \
--project-company "Punch Through Design" \
--company-id "com.punchthrough.LightBlue-Bean" \
--output ~/Desktop/"LightBlue-Bean" \
--keep-undocumented-objects \
--keep-undocumented-members \
--keep-intermediate-files \
--no-repeat-first-par \
--no-warn-invalid-crossref \
--exit-threshold 2 \
../
fi;