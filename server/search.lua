lsqlite3 = require "lsqlite3"
json = require "json"
utils = require "utils"

HL_TAG_OPEN = '<strong class="highlight">'
HL_TAG_CLOSE = '</strong>'
HL_MAX_TOKENS = 64

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
      content = {item['hl']}
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

