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
  print("[resolve-crossrefs] Starting...")
  local meta = doc.meta
  
  -- Only run if we are in standalone-pdf mode
  -- Use stringify to safely check the value
  local is_standalone = meta['standalone-pdf'] and pandoc.utils.stringify(meta['standalone-pdf']) == 'true'
  
  if is_standalone then
    -- Search for map file in common locations
    -- In the temporary build environment, we might be deep in src/chXX
    local paths_to_try = {
      "_book/theorem-map.json",
      "../_book/theorem-map.json",
      "../../_book/theorem-map.json",
      "../../../_book/theorem-map.json",
      "../../../../_book/theorem-map.json"
    }
    
    -- Also try relative to PWD via shell if needed
    local handle = io.popen("pwd")
    local pwd = handle:read("*a"):gsub("%s+", "")
    handle:close()
    
    if pwd then
      table.insert(paths_to_try, pwd .. "/_book/theorem-map.json")
      table.insert(paths_to_try, pwd .. "/../_book/theorem-map.json")
      table.insert(paths_to_try, pwd .. "/../../_book/theorem-map.json")
    end

    for _, path in ipairs(paths_to_try) do
      local f = io.open(path, "r")
      if f then
        local content = f:read("*all")
        f:close()
        -- Use pandoc.json for compatibility
        theorem_map = pandoc.json.decode(content) 
        if theorem_map then
        end
        break
      else
      end
    end
    
    if not theorem_map then 
    end
    
    if theorem_map then
      -- Helper to get label from ID (e.g., "thm-..." -> "Theorem")
      local function get_label(id)
        local prefix = id:match("^([a-z]+)-")
        if not prefix then return "" end
        
        local labels = {
          thm = "Theorem",
          lem = "Lemma",
          def = "Definition",
          cor = "Corollary",
          prp = "Proposition",
          exm = "Example",
          exr = "Exercise",
          cnj = "Conjecture",
          alg = "Algorithm"
        }
        
        return labels[prefix] or ""
      end

      local filtered_div = pandoc.walk_block(pandoc.Div(doc.blocks), {
        -- Handle broken refs that Quarto turned into Strong > Str "?@..."
        Strong = function(el)
          -- Log AST elements to verify structure
          -- io.stderr:write("DEBUG: Found Strong element\n")
          if #el.content == 1 and el.content[1].t == 'Str' then
             local text = el.content[1].text
             if text:match("^%?@") then
               local id = text:sub(3) -- remove "?@"
               if theorem_map[id] then
                 local label = get_label(id)
                 local ref_text = label == "" and theorem_map[id] or (label .. " " .. theorem_map[id])
                 return pandoc.Str(ref_text)
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
               local label = get_label(id)
               local ref_text = label == "" and theorem_map[id] or (label .. " " .. theorem_map[id])
               -- Replace the entire citation with the text (no bold)
               return pandoc.Str(ref_text)
             end
          end
          return nil
        end
      })
      
      -- Replace specific blocks if they contain refs
      doc.blocks = filtered_div.content
    end
  end
  return doc
end
