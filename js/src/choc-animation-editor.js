(function() {
  var ChocAnimationEditor, root;

  ChocAnimationEditor = (function() {
    var gval;

    gval = eval;

    function ChocAnimationEditor(options) {
      var defaults;
      defaults = {
        id: "#choc",
        maxIterations: 1000,
        maxAnimationFrames: 100
      };
      this.options = _.extend(defaults, options);
      this.$ = options.$;
      this.state = {
        delay: null,
        slider: {
          value: 0
        },
        playing: false,
        container: null,
        amountElement: null,
        sliderElement: null,
        editorElement: null,
        tlmarkElement: null
      };
      this.setupEditor();
    }

    ChocAnimationEditor.prototype.setupEditor = function() {
      var onSliderChange,
        _this = this;
      this.state.container = this.$(this.options.id);
      this.state.controlsContainer = $('<div class="controls-container"></div>');
      this.state.amountElement = $('<div class="amount-container"></div>');
      this.state.sliderElement = $('<div class="slider-container"></div>');
      this.state.animationControlsElement = $('<a href="#" class="animation-controls">Play</a>');
      this.state.controlsContainer.append(this.state.amountElement);
      this.state.controlsContainer.append(this.state.sliderElement);
      this.state.controlsContainer.append(this.state.animationControlsElement);
      this.state.editorContainer = $('<div class="editor-container"></div>');
      this.state.editorElement = $('<div></div>');
      this.state.editorContainer.append(this.state.editorElement);
      this.state.container.append(this.state.controlsContainer);
      this.state.container.append(this.state.editorContainer);
      this.interactiveValues = {
        onChange: function(v) {
          clearTimeout(_this.state.delay);
          return _this.state.delay = setTimeout((function() {
            return _this.updateViews();
          }), 1);
        }
      };
      this.codemirror = CodeMirror(this.state.editorElement[0], {
        value: this.options.code,
        mode: "javascript",
        viewportMargin: Infinity,
        tabMode: "spaces",
        interactiveNumbers: this.interactiveValues,
        highlightSelectionMatches: {
          showToken: /\w/
        }
      });
      this.codemirror.on("change", function() {
        clearTimeout(_this.state.delay);
        return _this.state.delay = setTimeout((function() {
          return _this.updateViews();
        }), 500);
      });
      onSliderChange = function(event, ui) {
        if (event.hasOwnProperty("originalEvent")) {
          return _this.changeSlider(ui.value);
        }
      };
      this.slider = this.state.sliderElement.slider({
        min: 0,
        max: this.options.maxAnimationFrames,
        change: onSliderChange,
        slide: onSliderChange
      });
      return this.state.animationControlsElement.click(function() {
        if (_this.state.playing) {
          _this.onPause();
        } else {
          _this.onPlay();
        }
        return false;
      });
    };

    ChocAnimationEditor.prototype.changeSliderValue = function(newValue) {
      this.state.amountElement.text("frame " + newValue);
      return this.state.slider.value = newValue;
    };

    ChocAnimationEditor.prototype.changeSlider = function(newValue) {
      this.changeSliderValue(newValue);
      return this.updateFrameView();
    };

    ChocAnimationEditor.prototype.onPlay = function() {
      this.state.animationControlsElement.text("Pause");
      this.state.playing = true;
      this.updateViews();
      return this.options.play();
    };

    ChocAnimationEditor.prototype.onPause = function() {
      this.state.animationControlsElement.text("Play");
      this.state.playing = false;
      this.options.pause();
      return this.updateViews();
    };

    ChocAnimationEditor.prototype.onFrame = function(frameCount, timeDelta) {
      this.changeSliderValue(frameCount);
      return this.slider.slider('value', frameCount);
    };

    ChocAnimationEditor.prototype.updateFrameView = function() {
      var appendSource, code, e;
      try {
        code = this.codemirror.getValue();
        if (this.options.animate != null) {
          appendSource = "for(var __i=0; __i<" + this.state.slider.value + "; __i++) {\n  if(__i == " + (this.state.slider.value - 1) + ") {\n    pad.clear();\n    " + this.options.animate + "();\n    pad.update();\n  } else {\n  " + this.options.animate + "();\n  }\n}";
        }
        this.runCode(this.codemirror.getValue() + appendSource, false);
        return this.$("#messages").text("");
      } catch (_error) {
        e = _error;
        console.log(e);
        console.log(e.stack);
        return this.$("#messages").text(e.toString());
      }
    };

    ChocAnimationEditor.prototype.runCode = function(code, isPreview) {
      var localsIndex, localsStr;
      if (isPreview == null) {
        isPreview = false;
      }
      gval = eval;
      localsIndex = isPreview ? 1 : 0;
      window._choc_preview_locals = this.options.locals;
      localsStr = _.map(_.keys(this.options.locals), function(name) {
        return "var " + name + " = _choc_preview_locals." + name + "[" + localsIndex + "]";
      }).join("; ");
      return gval(localsStr + "\n" + code);
    };

    ChocAnimationEditor.prototype.updateViews = function() {
      this.generatePreview();
      return this.updateFrameView();
    };

    ChocAnimationEditor.prototype.generatePreview = function() {
      var draw, _base, _base1, _fn, _i, _ref;
      if (typeof (_base = this.options).beforeGeneratePreview === "function") {
        _base.beforeGeneratePreview();
      }
      this.runCode(this.codemirror.getValue(), true);
      draw = gval(this.options.animate);
      _fn = function() {
        return draw();
      };
      for (_i = 1, _ref = this.options.maxAnimationFrames; 1 <= _ref ? _i <= _ref : _i >= _ref; 1 <= _ref ? _i++ : _i--) {
        _fn();
      }
      return typeof (_base1 = this.options).afterGeneratePreview === "function" ? _base1.afterGeneratePreview() : void 0;
    };

    ChocAnimationEditor.prototype.start = function(frame) {
      if (frame == null) {
        frame = 1;
      }
      this.changeSlider(frame);
      return this.updateViews();
    };

    return ChocAnimationEditor;

  })();

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  root.choc || (root.choc = {});

  root.choc.AnimationEditor = ChocAnimationEditor;

}).call(this);
