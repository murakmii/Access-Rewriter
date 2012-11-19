
global = @

class config 

   _create_id: ( ) ->
      id = Math.floor ( Math.random( ) * 1000000 )
      while @_get_rewrite( id ) isnt null
         id = Math.floor ( Math.random( ) * 1000000 )
      id

   _get_rewrite: ( id ) -> 
      if ( index = @_get_rewrite_index id ) isnt -1 then return @_config.rewrite[ index ] else null
      
   _get_rewrite_index: ( id ) ->
      for rewrite, i in @_config.rewrite
         return i if rewrite.id is id
      -1

   constructor: ( @_config ) ->

   # データを除いた設定を返す
   get_rewrite: ( id ) -> @_get_rewrite id
   get_rewrites: ( ) -> @_config.rewrite

   read_data: ( id, callback ) ->
      chrome.storage.local.get "data_#{id}", ( got ) =>
         if chrome.runtime.lastError?
            callback.call @, false, null
         else
            callback.call @, true, got[ "data_#{id}" ]

   add: ( title, url, url_is_regex, mime_header, mime_body, base64, data, callback ) ->

      valid_mime = /^[a-zA-Z\.\-]+$/
      if not mime_header.match valid_mime or not mime_body.match valid_mime
         callback.call @, false, null

      id = @_create_id( )
      @_config.rewrite.push
         id          : id
         title       : title
         url         : url
         url_is_regex: url_is_regex
         mime_header : mime_header,
         mime_body   : mime_body
         base64      : base64
         data        : data
         disabled    : false

      chrome.storage.local.set app: @_config, ( ) =>
         if chrome.runtime.lastError?
            @_config.rewrite.pop( )
            callback.call @, false, null
         else
            callback.call @, true, @_config.rewrite[ @_config.rewrite.length - 1 ]

   remove: ( id, callback ) ->
      callback.call @, false, null if ( index = @_get_rewrite_index id ) is -1

      removed = @_config.rewrite[ index ]
      @_config.rewrite.splice index, 1

      chrome.storage.local.set app: @_config, ( ) =>
         if chrome.runtime.lastError?
            @_config.rewrite.splice index, 0, removed
            callback.call @, false, null
         else
            callback.call @, true, removed

   override: ( id, title, url, url_is_regex, mime_header, mime_body, base64, data, callback ) ->
      callback.call @, false, null if ( index = @_get_rewrite_index parseInt ( id ) ) is -1
    
      backup = @_config.rewrite[ index ]
      @_config.rewrite[ index ] =
         id          : backup.id
         title       : title
         url         : url
         url_is_regex: url_is_regex
         mime_header : mime_header
         mime_body   : mime_body
         base64      : base64
         data        : data
         disabled    : backup.disabled

      chrome.storage.local.set app: @_config, ( ) =>
         if chrome.runtime.lastError?
            @_config.rewrite[ index ] = backup
            callback.call @, false, null
         else
            callback.call @, true, @_config.rewrite[ index ]

   disabled_all: ( ) -> @_config.disabled_all
   set_disabled_all: ( boolean, callback ) ->
      @_config.disabled_all = boolean
      chrome.storage.local.set app: @_config, ( ) =>
         if chrome.runtime.lastError?
            callback.call @, false
         else
            callback.call @, true

   disabled: ( id, boolean, callback ) ->
      if ( index = @_get_rewrite_index id ) is null then callback.call @, false, null
      backup = @_config.rewrite[ index ].disabled
      @_config.rewrite[ index ].disabled = boolean
      chrome.storage.local.set app: @_config, ( ) =>
         if chrome.runtime.lastError?
            @_config.rewrite[ index ].disabled = backup
            callback.call @, false, @_config.rewrite[ index ]
         else
            callback.call @, true, @_config.rewrite[ index ]


global.config = config














      