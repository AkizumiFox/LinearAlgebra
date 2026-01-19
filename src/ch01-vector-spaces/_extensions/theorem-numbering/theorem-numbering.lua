-- theorem-numbering.lua
function Pandoc(doc)
  local meta = doc.meta
  local ch_num = meta['chapter-number'] and tonumber(pandoc.utils.stringify(meta['chapter-number']))
  local sec_num = meta['section-number'] and tonumber(pandoc.utils.stringify(meta['section-number']))
  
  if FORMAT:match('latex') then
    local setup = ""
    if ch_num ~= nil and sec_num ~= nil then
      -- Section file - Robust format enforcement
      setup = string.format([[
\makeatletter
\AtBeginDocument{
  \def\thestandalone{}
  \setcounter{part}{%d}
  \setcounter{chapter}{%d}
  \providecommand{\thetheorem}{}
  \renewcommand{\thetheorem}{%d.%d.\arabic{theorem}}
  \providecommand{\thedefinition}{}
  \renewcommand{\thedefinition}{%d.%d.\arabic{definition}}
}
\makeatother
]], ch_num, sec_num, ch_num, sec_num, ch_num, sec_num)
    elseif ch_num ~= nil then
      setup = string.format([[\setcounter{part}{%d}]], ch_num)
    end
    
    if setup ~= "" then
      if not meta['header-includes'] then
        meta['header-includes'] = pandoc.MetaList({})
      end
      table.insert(meta['header-includes'], pandoc.RawBlock('latex', setup))
    end
  end
  return doc
end

return {{Pandoc = Pandoc}}
