lsqlite3 = require "lsqlite3"
json = require "json"
utils = require "utils"

HL_TAG_OPEN = '<strong class="highlight">'
HL_TAG_CLOSE = '</strong>'
HL_MAX_TOKENS = 64

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

local total = limit
local count = 0
local hits = {}

local db = lsqlite3.open('example.db')
local table_name = 'text_search_' .. language
local sql_query_search = string.format(
  "SELECT text_id, author, snippet(%s, 2, '%s', '%s', '', '%i') AS hl FROM %s WHERE text MATCH ? ORDER BY bm25(%s) LIMIT ? OFFSET ?;",
  table_name, HL_TAG_OPEN, HL_TAG_CLOSE, HL_MAX_TOKENS, table_name, table_name
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
      content = {item['hl']} -- TODO: maybe use sql highlight() and split manually, this makes one big chunk
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

