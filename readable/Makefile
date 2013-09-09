NPM_EXECUTABLE_HOME := node_modules/.bin

PATH := ${NPM_EXECUTABLE_HOME}:${PATH}

JS_DIR   = js
WISP_SRC_DIR = src
WISP_TEST_DIR = test

SRC_FILES  := $(shell find src  -name '*.wisp' | sed -e :a -e '$$!N;s/\n/ /;ta')
TEST_FILES := $(shell find test -name '*.wisp' | sed -e :a -e '$$!N;s/\n/ /;ta')

SRC_JS    := $(patsubst $(WISP_SRC_DIR)/%,$(JS_DIR)/src/%,$(patsubst %.wisp,%.js,$(SRC_FILES)))
TEST_JS   := $(patsubst $(WISP_TEST_DIR)/%,$(JS_DIR)/test/%,$(patsubst %.wisp,%.js,$(SRC_FILES)))

WISP := wisp

.PHONY: clean compile test

test:
	$(WISP) test/readable.wisp

watchtest:
	./node_modules/.bin/supervisor --watch src,test --extensions wisp --exec 'make' --no-restart-on exit test

watch:
	./node_modules/.bin/supervisor --watch src,test --extensions wisp --exec 'make' --no-restart-on exit compile

# dev: generate-js
# 	@coffee -wc --bare -o lib src/*.coffee

$(JS_DIR)/src:
	mkdir $(JS_DIR)/src

$(JS_DIR)/test:
	mkdir $(JS_DIR)/test

js: clean compile
	@true

compile: $(SRC_JS) Makefile

clean:
	rm -rf js/*.js

$(JS_DIR)/src/%.js : $(WISP_SRC_DIR)/%.wisp $(JS_DIR)/src
	cat $< | $(WISP) > $@

$(JS_DIR)/test/%.js : $(WISP_TEST_DIR)/%.wisp $(JS_DIR)/test
	cat $< | $(WISP) > $@

# package:
# 	echo FIXME

tree:
	tree -I node_modules

install:
	npm install

develop:
	npm install
	npm link
