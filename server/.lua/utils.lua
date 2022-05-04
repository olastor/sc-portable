local utils = {}

function utils.template(markup, replacements)
  local result = markup
  for key, value in pairs(replacements) do
    result = string.gsub(result, string.format('{{%s}}', key), value)
  end

  return result
end

function utils.get_sql_filter(language, author)
  filter = ''
  if language then
    filter = filter .. ' AND language="' .. language .. '"'
  end

  if author then
    filter = filter .. ' AND author="' .. author .. '"'
  end

  return filter
end

function utils.read_file(file)
  local f = assert(io.open(file, "rb"))
  local content = f:read("*all")
  f:close()
  return content
end

return utils
