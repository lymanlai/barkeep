# import common.coffee, jquery, and jquery-json

window.Commit =
  init: ->
    $(document).keydown (e) => @onKeydown e
    $(".diffLine").click(Commit.onDiffLineClick)

  onKeydown: (event) ->
    return unless KeyboardShortcuts.beforeKeydown(event)
    switch KeyboardShortcuts.keyCombo(event)
      when "j"
        window.scrollBy(0, Constants.SCROLL_DISTANCE_PIXELS)
      when "k"
        window.scrollBy(0, Constants.SCROLL_DISTANCE_PIXELS * -1)
      when "n"
        @scrollFile(true)
      when "p"
        @scrollFile(false)
      else
        KeyboardShortcuts.globalOnKeydown(event)

  scrollFile: (next = true) ->
    previousPosition = 0
    for file in $("#commit .file")
      currentPosition = $(file).offset().top
      if currentPosition < $(window).scrollTop() or ((currentPosition == $(window).scrollTop()) and next)
        previousPosition = currentPosition
      else
        break
    window.scroll(0, if next then currentPosition else previousPosition)

  #Logic to add comments
  onDiffLineClick: (e) ->
    current = $(e.currentTarget)
    lineNumber = current.attr("diff-line-number")
    filename = current.parents(".file").attr("filename")
    sha = current.parents("#commit").attr("sha")
    current.after(Commit.createCommentForm(sha,filename,lineNumber))

  createCommentForm: (commitSha, filename, lineNumber)->
    commentForm = $(" <form class='commentForm' action='/comment' type='POST'>
                          Comment: <input class='commentText' type='text' name='text' />
                          <input type='hidden' name='sha' value='#{commitSha}'/>
                          <input type='hidden' name='filename' value='#{filename}' />
                          <input type='hidden' name='lineNumber' value='#{lineNumber}' />
                          <input class='commentSubmit' type='submit' value='Submit' />
                          <input class='commentCancel' type='button' value='Cancel' />
                      </form>")
    commentForm.children(".commentText").keydown (e) -> e.stopPropagation()
    commentForm.submit Commit.onCommentSubmit
    commentForm.children(".commentCancel").click Commit.onCommentCancel
    return commentForm

  onCommentSubmit: (e) ->
    e.preventDefault()
    data = {}
    $(e.currentTarget).children("input").each (i,e) -> data[e.name] = e.value if e.name
    $.ajax
      type: "POST",
      data: data,
      url: e.currentTarget.action,
      success: (html) -> Commit.onCommentSubmitSuccess(html, e.currentTarget)

  onCommentSubmitSuccess: (html, form) ->
    $(form).after(html)
    $(form).remove()

  onCommentCancel: (e) ->
    $(e.currentTarget).parent(".commentForm").remove()

$(document).ready(-> Commit.init())
