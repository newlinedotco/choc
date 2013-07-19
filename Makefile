NPM_EXECUTABLE_HOME := node_modules/.bin

PATH := ${NPM_EXECUTABLE_HOME}:${PATH}

SRC_FILES     := $(shell find coffee/src  -name '*.coffee' | sed -e :a -e '$$!N;s/\n/ /;ta')
TEST_FILES    := $(shell find coffee/test -name '*.test.*' | sed -e :a -e '$$!N;s/\n/ /;ta')
JS_SRC_FILES  := $(shell find js/src  -name '*.js' | sed -e :a -e '$$!N;s/\n/ /;ta')
JS_TEST_FILES := $(shell find js/test -name '*.test.*' | sed -e :a -e '$$!N;s/\n/ /;ta')

.PHONY: test test-js install watch js watch-js loc test-loc clean tree develop server workers run

test:
	./node_modules/.bin/mocha --compilers coffee:coffee-script $(TEST_FILES)

test-js: js
	./node_modules/.bin/mocha $(JS_TEST_FILES)

install:
	npm install

watch:
	./node_modules/.bin/supervisor --watch coffee/ --extensions coffee --exec 'make' --no-restart-on exit build

js: clean
	coffee -c -o ./js ./coffee

watch-js: clean
	coffee -wc -o ./js ./coffee

loc:
	cat $(SRC_FILES) | grep -v -E '^( *#|\s*$$)' | wc -l | tr -s ' '

# calculate lines of code
test-loc:
	cat $(TEST_FILES) | grep -v -E '^( *#|\s*$$)' | wc -l | tr -s ' '

clean:
	@rm -fr js/

tree:
	tree -I node_modules

develop:
	npm install
	npm link

browserify:
	npm run-script build

build: js browserify

.PHONY: test build
