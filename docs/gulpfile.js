var gulp = require('gulp')
var ghPages = require('gulp-gh-pages')
var exec = require('child_process').exec

buildDocsCmd = [
  '/usr/local/bin/appledoc',
  '--project-name "Bean iOS/OSX SDK"',
  '--project-company "Punch Through Design"',
  '--company-id "com.ptd"',
  '--output ".build/"',
  '--logformat xcode',
  '--keep-undocumented-objects',
  '--keep-undocumented-members',
  '--keep-intermediate-files',
  '--no-repeat-first-par',
  '--no-warn-invalid-crossref',
  '--ignore "*.m"',
  '--ignore "LoadableCategory.h"',
  'source/'
].join(' ')

var config = {
  push: true
}

var execOpts = {
  cwd: '..'
}

gulp.task('build', function(done) {
  exec(buildDocsCmd, execOpts, function(err, stdout, stderr) {
    // Don't check 'err' and assume this works...it seems appledoc will
    // return a non-zero return code even though it generates valid HTML
    process.stdout.write(stdout)
    process.stderr.write(stderr)
    done()
  })
})

gulp.task('deploy', ['build'], function() {
  return gulp.src('../build/html/**/*')
    .pipe(ghPages(config))
})
