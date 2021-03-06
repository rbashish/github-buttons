fs    = require 'fs'
css   = require 'css'
less  = require 'less'
jsdom = require 'jsdom'


class OcticonsSizes
  constructor: (octicons, callback) ->
    sizes = {}
    for svg in fs.readdirSync "#{octicons}/svg" when svg.match /\.svg$/i
      selector = ".octicon-#{svg.replace /\.svg$/i, ""}"

      window = jsdom.jsdom(fs.readFileSync("#{octicons}/svg/#{svg}").toString(), parsingMode: "xml").defaultView
      sizes[selector] =
        height: round window.document.documentElement.getAttribute "height"
        width: round window.document.documentElement.getAttribute "width"
      window.close()

    stylesheet = css.parse fs.readFileSync("#{octicons}/octicons/octicons.css").toString()
      .stylesheet.rules.filter (rule) ->
        rule.type is "rule" and rule.selectors[0].match /:before$/i
      .map (rule) ->
        selectors = rule.selectors.map (selector) -> selector.replace /::?before$/i, ""

        for selector in selectors when selector of sizes
          size = sizes[selector]
          break

        "#{selectors.join ", "} { width: unit(( #{size.width} / #{size.height} ), em); }"
      .join "\n"

    less.render stylesheet, (_, output) ->
      ast = css.parse output.css
      ast.stylesheet.rules = ast.stylesheet.rules.filter (rule, index, array) ->
        _index = array.findIndex (_rule) -> _rule.declarations[0].value is rule.declarations[0].value
        array[_index].selectors = array[_index].selectors.concat rule.selectors if index isnt _index
        index is _index
      callback css.stringify ast

  round = (length) ->
    if Math.abs(length - Math.round length) < 0.01
      Math.round length
    else
      length


new OcticonsSizes "components/octicons", (stylesheet) ->
  if process.argv.length > 2
    fs.writeFileSync process.argv[2], stylesheet
  else
    console.log stylesheet
