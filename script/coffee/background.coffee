
global = @
global.app =
   is_ready       : false
   setup_failed   : false
   config         : null

main = ( config, data ) ->
   if not global.app.setup_failed
      global.app.config = new global.config config.app, data

   global.app.is_ready = true

setup = ( ) ->
   chrome.storage.local.get [ "version", "app" ], ( config ) ->

      if chrome.runtime.lastError?
         global.app.setup_failed = true
         main( )
         return

      version = chrome.runtime.getManifest( ).version

      # 設定データに書き込まれているバージョンが違う場合
      if config.version? and config.version isnt version
         main( )

      # 設定データが見つからない場合
      else if not config.version?
         default_config = 
            version  : version
            app      :
               disabled_all   : false
               rewrite        : [ ]
         chrome.storage.local.set default_config, ( ) ->
            global.app.setup_failed = chrome.runtime.lastError?
            main ( if global.app.setup_failed then null else default_config ), { }

      # 設定データが存在する場合
      else
         id_array = ( rewrite.id for rewrite in config.app.rewrite )
         data     = { }
         if id_array.length is 0
            main config, data
         else
            id = id_array.shift( )
            property = "data_#{id}"
            chrome.storage.local.get property, ( got ) ->
               if chrome.runtime.lastError?
                  global.app.setup_failed = true
                  main( )
               else
                  data[ property ] = got[ property ]
                  if ( id = id_array.shift( ) )?
                     property = "data_#{id}"
                     chrome.storage.local.get property, arguments.callee
                  else
                     main config, data


create_data_url_scheme = ( rewrite ) ->
   data = "data:#{rewrite.mime_header}/#{rewrite.mime_body}"
   if rewrite.base64 then data += ";base64"
   data += "," + global.app.config.get_data rewrite.id
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
