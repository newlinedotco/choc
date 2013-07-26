NPM_EXECUTABLE_HOME := node_modules/.bin

PATH := ${NPM_EXECUTABLE_HOME}:${PATH}

SRC_FILES  := $(shell find src  -name '*.wisp' | sed -e :a -e '$$!N;s/\n/ /;ta')
TEST_FILES := $(shell find test -name '*.test.*' | sed -e :a -e '$$!N;s/\n/ /;ta')

test:
	./node_modules/.bin/mocha $(TEST_FILES)

watch:
	./node_modules/.bin/mocha --watch

dev: generate-js
	@coffee -wc --bare -o lib src/*.coffee

js: generate-js
	@true

generate-js:
	@find src -name '*.coffee' | xargs coffee -c -o lib/src
	@find test -name '*.coffee' | xargs coffee -c -o lib/test

# calculate lines of code
test-loc:	
	cat $(TEST_FILES) | grep -v -E '^( *#|\s*$$)' | wc -l | tr -s ' '

loc:	
	cat $(SRC_FILES) | grep -v -E '^( *#|\s*$$)' | wc -l | tr -s ' '

package:
	echo FIXME

remove-js:
	@rm -fr lib/

doc:
	@docco src/*.coffee

tree:
	tree -I node_modules

.PHONY: test

install:
	npm install

develop:
	npm install
	npm link
