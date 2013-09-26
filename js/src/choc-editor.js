(function() {
  var ChocEditor, root,
    __slice = [].slice;

  ChocEditor = (function() {
    var WRAP_CLASS;

    WRAP_CLASS = "CodeMirror-activeline";

    function ChocEditor(options) {
      var defaults;
      defaults = {
        id: "#choc",
        maxIterations: 1000,
        maxAnimationFrames: 100,
        messagesId: "#messages",
        timeline: false,
        timelineValues: true,
        onLoaded: function() {}
      };
      this.options = _.extend(defaults, options);
      this.$ = options.$;
      this.state = {
        delay: null,
        lineWidgets: [],
        editor: {
          activeLine: null
        },
        timeline: {
          activeLine: null,
          activeFrame: null
        },
        slider: {
          value: 0
        },
        mouse: {
          x: 0,
          y: 0
        },
        mouseovercell: false,
        container: null,
        amountElement: null,
        sliderElement: null,
        editorElement: null,
        tlmarkElement: null
      };
      this.setupEditor();
    }

    ChocEditor.prototype.fireEvent = function(name, opts) {
      if (opts == null) {
        opts = {};
      }
      return this.state.container.trigger(name, opts);
    };

    ChocEditor.prototype.setupEditor = function() {
      var onCodeMirrorLoaded,
        _this = this;
      this.state.container = this.$(this.options.id);
      this.state.controlsContainer = $('<div class="controls-container"></div>');
      this.state.amountElement = $('<div class="amount-container"></div>');
      this.state.sliderElement = $('<div class="slider-container"></div>');
      this.state.controlsContainer.append(this.state.amountElement);
      this.state.controlsContainer.append(this.state.sliderElement);
      this.state.editorContainer = $('<div class="editor-container"></div>');
      this.state.editorElement = $('<div></div>');
      this.state.editorContainer.append(this.state.editorElement);
      if (this.options.timeline) {
        this.state.timelineContainer = $('<div class="timeline-container"></div>');
        this.state.timelineElement = $('<div class="timeline"></div>');
        this.state.timelineContainer.append(this.state.timelineElement);
        this.state.editorContainer.addClass("editor-with-timeline");
        this.state.timelineContainer.addClass("timeline-with-editor");
        this.state.editorContainer.css("position", "relative").css("top", "26px");
      }
      this.state.container.append(this.state.controlsContainer);
      this.state.container.append(this.state.editorContainer);
      if (this.options.timeline) {
        this.state.container.append(this.state.timelineContainer);
      }
      this.interactiveValues = {
        onChange: function(v) {
          clearTimeout(_this.state.delay);
          return _this.state.delay = setTimeout((function() {
            return _this.calculateIterations();
          }), 1);
        }
      };
      onCodeMirrorLoaded = function() {
        _this.fireEvent("chocEditorLoaded");
        return _this.options.onLoaded();
      };
      this.codemirror = CodeMirror(this.state.editorElement[0], {
        value: this.options.code,
        mode: "javascript",
        viewportMargin: Infinity,
        tabMode: "spaces",
        interactiveNumbers: this.interactiveValues,
        highlightSelectionMatches: {
          showToken: /\w/
        },
        onLoad: onCodeMirrorLoaded()
      });
      this.codemirror.on("change", function() {
        clearTimeout(_this.state.delay);
        return _this.state.delay = setTimeout((function() {
          return _this.calculateIterations();
        }), 500);
      });
      this.codemirror.on("focus", function() {
        return _this.clearLineWidgets();
      });
      return this.slider = this.state.sliderElement.slider({
        min: 0,
        max: 50,
        change: function(event, ui) {
          return _this.onSliderChange(event, ui);
        },
        slide: function(event, ui) {
          return _this.onSliderChange(event, ui);
        },
        create: function() {
          return _this.fireEvent("chocSliderLoaded");
        }
      });
    };

    ChocEditor.prototype.onSliderChange = function(event, ui) {
      this.state.amountElement.text("step " + ui.value);
      if (event.hasOwnProperty("originalEvent")) {
        this.state.slider.value = ui.value;
        return this.updatePreview();
      }
    };

    ChocEditor.prototype.beforeScrub = function() {
      return this.options.beforeScrub();
    };

    ChocEditor.prototype.afterScrub = function() {
      return this.options.afterScrub();
    };

    ChocEditor.prototype.clearActiveLine = function() {
      if (this.state.editor.activeLine) {
        this.state.editor.activeLine.removeClass(WRAP_CLASS);
      }
      if (this.state.timeline.activeLine) {
        this.state.timeline.activeLine.removeClass("active");
      }
      if (this.state.timeline.activeFrame) {
        return this.state.timeline.activeFrame.removeClass("active");
      }
    };

    ChocEditor.prototype.updateActiveLine = function(cm, lineNumber, frameNumber) {
      var activeFrame, activeRow, activeTd, line, notYetRunTds, runTds;
      line = this.$(this.state.container.find(".CodeMirror-lines pre")[lineNumber]);
      if (cm.state.activeLine === line) {
        return;
      }
      this.clearActiveLine();
      if (line) {
        line.addClass(WRAP_CLASS);
      }
      this.state.editor.activeLine = line;
      if (this.state.timelineElement) {
        this.state.timeline.activeLine = this.$(this.state.timelineElement.find("table tr")[lineNumber + 1]);
        if (this.state.timeline.activeLine) {
          this.state.timeline.activeLine.addClass("active");
        }
        activeRow = this.state.timelineElement.find("table tr")[lineNumber + 1];
        activeTd = this.$(activeRow).find("td")[frameNumber];
        activeFrame = this.$(activeTd).find(".cell");
        this.state.timeline.activeFrame = activeFrame;
        if (this.state.timeline.activeFrame) {
          this.state.timeline.activeFrame.addClass("active");
        }
        runTds = this.state.timelineElement.find("table tr").find("td:nth-child(-n+" + frameNumber + ") .cell");
        notYetRunTds = this.state.timelineElement.find("table tr").find("td:nth-child(n+" + (frameNumber + 1) + ") .cell");
        this.$(runTds).addClass("executed");
        this.$(notYetRunTds).removeClass('executed');
        return this.updateTimelineMarker(activeFrame);
      }
    };

    ChocEditor.prototype.updateTimelineMarker = function(activeFrame, shouldScroll) {
      var relX, timeline;
      if (shouldScroll == null) {
        shouldScroll = true;
      }
      if ((activeFrame != null ? activeFrame.position() : void 0) != null) {
        timeline = this.state.timelineElement;
        relX = activeFrame.position().left + timeline.scrollLeft() + (activeFrame.width() / 2.0);
        this.state.tlmarkElement.css('left', relX);
        if (!this.state.mouseovercell) {
          if (shouldScroll) {
            timeline.scrollLeft(relX - 60);
          }
        }
        return this.state.mouseovercell = false;
      }
    };

    ChocEditor.prototype.onScrub = function(info, opts) {
      if (opts == null) {
        opts = {};
      }
      return this.updateActiveLine(this.codemirror, info.lineNumber - 1, info.frameNumber);
    };

    ChocEditor.prototype.onMessages = function(messages) {
      var firstMessage, _ref,
        _this = this;
      firstMessage = (_ref = messages[0]) != null ? _ref.message : void 0;
      if (firstMessage) {
        return _.map(messages, function(messageInfo) {
          var line, messageString, widget, widgetHtml;
          messageString = "";
          if (_.isObject(messageInfo.message)) {
            messageString = messageInfo.message.inline;
          } else {
            messageString = messageInfo.message;
          }
          line = _this.codemirror.getLineHandle(messageInfo.lineNumber - 1);
          widgetHtml = $("<div class='line-messages'>" + messageString + "</div>");
          widget = _this.codemirror.addLineWidget(line, widgetHtml[0]);
          return _this.state.lineWidgets.push(widget);
        });
      }
    };

    ChocEditor.prototype.generateTimelineTable = function(timeline) {
      var cell, column, display, frameId, headerRow, idx, info, innerCell, klass, message, row, rowidx, self, slider, table, tdiv, timelineCreator, tlmark, updatePreview, updateSlider, value, _i, _j, _len, _ref, _ref1, _ref2, _ref3, _results,
        _this = this;
      tdiv = this.state.timelineElement;
      table = $('<table></table>');
      headerRow = $("<tr></tr>");
      for (column = _i = 0, _ref = timeline.steps.length - 1; _i <= _ref; column = _i += 1) {
        value = "";
        klass = "";
        if ((column % 10) === 0) {
          value = column;
          klass = "mod-ten";
        } else if ((column % 5) === 0) {
          value = "<div class='tick'></div>";
          klass = "mod-five";
        } else {
          value = "<div class='tick'></div>";
          klass = "mod-one";
        }
        headerRow.append("<th><div class='cell " + klass + "'>" + value + "</div></th>");
      }
      table.append(headerRow);
      rowidx = 0;
      while (rowidx < timeline.maxLines + 1) {
        row = $('<tr class="timeline-row"></tr>');
        column = 0;
        while (column < timeline.steps.length) {
          idx = rowidx * column;
          if (timeline.stepMap[column][rowidx]) {
            info = timeline.stepMap[column][rowidx];
            message = (_ref1 = info.messages) != null ? _ref1[0] : void 0;
            display = "&nbsp;";
            frameId = "data-frame-" + info.frameNumber;
            cell = $("<td></td>");
            innerCell = $("<div></div>").addClass("cell content-cell").attr("id", frameId).attr("data-frame-number", info.frameNumber).attr("data-line-number", info.lineNumber);
            cell.append(innerCell);
            if (this.options.timelineValues && ((message != null ? (_ref2 = message.message) != null ? _ref2.timeline : void 0 : void 0) != null)) {
              timelineCreator = message.message.timeline;
              if (_.isFunction(timelineCreator)) {
                timelineCreator(innerCell);
              }
            } else if (this.options.timelineValues && ((message != null ? message.timeline : void 0) != null)) {
              display = message.timeline;
              if (display.hasOwnProperty("_choc_timeline")) {
                display = display._choc_timeline();
              }
              innerCell.html(display);
            } else {
              innerCell.addClass('circle');
              innerCell.html(display);
            }
            row.append(cell);
          } else {
            value = "";
            cell = $("<td><div class='cell'>" + value + "</div></td>");
            row.append(cell);
          }
          column += 1;
        }
        rowidx += 1;
        table.append(row);
      }
      tdiv.html(table);
      tlmark = this.state.tlmarkElement = $("<div class='tlmark'>&nbsp;</div>");
      tlmark.height(tdiv.height() - (2 * row.height()));
      tlmark.css('top', row.height());
      tdiv.append(tlmark);
      slider = this.slider;
      updatePreview = this.updatePreview;
      self = this;
      updateSlider = function(frameNumber) {
        self.$(_this.state.sliderElement).text("step " + frameNumber);
        self.state.slider.value = frameNumber;
        return updatePreview.apply(self);
      };
      _ref3 = this.state.timelineElement.find(".content-cell");
      _results = [];
      for (_j = 0, _len = _ref3.length; _j < _len; _j++) {
        cell = _ref3[_j];
        _results.push((function(cell) {
          return $(cell).on('mouseover', function() {});
        })(cell));
      }
      return _results;
    };

    ChocEditor.prototype.onTimeline = function(timeline) {
      if (this.options.timeline) {
        return this.generateTimelineTable(timeline);
      }
    };

    ChocEditor.prototype.clearLineWidgets = function() {
      return _.map(this.state.lineWidgets, function(widget) {
        return widget.clear();
      });
    };

    ChocEditor.prototype.updatePreview = function() {
      var code, e,
        _this = this;
      this.clearLineWidgets();
      try {
        code = this.codemirror.getValue();
        window.choc.scrub(code, this.state.slider.value, {
          onFrame: function() {
            var args;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            return _this.onScrub.apply(_this, args);
          },
          beforeEach: function() {
            var args;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            return _this.beforeScrub.apply(_this, args);
          },
          afterEach: function() {
            var args;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            return _this.afterScrub.apply(_this, args);
          },
          onMessages: function() {
            var args;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            return _this.onMessages.apply(_this, args);
          },
          locals: this.options.locals
        });
        return this.$(this.options.messagesId).text("");
      } catch (_error) {
        e = _error;
        console.log(e);
        console.log(e.stack);
        return this.$(this.options.messagesId).text(e.toString());
      }
    };

    ChocEditor.prototype.calculateIterations = function(first) {
      var afterAll,
        _this = this;
      if (first == null) {
        first = false;
      }
      afterAll = function() {};
      if (first) {
        afterAll = function(info) {
          var count;
          count = info.frameCount;
          _this.slider.slider('option', 'max', count);
          _this.slider.slider('value', count);
          return _this.state.slider.value = count;
        };
      } else {
        afterAll = function(info) {
          var count, max;
          count = info.frameCount;
          _this.slider.slider('option', 'max', count);
          max = _this.slider.slider('option', 'max');
          if (_this.state.slider.value > max) {
            _this.state.slider.value = max;
            _this.slider.slider('value', max);
            return _this.slider.slider('step', count);
          }
        };
      }
      console.log("regular calculate iterations");
      return window.choc.scrub(this.codemirror.getValue(), this.options.maxIterations, {
        onTimeline: function() {
          var args;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          return _this.onTimeline.apply(_this, args);
        },
        beforeEach: function() {
          var args;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          return _this.beforeScrub.apply(_this, args);
        },
        afterEach: function() {
          var args;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          return _this.afterScrub.apply(_this, args);
        },
        afterFrame: function() {
          var args;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          return _this.afterFrame.apply(_this, args);
        },
        afterAll: afterAll,
        locals: this.options.locals
      });
    };

    ChocEditor.prototype.start = function() {
      this.calculateIterations(true);
      return this.updatePreview();
    };

    return ChocEditor;

  })();

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  root.choc || (root.choc = {});

  root.choc.Editor = ChocEditor;

}).call(this);
