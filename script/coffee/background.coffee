
global = @
global.app =
   is_ready       : false
   setup_failed   : false
   config         : null

main = ( config ) ->
   if not global.app.setup_failed
      global.app.config = new global.config config.app

   global.app.is_ready = true

# 設定のセットアップを行う
# 途中でエラーが発生した場合はglobal.app.setup_failedをtrueに設定する
# 処理の終了後、設定データを引数にmainを呼び出す。global.app.setup_filedがtrueに設定されている場合は引数はnullとなる
setup = ( ) ->
   chrome.storage.local.get [ "version", "app" ], ( config ) ->

      if chrome.runtime.lastError?
         global.app.setup_failed = true
         main( null )
         return

      version = chrome.runtime.getManifest( ).version
      if config.version? and config.version isnt version

         # ここにバージョン間の設定の差異を補完するコード
         main( null )

      else if not config.version?
         default_config = 
            version: version
            app:
               disabled_all   : false
               rewrite        : [ ]
         chrome.storage.local.set default_config, ( ) ->
            global.app.setup_failed = chrome.runtime.lastError?
            main( if global.app.setup_failed then null else default_config )
      else
         main( config )

create_data_url_scheme = ( rewrite ) ->
   data = "data:#{rewrite.mime_header}/#{rewrite.mime_body}"
   if rewrite.base64 then data += ";base64"
   data += ",#{rewrite.data}"
   data

chrome.runtime.onInstalled.addListener setup
chrome.runtime.onStartup.addListener setup

chrome.webRequest.onBeforeRequest.addListener ( detail ) ->

   if global.app.is_ready and not global.app.setup_failed and not global.app.config.disabled_all( )
      for rewrite in global.app.config.get_rewrites( )
         if not rewrite.disabled
            if rewrite.url_is_regex
               url_pattern = new RegExp rewrite.url
               return redirectUrl: create_data_url_scheme( rewrite ) if detail.url.match url_pattern
            else
               return redirectUrl: create_data_url_scheme( rewrite ) if detail.url is rewrite.url
      cancel: false
   else
      cancel: false

, urls: [ "*://*/*" ], [ "blocking" ]
