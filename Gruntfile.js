'use strict';
module.exports = function (grunt) {
	require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks);

	grunt.initConfig({
		clean: {
      dist: [
				'js',
      ],
			test: [
				'tmp',
				'components',
				'bower_components'
			]
		},

    coffee: {
      dist: {
        files: [{
          expand: true,
          cwd: 'coffee/src',
          src: '*.coffee',
          dest: 'js/src',
          ext: '.js'
        }]
      },
      test: {
        files: [{
          expand: true,
          cwd: 'coffee/test',
          src: '*.coffee',
          dest: 'js/test',
          ext: '.js'
        }]
      }
    },

    wisp: {
      dist: {
        options: {
          srcBaseDir: "wisp/"
        },
        files: {
          'js/': ['wisp/**/*.wisp']
        }
      }
    },

    browserify: {
      dist: {
        files: {
          'dist/choc.browser.js': ['tools/entry-point.js']
        }
      }
    },

    watch: {
      coffee: {
        files: ['coffee/src/*.coffee'],
        tasks: ['coffee:dist', 'wisp', 'browserify']
      }
    }
	});

  grunt.loadTasks('tasks');
  grunt.registerTask('build', [
    'clean:dist',
    'coffee',
    'wisp',
    'browserify'
  ]);

};
