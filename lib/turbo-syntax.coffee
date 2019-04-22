emptyLine = /^\s*$/
continuationLine = /[\\\[\{\(:;,]\s*$/

module.exports =

  activate: (state) ->
    atom.commands.add 'atom-text-editor',
      'turbo-syntax:end-line-semicolon': => @endLine(';', false)
    atom.commands.add 'atom-text-editor',
      'turbo-syntax:end-line-comma': => @endLine(',', false)
    atom.commands.add 'atom-text-editor',
      'turbo-syntax:backspace-preceding': => @backspaceToPrecedingWord()
    atom.commands.add 'atom-text-editor',
      'turbo-syntax:delete-following': => @deleteToNextWord()
    atom.commands.add 'atom-text-editor',
      'turbo-syntax:c-wrap-block': => @wrapBlock('{', '}')
    atom.commands.add 'atom-text-editor',
      'turbo-syntax:s-wrap-block': => @wrapBlock('[', ']')
    atom.commands.add 'atom-text-editor',
      'turbo-syntax:p-wrap-block': => @wrapBlock('(', ')')

  endLine: (replString, insertNewLine) ->
    editor = atom.workspace.getActiveTextEditor()
    cursorPositions = editor.getCursorBufferPositions()

    cursorPositions.forEach((cursorPosition) ->
      # clear multi-line cursor
      editor.setCursorBufferPosition(cursorPosition)
      cursor = editor.getLastCursor()
      line = cursor.getCurrentBufferLine()
      cursor.moveToEndOfLine()
      editor.insertText(replString) if !continuationLine.test(line) and !emptyLine.test(line)
      editor.insertNewlineBelow() if insertNewLine
    )

    # restore cursor
    editor.setCursorBufferPosition(cursorPositions[0])
    cursorPositions.forEach((cursorPosition) ->
      editor.addCursorAtBufferPosition(cursorPosition)
    )

  backspaceToPrecedingWord: () ->
    editor = atom.workspace.getActiveTextEditor()
    cursorPositions = editor.getCursorBufferPositions()
    newPositions = []

    cursorPositions.forEach((cursorPosition) ->
      # clear multi-line cursor
      editor.setCursorBufferPosition(cursorPosition)

      # find next word
      editor.selectToPreviousWordBoundary()
      range = editor.getSelectedBufferRange()
      if range['start']['row'] < range['end']['row']
        editor.selectRight()

      range = editor.getSelectedBufferRange()
      text = editor.getTextInBufferRange(range)

      # check if on new line
      if range['start']['row'] == range['end']['row']
        range = editor.setTextInBufferRange(range, text.replace(/^\s+$/, ''))
        newPositions.push(range['start'])
      else
        newPositions.push(cursorPosition)
    )

    # restore cursor
    editor.setCursorBufferPosition(newPositions[0])
    newPositions.forEach((cursorPosition) ->
      editor.addCursorAtBufferPosition(cursorPosition)
    )

  deleteToNextWord: () ->
    editor = atom.workspace.getActiveTextEditor()
    cursorPositions = editor.getCursorBufferPositions()
    newPositions = []

    cursorPositions.forEach((cursorPosition) ->
      # clear multi-line cursor
      editor.setCursorBufferPosition(cursorPosition)

      # find next word
      editor.selectToNextWordBoundary()
      range = editor.getSelectedBufferRange()
      if range['start']['row'] < range['end']['row']
        editor.selectLeft()

      range = editor.getSelectedBufferRange()
      text = editor.getTextInBufferRange(range)

      # check if on new line
      if range['start']['row'] == range['end']['row']
        range = editor.setTextInBufferRange(range, text.replace(/^\s+$/, ''))
        newPositions.push(range['end'])
      else
        newPositions.push(cursorPosition)
    )

    # restore cursor
    editor.setCursorBufferPosition(newPositions[0])
    newPositions.forEach((cursorPosition) ->
      editor.addCursorAtBufferPosition(cursorPosition)
    )

  wrapBlock: (bracket, close) ->
    editor = atom.workspace.getActiveTextEditor()
    rangesToWrap = editor.getSelectedBufferRanges().filter((r) -> !r.isEmpty())
    if rangesToWrap.length
      rangesToWrap.sort((a, b) ->
        return if a.start.row > b.start.row then -1 else 1
      ).forEach((range) ->
        text = editor.getTextInBufferRange(range)
        if (RegExp('^\\s*\\'+ bracket + '\\s*').test(text) && /\s*\s*/.test(text))
          # unwrap each selection from its block
          editor.setTextInBufferRange(range,
            text.replace(RegExp('\\'+ bracket + '\\s*'), '').replace(RegExp('\\s*\\'+ close), '')
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
