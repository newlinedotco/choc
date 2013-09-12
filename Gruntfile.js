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
       default_options: {
         options: {
           srcBaseDir: "wisp/"
         },
         files: {
           'js/': ['wisp/**/*.wisp']
         }
       }
    },


		bower: {
			options: {
				exclude: ['underscore']
			},
			standard: {
				rjsConfig: 'tmp/config.js'
			},
			global: {
				rjsConfig: 'tmp/global-config.js'
			},
			baseUrl: {
				rjsConfig: 'tmp/baseurl-config.js'
			}
		}
	});

	// grunt.registerTask('bower-install', function () {
	// 	require('bower').commands
	// 		.install([
	// 			'jquery',
	// 			'underscore',
	// 			'requirejs',
	// 			'respond',
	// 			'anima',
	// 			'typeahead.js',
	// 			'highstock'
	// 		]).on('end', this.async());
	// });

  grunt.loadTasks('tasks');
  grunt.registerTask('build', [
    'clean:dist',
    'coffee'
  ]);
};
