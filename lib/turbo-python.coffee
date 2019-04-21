emptyLine = /^\s*$/
objectLiteralLine = /^\s*[\w'"]+\s*\:\s*/m
continuationLine = /[\{\(;,]\s*$/

module.exports =

  activate: (state) ->
    atom.commands.add 'atom-text-editor',
      'turbo-javascript:end-line': => @endLine(';', false)
    atom.commands.add 'atom-text-editor',
      'turbo-javascript:end-line-comma': => @endLine(',', false)
    atom.commands.add 'atom-text-editor',
      'turbo-javascript:end-new-line': => @endLine('', true)
    atom.commands.add 'atom-text-editor',
      'turbo-javascript:c-wrap-block': => @wrapBlock('{')
    atom.commands.add 'atom-text-editor',
      'turbo-javascript:s-wrap-block': => @wrapBlock('[')

  endLine: (terminator, insertNewLine) ->
    editor = atom.workspace.getActiveTextEditor()
    cursorPositions = editor.getCursorBufferPositions()

    cursorPositions.forEach((cursorPosition) ->
      editor.setCursorBufferPosition(cursorPosition)
      cursor = editor.getLastCursor()
      line = cursor.getCurrentBufferLine()
      if !terminator
        # guess the best terminator
        terminator = if objectLiteralLine.test(line) then ',' else ';'
      cursor.moveToEndOfLine()
      editor.insertText(terminator) if !continuationLine.test(line) and !emptyLine.test(line)
      editor.insertNewlineBelow() if insertNewLine
      )

    editor.setCursorBufferPosition(cursorPositions[0])
    cursorPositions.forEach((cursorPosition) ->
      editor.addCursorAtBufferPosition(cursorPosition)
    )

  wrapBlock: (bracket) ->
    if bracket == '{'
      close = '}'
    else if bracket == '['
      close = ']'
    editor = atom.workspace.getActiveTextEditor()
    rangesToWrap = editor.getSelectedBufferRanges().filter((r) -> !r.isEmpty())
    if rangesToWrap.length
      rangesToWrap.sort((a, b) ->
        return if a.start.row > b.start.row then -1 else 1
      ).forEach((range) ->
        text = editor.getTextInBufferRange(range)
        if (RegExp('^\\s*\\'+ bracket + '\\s*').test(text) && /\s*\\s*/.test(text))
          # unwrap each selection from its block
          editor.setTextInBufferRange(range,
            text.replace(RegExp('\\'+ bracket + '\\s*')).replace(RegExp('\\s*\\'+ close))
          )
        else
          # wrap each selection in a block
          editor.setTextInBufferRange(range, bracket + '\n' + text + '\n' + close)
      )
      editor.autoIndentSelectedRows()
    else
      # create an empty block at each cursor
      editor.insertText(bracket + '\n\n' + close)
      editor.selectUp(2)
      editor.autoIndentSelectedRows()
      editor.moveRight()
      editor.moveUp()
      editor.moveToEndOfLine()
