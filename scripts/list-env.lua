-- list-env.lua: Convert Divs with a list into a single LaTeX environment
-- Also adds helpful classes for HTML styling
function Div(el)
  -- Check if the Div has a class that we want to treat as a list environment
  local env = nil
  if el.classes:includes('enumerate') then
    env = 'enumerate'
  elseif el.classes:includes('itemize') then
    env = 'itemize'
  end

  if not env then return nil end

  local options = el.attr.attributes['options']

  -- HTML: Add specific classes based on options for CSS styling
  if FORMAT:match('html') then
    if options then
      if options:match('label=%(F') then
        el.classes:insert('enumerate-f')
      elseif options:match('label=%(VS') then
        el.classes:insert('enumerate-vs')
      elseif options:match('label=%(LT') then
        el.classes:insert('enumerate-lt')
      end
    end
    return el
  end

  -- LaTeX: Convert to raw LaTeX environment to avoid nesting
  if FORMAT:match('latex') then
    local new_content = pandoc.List()
    
    for _, block in ipairs(el.content) do
      if block.t == 'OrderedList' or block.t == 'BulletList' then
        local items = (block.t == 'OrderedList') and block.list or block.content
        
        local beginTex = '\\begin{' .. env .. '}'
        if options then
          beginTex = beginTex .. '[' .. options .. ']'
        end
        new_content:insert(pandoc.RawBlock('tex', beginTex))
        
        for _, item in ipairs(items) do
          new_content:insert(pandoc.RawBlock('tex', '\\item'))
          for _, itemBlock in ipairs(item) do
            new_content:insert(itemBlock)
          end
        end
        
        new_content:insert(pandoc.RawBlock('tex', '\\end{' .. env .. '}'))
      else
        new_content:insert(block)
      end
    end
    -- We return a Div but its content is now raw TeX for the list
    return pandoc.Div(new_content)
  end
end
