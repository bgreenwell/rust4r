-- Keep a short table with the heading and lead-in paragraph above it (PDF).
--
-- LaTeX will end a page between a heading, or the sentence that introduces a
-- table, and the table itself, which strands "Summary" at the bottom of a page
-- with its table on the next. Before each table, find where its run starts
-- (the lead-in paragraph, and the heading before that, if any) and put a
-- \needspace there, sized to the table, so the run moves to the next page as
-- a whole when it doesn't fit. Long tables still break across pages; the
-- reserved space is capped.

if not FORMAT:match("latex") then
  return {}
end

local CAP = 24

-- Rough height in lines: table cells in narrow columns often wrap, so count
-- two lines per row
local function table_lines(tbl)
  local rows = #tbl.head.rows
  for _, body in ipairs(tbl.bodies) do
    rows = rows + #body.body
  end
  return 2 * rows + 2
end

function Blocks(blocks)
  local starts = {}
  for i, block in ipairs(blocks) do
    if block.t == "Table" then
      local lines = table_lines(block)
      local s = i
      if s > 1 and blocks[s - 1].t == "Para" then
        s = s - 1
        lines = lines + 3
      end
      if s > 1 and blocks[s - 1].t == "Header" then
        s = s - 1
        lines = lines + 3
      end
      starts[s] = math.min(lines, CAP)
    end
  end
  if next(starts) == nil then
    return nil
  end

  local out = pandoc.Blocks({})
  for i, block in ipairs(blocks) do
    if starts[i] then
      out:insert(pandoc.RawBlock("latex",
        string.format("\\needspace{%d\\baselineskip}", starts[i])))
    end
    out:insert(block)
  end
  return out
end
