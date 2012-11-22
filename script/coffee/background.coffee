
global = @
global.app =
   is_ready       : false
   setup_failed   : false
   config         : null

main = ( ) ->
   global.app.config = new global.config ( success ) ->
      console.log @
      global.app.setup_failed = not success
      global.app.is_ready     = true

create_data_url_scheme = ( rewrite ) ->
   data = "data:#{rewrite.mime_header}/#{rewrite.mime_body}"
   if rewrite.base64 then data += ";base64"
   data += "," + global.app.config.get_data rewrite.id
   data

chrome.runtime.onInstalled.addListener main
chrome.runtime.onStartup.addListener main

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
