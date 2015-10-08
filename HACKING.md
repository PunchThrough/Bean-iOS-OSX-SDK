# Developer Documentation

Welcome to the Developer documentation for the Bean iOS/OSX SDK.

## Building the Docs

Install appledoc. The best way to do this is cloning the repo and running an install script:

```bash
$ git clone git://github.com/tomaz/appledoc.git
$ sudo ./install-appledoc.sh -t default
```

Build the docs:

```bash
/usr/local/bin/appledoc \
--project-name "Bean iOS/OSX SDK" \
--project-company "Punch Through Design" \
--company-id "com.ptd" \
--output "build/" \
--logformat xcode \
--keep-undocumented-objects \
--keep-undocumented-members \
--keep-intermediate-files \
--no-repeat-first-par \
--no-warn-invalid-crossref \
--ignore "*.m" \
--ignore "LoadableCategory.h" \
--index-desc "README.md" \
source/
```

Once the docs are built you can open `build/html/index.html` in a web browser.
