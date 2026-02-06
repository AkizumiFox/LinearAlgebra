-- claim-env.lua: Handle .claim divs for both HTML and LaTeX
-- Converts ::: {.claim} divs to properly styled environments

function Div(el)
  if not el.classes:includes('claim') then
    return nil
  end

  -- Extract optional title from attributes
  local title = el.attr.attributes['title'] or ''

  if FORMAT:match('latex') then
    -- LaTeX: wrap content in claim environment
    local new_content = pandoc.List()
    
    if title ~= '' then
      new_content:insert(pandoc.RawBlock('tex', '\\begin{claim}[' .. title .. ']'))
    else
      new_content:insert(pandoc.RawBlock('tex', '\\begin{claim}'))
    end
    
    for _, block in ipairs(el.content) do
      new_content:insert(block)
    end
    
    new_content:insert(pandoc.RawBlock('tex', '\\end{claim}'))
    
    return new_content
  end

  if FORMAT:match('html') then
    -- HTML: Prepend proof-title span to the first paragraph (inline)
    local title_text = 'Claim'
    if title ~= '' then
      title_text = 'Claim (' .. title .. ')'
    end
    
    local title_span = pandoc.RawInline('html', '<span class="proof-title"><em>' .. title_text .. '</em>.</span> ')
    
    -- Find the first Para or Plain block and prepend the title
    for i, block in ipairs(el.content) do
      if block.t == 'Para' or block.t == 'Plain' then
        -- Prepend title to the first inline element
        table.insert(block.content, 1, title_span)
        break
      end
    end
    
    return el
  end
end
