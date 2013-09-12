/*
 * grunt-wisp
 * https://github.com/syuta/grunt-wisp
 *
 * Copyright (c) 2013 syuta
 * Licensed under the MIT license.
 */

'use strict';

module.exports = function (grunt) {


    grunt.registerMultiTask('wisp', 'compile Wrap files into Javascript.', function () {

        var done = this.async();
        var target = this.target;
        var srcBaseDir = grunt.config('wisp')[target].options.srcBaseDir;

        // Iterate over all specified file groups.
        this.files.forEach(function (f) {
            var files = f.src.toString().split(",")
            compile(srcBaseDir, f.dest, files, done)
        });
    });

    /**
     * compile wisp files.
     * @param srcBaseDir
     * @param path
     * @param files
     * @param done
     */
    var compile = function (srcBaseDir, path, files, done) {
        var exec = require('child_process').exec;

        if (files.length === 0) {
            done();
        } else {
            var mkdirp = require('mkdirp');

            var file = files.pop(); //コンパイル対象ファイルパス
            var filePathArray = file.replace(srcBaseDir, path).split("/");//出力先パスを/区切り
            var fileName = filePathArray[filePathArray.length - 1];//ファイル名取得

            var destPath = "";
            for (var i = 0; i < filePathArray.length - 1; i++) {
                destPath += filePathArray[i] + "/";
            }

            //make dir
            mkdirp.sync(destPath);
            var destFileName = fileName.split(".")[0];//拡張子を除く
            exec('cat ' + file + '| wisp > ' + destPath + destFileName + ".js", function (err, stdout, stderr) {
                grunt.log.writeln('File ' + destPath + destFileName + '.js created.');
                compile(srcBaseDir, path, files, done);
            });
        }
    };


};
