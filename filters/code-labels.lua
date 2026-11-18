-- One labeled code block per chunk.
--
-- _common.R labels every displayed R and Rust chunk with its language
-- (Quarto's `filename` option). Two things get in the way of that label:
--
-- * knitr splits an R chunk's source after every expression that prints, so
--   the chunk comes out as several code blocks with output in between, and
--   only the first block gets the label. Merge the pieces into one block and
--   keep the output after it, in its original order, joining neighboring
--   output blocks of the same kind (stdout, stderr). Rust chunks already
--   look like this.
-- * In LaTeX, Quarto turns a filename into a numbered `codelisting` float
--   ("Listing 4.1") that can't break across pages. Replace it with a plain
--   \codelabel{} line (defined in _quarto.yml). HTML keeps Quarto's
--   filename header. The same goes for plain code blocks that carry a
--   filename, such as {.bash filename="Terminal"} or {.toml
--   filename="Cargo.toml"}.

local latex = FORMAT:match("latex") ~= nil

-- Chunks up to this many lines, code and output together, are kept on one page
local MAX_KEEP = 25
-- In longer chunks, output blocks up to this many lines are kept in one piece
local MAX_OUTPUT = 20

local function label(name)
  return pandoc.Plain({
    pandoc.RawInline("latex", "\\codelabel{"),
    pandoc.Str(name),
    pandoc.RawInline("latex", "}"),
  })
end

function CodeBlock(block)
  local name = block.attributes.filename
  if not latex or name == nil then
    return nil
  end
  block.attributes.filename = nil
  return { label(name), block }
end

local function is_source(block)
  return block.t == "CodeBlock" and block.classes:includes("cell-code")
end

-- A text output block: a .cell-output div holding a single code block
local function text_output(block)
  if block.t == "Div" and block.classes:includes("cell-output")
      and #block.content == 1 and block.content[1].t == "CodeBlock" then
    return block.content[1]
  end
end

function Div(div)
  if not div.classes:includes("cell") then
    return nil
  end

  local blocks = pandoc.Blocks({})
  local code, at = nil, nil
  for _, block in ipairs(div.content) do
    local out = text_output(block)
    local prev = blocks[#blocks]
    if not is_source(block) then
      if out and prev and text_output(prev)
          and table.concat(prev.classes, " ") == table.concat(block.classes, " ") then
        local joined = text_output(prev)
        joined.text = joined.text .. "\n" .. out.text
      else
        blocks:insert(block)
      end
    elseif code then
      code.text = code.text .. "\n" .. block.text
    else
      code = block
      blocks:insert(block)
      at = #blocks
    end
  end
  div.content = blocks

  local name = div.attributes.filename
  if latex and code and name then
    div.attributes.filename = nil
    div.content:insert(at, label(name))
    -- Keep a short chunk, its code and output together, on one page: reserve
    -- room for all of it, so it moves to the next page whole instead of
    -- splitting. Longer chunks break as usual.
    local lines = 1
    for _, block in ipairs(blocks) do
      local text = block.t == "CodeBlock" and block.text
        or (text_output(block) and text_output(block).text)
      if text then
        local _, newlines = text:gsub("\n", "")
        lines = lines + newlines + 2
      end
    end
    if lines <= MAX_KEEP then
      div.content:insert(at, pandoc.RawBlock("latex",
        string.format("\\needspace{%d\\baselineskip}", lines)))
      -- Record the lines kept together, for the lead-in rule in Blocks().
      -- \codelabel itself asks for 8, so never record fewer.
      div.attributes["keep-lines"] = tostring(math.max(lines, 8))
    else
      -- Only the label and the 8 lines \codelabel asks for stay together
      div.attributes["keep-lines"] = "8"
      -- Too long to keep whole: keep each short output block, such as a
      -- compiler message, in one piece instead
      local kept = pandoc.Blocks({})
      for _, block in ipairs(div.content) do
        local out = text_output(block)
        if out then
          local _, newlines = out.text:gsub("\n", "")
          if newlines + 2 <= MAX_OUTPUT then
            kept:insert(pandoc.RawBlock("latex",
              string.format("\\needspace{%d\\baselineskip}", newlines + 2)))
          end
        end
        kept:insert(block)
      end
      div.content = kept
    end
  end
  return div
end

-- Keep a short lead-in ("... and the compiler objects:") with the chunk it
-- introduces (PDF). The \needspace above only keeps the chunk together, so
-- LaTeX can still end a page between the lead-in and the chunk. When a short
-- paragraph ending in a colon comes right before a chunk, reserve room for
-- the paragraph, the heading before it if any, and the chunk's kept lines,
-- so they move to the next page as a unit. Longer lead-ins are left alone:
-- moving them would leave a large gap.
local CHARS_PER_LINE = 90
local MAX_LEAD = 4

local function lead_in_lines(block)
  if block == nil or block.t ~= "Para" then
    return nil
  end
  local text = pandoc.utils.stringify(block)
  if not text:match(":%s*$") then
    return nil
  end
  local lines = math.ceil((utf8.len(text) or #text) / CHARS_PER_LINE)
  if lines > MAX_LEAD then
    return nil
  end
  -- One line for the paragraph break and one for the space \codelabel adds
  return lines + 2
end

-- Lines a block keeps together: a chunk's count from Div(), or the label and
-- first lines of a plain code block such as {.bash filename="Terminal"}
local function kept_lines(block)
  if block.t == "Div" and block.classes:includes("cell") then
    local n = tonumber(block.attributes["keep-lines"])
    block.attributes["keep-lines"] = nil
    return n
  end
  if block.t == "Plain" and block.content[1]
      and block.content[1].t == "RawInline"
      and block.content[1].text == "\\codelabel{" then
    return 8
  end
end

function Blocks(blocks)
  if not latex then
    return nil
  end
  local out = pandoc.Blocks({})
  for _, block in ipairs(blocks) do
    local n = kept_lines(block)
    local lead = n and lead_in_lines(out[#out])
    if lead then
      local at = #out
      if at > 1 and out[at - 1].t == "Header" then
        at = at - 1
        lead = lead + 3
      end
      out:insert(at, pandoc.RawBlock("latex",
        string.format("\\needspace{%d\\baselineskip}", lead + n)))
    end
    out:insert(block)
  end
  return out
end
