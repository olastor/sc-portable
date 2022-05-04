porter = require "porter"
lsqlite3 = require "lsqlite3"
json = require "json"
utils = require "utils"

local db = lsqlite3.open('example.db')

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function tokenize(sentence)
  return string.gmatch(sentence, '(%w+)')
end

function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

function load_stopwords(lang)
  file = 'stopwords/' .. lang
  if not file_exists(file) then return {} end
  local data = {}
  for line in io.lines(file) do 
    data[line] = true
  end
  return data
end

STOPWORDS = load_stopwords('english')
PUNCT_PATTERN = '[!"#$%%&\'()*+,-./:;<=>?@^_`{|}\\%[%]~—]'

function strip_punctuation(s)
  return s:gsub(PUNCT_PATTERN, '')
end

function process_query(query)
  local query_tokens = {}
  for word in tokenize(query) do
    word = porter:stem(strip_punctuation(word:lower()), 1, string.len(word))
    
    if STOPWORDS[word] ~= true then
      table.insert(query_tokens, word)
    end
  end
  return query_tokens
end

function search(query, language)
  local k1 = 2.0
  local b = 0.75

  local scores = {}
  local id_lookup = {}
  
  local query_tokens = process_query(query)

  local num_of_texts = 0
  for row in db:nrows('SELECT COUNT(DISTINCT text_id) as count FROM texts_meta WHERE language="' .. language .. '"') do
    num_of_texts = row.count
  end

  local avg_text_length = 0
  for row in db:nrows('SELECT AVG(length) as avg_length FROM texts_meta WHERE language="' .. language .. '"') do
    avg_text_length = row.avg_length
  end

  for _, word in ipairs(query_tokens) do
    for row in db:nrows('SELECT frequencies FROM search_index WHERE token="' .. word .. '"') do
      local frequencies = json.decode(row.frequencies)
      local num_of_matching_texts = 0

      for _, item in pairs(frequencies) do
        local text_lang = item[2]

        if text_lang == language then
          num_of_matching_texts = num_of_matching_texts + 1
        end
      end

      for _, item in pairs(frequencies) do
        local text_id = item[1]
        local text_author = item[2]
        local text_lang = item[3]
        local text_freq = item[4]

        if text_lang == language then
          local text_length = 0
          local text_filter = 'text_id="' .. text_id .. '" AND language="' .. text_lang .. '" AND author="' .. text_author .. '"'

          for row2 in db:nrows('SELECT SUM(length) as length FROM texts_meta WHERE ' .. text_filter) do
            text_length = row2.length
          end

          local idf = math.log(
            (num_of_texts - num_of_matching_texts + 0.5) /
            (num_of_matching_texts + 0.5)
          )

          local score = idf * (
            (text_freq * (k1 + 1)) /
            (text_freq + k1 * (1 - b + b * (text_length / avg_text_length)))
          )

          local full_id = text_id .. text_author .. text_lang
          if scores[full_id] == nil then
            scores[full_id] = 0
          end

          scores[full_id] = scores[full_id] + score
          id_lookup[full_id] = { text_id = text_id, author = text_author, language = text_lang }
        end
      end
    end
  end

  local score_array = {}
  for text_id, score in pairs(scores) do
    local text_info = id_lookup[text_id]
    text_info['score'] = score
    table.insert(score_array, text_info)
  end

  table.sort(score_array, function (a, b) return a.score > b.score end)

  return score_array
end

function findall (s, pattern) 
  local first, last = 0
  local indices = {}
  while true do
     first, last = string.find(s, pattern, first+1)
     if not first then break end
     table.insert(indices, first)
  end

  return indices
end

local function has_substr (tab, str)
  for _, substr in ipairs(tab) do
    if string.find(str, substr, 1, true) then
      return true
    end
  end

  return false
end

function strip_html_tags (str)
  return str:gsub('(<[^>]*>)', '')
end

function highlight (query, text, collection)
  local result = nil
  
  text = strip_html_tags(text)

  local tokens = {}
  local word_bounds = findall(text, '([%s' .. PUNCT_PATTERN:sub(2, PUNCT_PATTERN:len()) .. ')')
  for i, char_index in ipairs(word_bounds) do
    if i == 1 then
      table.insert(tokens, string.sub(text, 1, char_index - 1))
    else
      table.insert(tokens, string.sub(text, word_bounds[i - 1] + 1, char_index - 1))
    end

    table.insert(tokens, string.sub(text, char_index, char_index))
  end

  local query_tokens = process_query(query)

  local excerpt = ''
  local window_size = 15
  local tokensLength = tablelength(tokens)
  local displayData = {}

  for i, token in ipairs(tokens) do
    if string.len(token) > 1 then
      token = porter:stem(token:lower(), 1, string.len(token))
      token = strip_punctuation(token)
      if has_substr(query_tokens, token) then
        displayData[i] = true

        for j=math.max(1, i - window_size),math.min(tokensLength, i + window_size),1 do
          if displayData[j] ~= true then
            displayData[j] = false
          end
        end
      end
    end
  end

  local display_data_sorted = {}
  for i, val in pairs(displayData) do
    table.insert(display_data_sorted, { pos = i, highlight = val })
  end

  table.sort(display_data_sorted, function (a, b) return a.pos < b.pos end)

  local last_index = 0

  local current_window = ''
  for _, item in ipairs(display_data_sorted) do
    if item.pos ~= (last_index + 1) and string.len(current_window) > 0 then
      table.insert(collection, current_window)
      current_window = ''
    end

    if item.highlight then
      current_window = current_window .. '<b>' .. tokens[item.pos] .. '</b>'
    else
      current_window = current_window .. tokens[item.pos]
    end

    last_index = item.pos
  end

  if string.len(current_window) > 0 then
    table.insert(collection, current_window)
  end
end

function get_highlights(text_id, query, language, author)
  local highlights = {}
  local found_text = false

  local file_bilara = '/zip/api/bilarasuttas/' .. text_id .. '/' .. author .. '?lang=' .. language .. '&siteLanguage=' .. language
  if file_exists(file_bilara) then
    local bilara_data = json.decode(utils.read_file(file_bilara))
    if bilara_data['translation_text'] then
      found_text = true
      for _, paragraph in pairs(bilara_data['translation_text']) do
        highlight(query, paragraph, highlights)
      end
    end
  end

  if not found_text then
    local file_sutta = '/zip/api/suttas/' .. text_id .. '/' .. author .. '?lang=' .. language .. '&siteLanguage=' .. language
    if file_exists(file_sutta) then
      local sutta_data = json.decode(utils.read_file(file_sutta))
      if sutta_data['root_text'] and sutta_data['root_text']['text'] then
        highlight(query, sutta_data['root_text']['text'], highlights)
      end
    end
  end

  return highlights
end

function get_languages() 
  languages = {}
  for row in db:nrows('SELECT DISTINCT(language) FROM texts_meta') do
    table.insert(languages, row.languages)
  end
  return languages
end

local query = GetParam('query')
local language = GetParam('language')
local limit = GetParam('limit')
local offset = GetParam('offset')

if limit then
  limit = tonumber(limit)
else
  limit = 50
end

if offset then
  offset = tonumber(offset)
else
  offset = 0
end

local total = 0
local count = 0
local hits = {}
for i, item in ipairs(search(query, language)) do
  if i > offset and count < limit then
    local hit = {
      acronym = item['text_id'],
      uid = item['text_id'],
      lang = item['language'],
      author = item['author'],
      author_short = item['author'],
      heading = {
        division = "",
        subhead = {},
        title = ""
      },
      is_root = false,
      highlight = {
        content = get_highlights(item['text_id'], query, item['language'], item['author'])
      },
      url = '/' .. item['text_id'] .. '/' .. item['language'] .. '/' .. item['author']
    }    

    table.insert(hits, hit)
    count = count + 1
  end

  total = total + 1
end

local results = {
  total = total,
  hits = hits
}

Write(json.encode(results))

