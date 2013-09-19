NPM_EXECUTABLE_HOME := node_modules/.bin

PATH := ${NPM_EXECUTABLE_HOME}:${PATH}

SRC_FILES     := $(shell find coffee/src  -name '*.coffee' | sed -e :a -e '$$!N;s/\n/ /;ta')
TEST_FILES    := $(shell find coffee/test -name '*.test.*' | sed -e :a -e '$$!N;s/\n/ /;ta')
JS_SRC_FILES  := $(shell find js/src  -name '*.js' | sed -e :a -e '$$!N;s/\n/ /;ta')
JS_TEST_FILES := $(shell find js/test -name '*.test.*' | sed -e :a -e '$$!N;s/\n/ /;ta')

.PHONY: test test-js install watch js watch-js loc test-loc clean tree develop server workers run

all: build

test:
	./node_modules/.bin/mocha --compilers coffee:coffee-script $(TEST_FILES)

watchtest:
	./node_modules/.bin/mocha --watch --compilers coffee:coffee-script $(TEST_FILES)

test-js: js
	./node_modules/.bin/mocha $(JS_TEST_FILES)

install:
	npm install
	bower install

watch:
	grunt watch

loc:
	cat $(SRC_FILES) | grep -v -E '^( *#|\s*$$)' | wc -l | tr -s ' '

# calculate lines of code
test-loc:
	cat $(TEST_FILES) | grep -v -E '^( *#|\s*$$)' | wc -l | tr -s ' '

clean:
	grunt clean

tree:
	tree -I node_modules

develop:
	npm link
	bower link

build:
	grunt build

.PHONY: test build

