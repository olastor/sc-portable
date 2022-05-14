lsqlite3 = require "lsqlite3"
json = require "json"
utils = require "utils"

DB_PATH = 'search.db'
HL_TAG_OPEN = '<strong class="highlight">'
HL_TAG_CLOSE = '</strong>'
HL_WINDOW_SIZE = 20
HL_MIN_GAP = 10

-- TODO: add more later
STOP_LANGUAGES = {
  en = "english",
  de = "german"
}

function remove_stopwords(text, language) 
  if not STOP_LANGUAGES[language] then
    return text
  end

  stop_file = utils.read_file('/zip/stopwords/' .. STOP_LANGUAGES[language])

  text = text:lower()

  for word in stop_file:gsub('\n$', ''):gmatch('[^\n]+') do
    text = text:gsub('%s' .. word .. '%s', ' ')
    text = text:gsub('%s' .. word .. '$', ' ')
    text = text:gsub('^' .. word .. '%s', ' ')
    text = text:gsub('^' .. word .. '$', ' ')
  end

  return text
end

function get_meta(text_id, author, language)
  local meta = {
    acronym = text_id,
    author = author,
    is_root = false,
    heading = {
      division = "",
      subhead = {},
      title = ""
    }
  }

  local info_file = string.format(
    '/zip/api/suttaplex/%s?language=%s',
    text_id, language
  )

  if utils.file_exists(info_file) then
    data = json.decode(utils.read_file(info_file))
    
    for _, info in ipairs(data) do
      meta['acronym'] = info['acronym']
      meta['heading']['title'] = info['translated_title']

      for _, item in ipairs(info['translations']) do
        if item['author_uid'] == 'author' and item['lang'] == language then
          meta['is_root'] = item['is_root']
          meta['author'] = item['author']
          break
        end
      end

      -- structure like [ { ...data } ]
      break
    end
  end

  return meta
end

function trim_highlights(highlighted_text, max_window_size, min_gap_size)
  local results_set = {}
  local results = {}

  highlighted_text = string.gsub(highlighted_text, '\n', ' ')

  local trim_pattern = '>('
  for i=0,max_window_size do
    trim_pattern = trim_pattern .. '[^<]'
  end
  trim_pattern = trim_pattern .. ')'

  for i=0,min_gap_size do
    trim_pattern = trim_pattern .. '[^<]'
  end
  trim_pattern = trim_pattern .. '+('

  for i=0,max_window_size do
    trim_pattern = trim_pattern .. '[^<]'
  end
  trim_pattern = trim_pattern .. ')'

  text_trimmed = string.gsub('>' .. highlighted_text .. '<', trim_pattern, '>%1\n%2')
  for item in string.gmatch(text_trimmed, '[^\n]+') do
    results_set[item] = true
  end

  for item,_ in pairs(results_set) do
    table.insert(results, item)
  end

  table.remove(results, #results)
  table.remove(results, 1)

  return results
end

local language = GetParam('language')
local restrict = GetParam('restrict')

if restrict == 'root-texts' then
  language = 'pli'
end

local query = remove_stopwords(GetParam('query'), language)
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

local total = limit
local count = 0
local hits = {}

local db = lsqlite3.open(DB_PATH)
local table_name = 'text_search_' .. language
local sql_query_search = string.format(
  "SELECT text_id, author, highlight(%s, 2, '%s', '%s') AS hl FROM %s WHERE text MATCH ? ORDER BY bm25(%s) LIMIT ? OFFSET ?;",
  table_name, HL_TAG_OPEN, HL_TAG_CLOSE, table_name, table_name
)
local sql_query_total = string.format(
  "SELECT COUNT(*) FROM %s WHERE text MATCH ? ORDER BY bm25(%s);",
  table_name, table_name
)

local stmt_total = db:prepare(sql_query_total)
stmt_total:bind_values(query)
for count in stmt_total:urows(sql_query_total) do
  total = count
  break
end

local stmt = db:prepare(sql_query_search)
stmt:bind_values(query, limit, offset)
for item in stmt:nrows() do
  local meta = get_meta(item['text_id'], item['author'], language)
  local hit = {
    acronym = meta['acronym'],
    uid = item['text_id'],
    lang = item['language'],
    author = meta['author'],
    author_short = item['author'],
    heading = meta['heading'],
    is_root = meta['is_root'],
    highlight = {
      content = trim_highlights(item['hl'], HL_WINDOW_SIZE, HL_MIN_GAP)
    },
    url = '/' .. item['text_id'] .. '/' .. language .. '/' .. item['author']
  }    
  table.insert(hits, hit)
end

local results = {
  total = total,
  hits = hits
}


SetHeader('Content-Type', 'application/json')
Write(json.encode(results))

