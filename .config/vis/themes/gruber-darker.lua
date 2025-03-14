local lexers = vis.lexers

local gruber_darker = {
  ["fg"]        =        "#e4e4ef",
  ["fg+1"]      =        "#f4f4ff",
  ["fg+2"]      =        "#f5f5f5",
  ["white"]     =        "#ffffff",
  ["black"]     =        "#000000",
  ["bg-1"]      =        "#101010",
  ["bg"]        =        "#181818",
  ["bg+1"]      =        "#282828",
  ["bg+2"]      =        "#453d41",
  ["bg+3"]      =        "#484848",
  ["bg+4"]      =        "#52494e",
  ["red-2"]     =        "#9a3200",
  ["red-1"]     =        "#c73c3f",
  ["red"]       =        "#f43841",
  ["red+1"]     =        "#ff4f58",
  ["green"]     =        "#73c936",
  ["yellow-1"]  =        "#9a7f00",
  ["yellow"]    =        "#ffdd33",
  ["brown"]     =        "#cc8c3c",
  ["quartz"]    =        "#95a99f",
  ["niagara-2"] =        "#303540",
  ["niagara-1"] =        "#565f73",
  ["niagara"]   =        "#96a6c8",
  ["wisteria"]  =        "#9e95c7"
}

-- To use your terminal's default background (e.g. for transparency), set the value below to 'back:default,fore:'..gruber_darker.fg
lexers.STYLE_DEFAULT            = 'back:'..gruber_darker.bg..',fore:'..gruber_darker.fg
lexers.STYLE_NOTHING            = ''
lexers.STYLE_CLASS              = 'fore:'..gruber_darker.yellow
lexers.STYLE_COMMENT            = 'fore:'..gruber_darker.brown..',italics'
lexers.STYLE_CONSTANT           = 'fore:'..gruber_darker.quartz
lexers.STYLE_DEFINITION         = 'fore:'..gruber_darker.yellow
lexers.STYLE_ERROR              = 'fore:'..gruber_darker["red+1"]..',back:'..gruber_darker.bg
lexers.STYLE_FUNCTION           = 'fore:'..gruber_darker.niagara..',bold'
lexers.STYLE_KEYWORD            = 'fore:'..gruber_darker.yellow..',bold'
lexers.STYLE_LABEL              = 'fore:'..gruber_darker.green..',back:'..gruber_darker["bg+1"]
lexers.STYLE_NUMBER             = 'fore:'..gruber_darker.wisteria
lexers.STYLE_OPERATOR           = lexers.STYLE_DEFAULT
lexers.STYLE_REGEX              = 'fore:'..gruber_darker.quartz
lexers.STYLE_STRING             = 'fore:'..gruber_darker.green
lexers.STYLE_PREPROCESSOR       = 'fore:'..gruber_darker.quartz
lexers.STYLE_TAG                = 'fore:'..gruber_darker.yellow
lexers.STYLE_TYPE               = 'fore:'..gruber_darker.quartz
lexers.STYLE_VARIABLE           = 'fore:'..gruber_darker["fg+1"]
lexers.STYLE_WHITESPACE         = 'fore:'..gruber_darker["bg+1"]
lexers.STYLE_EMBEDDED           = 'fore:'..gruber_darker["bg+2"]
lexers.STYLE_IDENTIFIER         = lexers.STYLE_DEFAULT -- 'fore:'..gruber_darker["niagara-2"]

lexers.STYLE_LINENUMBER         = 'fore:'..gruber_darker["bg+4"]
lexers.STYLE_LINENUMBER_CURSOR  = 'fore:'..gruber_darker.yellow
lexers.STYLE_CURSOR             = 'reverse'
lexers.STYLE_CURSOR_PRIMARY     = lexers.STYLE_CURSOR..',fore:'..gruber_darker['yellow']
lexers.STYLE_CURSOR_LINE        = 'back:'..gruber_darker["bg+1"]
lexers.STYLE_COLOR_COLUMN       = 'back:'..gruber_darker["bg+1"]
lexers.STYLE_SELECTION          = 'back:'..gruber_darker["bg+1"]..',reverse'
lexers.STYLE_STATUS             = 'fore:'..gruber_darker["fg"]..',back:'..gruber_darker["bg+1"]
lexers.STYLE_STATUS_FOCUSED     = 'fore:'..gruber_darker["fg"]..',back:'..gruber_darker["bg+1"]..',bold'
lexers.STYLE_SEPARATOR          = ''
lexers.STYLE_INFO               = ''
lexers.STYLE_EOF                = lexers.STYLE_LINENUMBER

-- Markdown
lexers.STYLE_HR = ''
lexers.STYLE_HEADING =  'fore:'..gruber_darker["fg"] .. ',back:' .. gruber_darker["bg+3"]
for i = 1,6 do lexers['STYLE_HEADING_H'..i] = lexers.STYLE_HEADING end
lexers.STYLE_BOLD = 'bold'
lexers.STYLE_ITALIC = 'italics'
lexers.STYLE_LIST = lexers.STYLE_KEYWORD
lexers.STYLE_LINK = lexers.STYLE_KEYWORD
lexers.STYLE_REFERENCE = lexers.STYLE_KEYWORD
lexers.STYLE_CODE = lexers.STYLE_COMMENT

