HidePath('/usr/share/zoneinfo/')
HidePath('/usr/share/ssl/')

utils = require "utils"

local function starts_with(str, start)
  return str:sub(1, #start) == start
end

function handle_404_fallback(api_url)
  local lang = GetParam('lang')
  local site_lang = GetParam('siteLanguage')

  if lang and site_lang then
    local url_same_lang = string.gsub(api_url, 'siteLanguage=' .. site_lang, 'siteLanguage=' .. lang)
    if utils.file_exists('/zip' .. url_same_lang) and ServeAsset(url_same_lang) then
      SetStatus(200)
      return
    end

    local url_no_site_lang = string.gsub(api_url, 'siteLanguage=' .. site_lang, '')
    if utils.file_exists('/zip' .. url_no_site_lang) and ServeAsset(url_no_site_lang) then
      SetStatus(200)
      return
    end
  end

  if lang and not site_lang then
    local url_added_sitelang = api_url .. '&siteLanguage=' .. lang
    if utils.file_exists('/zip' .. url_added_sitelang) and ServeAsset(url_added_sitelang) then
      SetStatus(200)
      return
    end

    -- try adding primary language TODO: find some better way
    local url_sitelang_en = api_url .. '&siteLanguage=en'
    if utils.file_exists('/zip' .. url_sitelang_en) and ServeAsset(url_sitelang_en) then
      SetStatus(200)
      return
    end
  end

  -- without any parameters
  if utils.file_exists('/zip' .. GetPath()) and ServeAsset(GetPath()) then
    SetStatus(200)
    return
  end

  -- if nothing helps...
  SetStatus(404)
  Write('{ "error": "Not found." }')
end

OnHttpRequest = function()
  -- Handle API calls
  -- the default handler strips of query parameters, but the static
  -- file names of the data we want to server have them included.
  local url = GetUrl()
  local api_url_start = string.find(url, "/api", 1, true) 
  if api_url_start then
    SetHeader('Content-Type', 'application/json')

    local api_url = string.sub(url, api_url_start) 

    if starts_with(api_url, '/api/search') then
      RoutePath('search.lua')
      return
    end

    if utils.file_exists('/zip' .. api_url) and ServeAsset(api_url) then
      SetStatus(200)
    else
      handle_404_fallback(api_url)
    end
  else
    if not ServeAsset(GetPath()) then
      -- automatical fallback to index.html for SPA routing
      ServeAsset('/index.html')
    else
      Route()
    end
  end
end
