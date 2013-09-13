(function() {
  var ChocAnimationEditor, root;

  ChocAnimationEditor = (function() {
    var gval;

    gval = eval;

    function ChocAnimationEditor(options) {
      var defaults;
      defaults = {
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
        playing: false
      };
      this.setupEditor();
    }

    ChocAnimationEditor.prototype.changeSliderValue = function(newValue) {
      this.$("#amount").text("frame " + newValue);
      return this.state.slider.value = newValue;
    };

    ChocAnimationEditor.prototype.changeSlider = function(newValue) {
      this.changeSliderValue(newValue);
      return this.updateFrameView();
    };

    ChocAnimationEditor.prototype.setupEditor = function() {
      var onSliderChange,
        _this = this;
      this.interactiveValues = {
        onChange: function(v) {
          clearTimeout(_this.state.delay);
          return _this.state.delay = setTimeout((function() {
            return _this.updateViews();
          }), 1);
        }
      };
      this.codemirror = CodeMirror(this.$("#editor")[0], {
        value: this.options.code,
        mode: "javascript",
        viewportMargin: Infinity,
        tabMode: "spaces",
        interactiveNumbers: this.interactiveValues
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
      this.slider = this.$("#slider").slider({
        min: 0,
        max: this.options.maxAnimationFrames,
        change: onSliderChange,
        slide: onSliderChange
      });
      return this.$("#animation-controls").click(function() {
        if (_this.state.playing) {
          return _this.onPause();
        } else {
          return _this.onPlay();
        }
      });
    };

    ChocAnimationEditor.prototype.onPlay = function() {
      this.$("#animation-controls").text("Pause");
      this.state.playing = true;
      this.updateViews();
      return this.options.play();
    };

    ChocAnimationEditor.prototype.onPause = function() {
      this.$("#animation-controls").text("Play");
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
