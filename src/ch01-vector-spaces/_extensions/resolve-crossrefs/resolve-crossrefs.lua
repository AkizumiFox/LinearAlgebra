-- resolve-crossrefs.lua
-- Replaces broken cross-references (e.g. ?@thm-id) with static numbers from theorem-map.json

local theorem_map = nil

-- Helper to load the map file
local function load_map(file_path)
  local f = io.open(file_path, "r")
  if not f then return nil end
  local content = f:read("*all")
  f:close()
  return pandoc.json.decode(content)
end

function Pandoc(doc)
  local meta = doc.meta
  
  -- Only run if we are in standalone-pdf mode
  -- Use stringify to safely check the value
  local is_standalone = meta['standalone-pdf'] and pandoc.utils.stringify(meta['standalone-pdf']) == 'true'
  
  if is_standalone then
    -- Try to load the map from various locations
    local candidates = {
      "_book/theorem-map.json",
      "../_book/theorem-map.json",
      "../../_book/theorem-map.json"
    }
    
    for _, path in ipairs(candidates) do
      theorem_map = load_map(path)
      if theorem_map then break end
    end
    
    if not theorem_map then
      -- Fallback to PWD env var
      local project_dir = os.getenv("PWD")
      if project_dir then
         theorem_map = load_map(project_dir .. "/_book/theorem-map.json")
      end
    end
    
    if theorem_map then
      local filtered_div = pandoc.walk_block(pandoc.Div(doc.blocks), {
        -- Handle broken refs that Quarto turned into Strong > Str "?@..."
        Strong = function(el)
          if #el.content == 1 and el.content[1].t == 'Str' then
             local text = el.content[1].text
             if text:match("^%?@") then
               local id = text:sub(3) -- remove "?@"
               if theorem_map[id] then
                 return pandoc.Str(theorem_map[id])
               end
             end
          end
          return nil
        end,
        
        -- Handle raw Cite objects if they haven't been processed yet
        Cite = function(el)
          for _, citation in ipairs(el.citations) do
             local id = citation.id
             if theorem_map[id] then
                -- Replace the entire citation with the number
                return pandoc.Str(theorem_map[id])
             end
          end
          return nil
        end
      })
      doc.blocks = filtered_div.content
    end
  end
  return doc
end
