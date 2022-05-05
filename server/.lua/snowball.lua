utils = require "utils"

__vowels = "aeiouy\xE4\xF6\xFC"
__s_ending = "bdfghklmnrt"
__st_ending = "bdfghklmnt"

-- __step1_suffixes = {"ern" = true, "em" = true, "er" = true, "en" = true, "es" = true, "e" = true, "s" = true}
-- __step2_suffixes = {"est" = true, "en" = true, "er" = true, "st" = true}
-- __step3_suffixes = {"isch" = true, "lich" = true, "heit" = true, "keit" = true, "end" = true, "ung" = true, "ig" = true, "ik" = true}

stopwords = utils.load_stopwords('german')

function get_range(word, start, stop)
  -- index starts at 0!
  if start == nil then
    return word
  end

  if stop == nil then
    stop = len(word)
  end

  if start < 0 then
    start = start + len(word)
  end

  if stop < 0 then
    stop = stop + len(word)
  end

  return string.sub(word, start + 1, stop) end

function get_char(word, i)
  return string.sub(word, i + 1, i + 1)
end

function has(needle, haystack)
  if type(haystack) == 'string' then
    return string.find(haystack, needle, 1, true) ~= nil
  end

  return false
end

function len(s) 
  return string.len(s)
end

function _r1r2_standard(word, vowels)
  local r1 = ""
  local r2 = ""

  for i=1,len(word)-1 do
    if not has(get_char(word, i), vowels) and has(get_char(word, i - 1), vowels) then
      r1 = get_range(word, i + 1)
      break
    end
  end

  for i=1,len(r1)-1 do
    if not has(get_char(r1, i), vowels) and has(get_char(r1, i - 1), vowels) then
      r2 = get_range(r1, i + 1)
      break
    end
  end

  return {r1, r2}
end

local function starts_with(str, start)
   return str:sub(1, #start) == start
end

local function ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
 end

function stem(word)
  -- https://www.nltk.org/_modules/nltk/stem/snowball.html#SnowballStemmer
  word = word:lower()
  word = word:gsub("\xDF", "ss")

  local n = len(word)
  for i=1,n-1 do
    if has(get_char(word, i - 1), __vowels) and has(get_char(word, i + 1), __vowels) then
      if get_char(word, i) == 'u' then
        word = get_range(word, 0, i) .. 'U' .. get_range(word, i + 1) 
      end

      if get_char(word, i) == 'y' then
        word = get_range(word, 0, i) .. 'Y' .. get_range(word, i + 1) 
      end
    end
  end

  r1, r2 = table.unpack(_r1r2_standard(word, __vowels))

  for i=1,n-1 do
    if not has(get_char(word, i), __vowels) and has(get_char(word, i - 1), __vowels) then
      local tmp = len(get_range(word, 0, i + 1))
      if 3 > tmp and tmp > 0 then
        r1 = get_range(word, 3)
      elseif len(get_range(word, 0, i + 1)) == 0 then
        return word
      end
      break
    end
  end
  
  -- STEP 1
  for suffix,_ in pairs(__step1_suffixes) do
      if ends_with(r1, suffix) then
        if (suffix == 'en' or suffix == 'es' or suffix == 'e') and get_range(word, - len(suffix) - 4, - len(suffix)) == 'niss' then
          word = get_range(word, 0, -len(suffix) - 1]
          r1 = get_range(r1, 0, -len(suffix) - 1)
          r2 = get_range(r2, 0, -len(suffix) - 1)
        elseif suffix == "s" then
            if word[-2] in self.__s_ending:
                word = word[:-1]
                r1 = r1[:-1]
                r2 = r2[:-1]
        else
            word = word[: -len(suffix)]
            r1 = r1[: -len(suffix)]
            r2 = r2[: -len(suffix)]
        break
      end
  end

  return word
end


print(stem('Feuer'))
print(get_range('abcd', -2))
