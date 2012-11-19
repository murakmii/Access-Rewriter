// Generated by CoffeeScript 1.4.0
(function() {
  var create_data_url_scheme, global, main, setup;

  global = this;

  global.app = {
    is_ready: false,
    setup_failed: false,
    config: null
  };

  main = function(config, data) {
    if (!global.app.setup_failed) {
      global.app.config = new global.config(config.app, data);
    }
    return global.app.is_ready = true;
  };

  setup = function() {
    return chrome.storage.local.get(["version", "app"], function(config) {
      var data, default_config, id, id_array, property, rewrite, version;
      if (chrome.runtime.lastError != null) {
        global.app.setup_failed = true;
        main();
        return;
      }
      version = chrome.runtime.getManifest().version;
      if ((config.version != null) && config.version !== version) {
        return main();
      } else if (!(config.version != null)) {
        default_config = {
          version: version,
          app: {
            disabled_all: false,
            rewrite: []
          }
        };
        return chrome.storage.local.set(default_config, function() {
          global.app.setup_failed = chrome.runtime.lastError != null;
          return main((global.app.setup_failed ? null : default_config), {});
        });
      } else {
        id_array = (function() {
          var _i, _len, _ref, _results;
          _ref = config.app.rewrite;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            rewrite = _ref[_i];
            _results.push(rewrite.id);
          }
          return _results;
        })();
        data = {};
        if (id_array.length === 0) {
          return main(config, data);
        } else {
          id = id_array.shift();
          property = "data_" + id;
          return chrome.storage.local.get(property, function(got) {
            if (chrome.runtime.lastError != null) {
              global.app.setup_failed = true;
              return main();
            } else {
              data[property] = got[property];
              if ((id = id_array.shift()) != null) {
                property = "data_" + id;
                return chrome.storage.local.get(property, arguments.callee);
              } else {
                return main(config, data);
              }
            }
          });
        }
      }
    });
  };

  create_data_url_scheme = function(rewrite) {
    var data;
    data = "data:" + rewrite.mime_header + "/" + rewrite.mime_body;
    if (rewrite.base64) {
      data += ";base64";
    }
    data += "," + global.app.config.get_data(rewrite.id);
    return data;
  };

  chrome.runtime.onInstalled.addListener(setup);

  chrome.runtime.onStartup.addListener(setup);

  chrome.webRequest.onBeforeRequest.addListener(function(detail) {
    var rewrite, url_pattern, _i, _len, _ref;
    if (global.app.is_ready && !global.app.setup_failed && !global.app.config.disabled_all()) {
      _ref = global.app.config.get_rewrites();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        rewrite = _ref[_i];
        if (!rewrite.disabled) {
          if (rewrite.url_is_regex) {
            url_pattern = new RegExp(rewrite.url);
            if (detail.url.match(url_pattern)) {
              return {
                redirectUrl: create_data_url_scheme(rewrite)
              };
            }
          } else {
            if (detail.url === rewrite.url) {
              return {
                redirectUrl: create_data_url_scheme(rewrite)
              };
            }
          }
        }
      }
      return {
        cancel: false
      };
    } else {
      return {
        cancel: false
      };
    }
  }, {
    urls: ["*://*/*"]
  }, ["blocking"]);

}).call(this);
