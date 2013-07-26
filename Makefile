NPM_EXECUTABLE_HOME := node_modules/.bin

PATH := ${NPM_EXECUTABLE_HOME}:${PATH}

JSDIR   = js
WISPDIR = src

SRC_FILES  := $(shell find src  -name '*.wisp' | sed -e :a -e '$$!N;s/\n/ /;ta')
TEST_FILES := $(shell find test -name '*.test.*' | sed -e :a -e '$$!N;s/\n/ /;ta')

SRC_JS    := $(patsubst $(WISPDIR)/%,$(JSDIR)/%,$(patsubst %.wisp,%.js,$(SRC_FILES)))

WISP := wisp

.PHONY: clean compile

test:
	./node_modules/.bin/mocha $(TEST_FILES)

watch:
	./node_modules/.bin/mocha --watch

dev: generate-js
	@coffee -wc --bare -o lib src/*.coffee

js: generate-js
	@true

compile: clean $(SRC_JS) Makefile

clean:
	rm -rf js/*.js

$(JSDIR)/%.js : $(WISPDIR)/%.wisp
	cat $< | $(WISP) > $@

# generate-js:
# 	@find cat ./src/ast.wisp | $(WISP) > ./ast.js
# 	@find src -name '*.wisp' | xargs $(WISP) -c -o lib/src
# 	@find test -name '*.coffee' | xargs coffee -c -o lib/test

package:
	echo FIXME

tree:
	tree -I node_modules

install:
	npm install

develop:
	npm install
	npm link
