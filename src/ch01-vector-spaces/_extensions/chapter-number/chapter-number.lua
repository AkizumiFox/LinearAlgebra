-- chapter-number.lua
-- Automatically sets the chapter counter based on 'chapter-number' metadata
-- Usage: Add 'chapter-number: 3' to your YAML front matter

function Meta(meta)
  if meta['chapter-number'] then
    local ch_num = tonumber(pandoc.utils.stringify(meta['chapter-number']))
    local sec_num = meta['section-number'] and tonumber(pandoc.utils.stringify(meta['section-number']))
    
    if ch_num and FORMAT:match('latex') then
      local latex_cmd
      
      if sec_num then
        -- Composite numbering: Chapter.Section
        -- \renewcommand{\thechapter}{Ch.Sec}
        -- \setcounter{chapter}{Ch}
        -- Note: We set counter to ch_num because we want the PDF to be treated as that chapter
        -- but with a custom display label.
        latex_cmd = string.format(
          "\\renewcommand{\\thechapter}{%d.%d}\\setcounter{chapter}{%d}", 
          ch_num, sec_num, ch_num
        )
      else
        -- Standard chapter only numbering
        -- Set chapter counter to N-1 so the next \chapter command produces N
        latex_cmd = string.format("\\setcounter{chapter}{%d}", ch_num - 1)
      end
      
      -- Insert at the beginning of the document
      return meta, {
        pandoc.RawBlock('latex', latex_cmd)
      }
    end
  end
  return meta
end

function Pandoc(doc)
  local meta = doc.meta
  if meta['chapter-number'] then
    local ch_num = tonumber(pandoc.utils.stringify(meta['chapter-number']))
    local sec_num = meta['section-number'] and tonumber(pandoc.utils.stringify(meta['section-number']))
    
    if ch_num and FORMAT:match('latex') then
      local latex_cmd
      
      if sec_num then
        latex_cmd = string.format(
          "\\renewcommand{\\thechapter}{%d.%d}\\setcounter{chapter}{%d}", 
          ch_num, sec_num, ch_num
        )
      else
        latex_cmd = string.format("\\setcounter{chapter}{%d}", ch_num - 1)
      end
      
      table.insert(doc.blocks, 1, pandoc.RawBlock('latex', latex_cmd))
    end
  end
  return doc
end
