# Bespoke Lua Docstrings and Document Generation

Docstrings can be in the form of a single-line `--- comment` or multi-line `---[[{\n\tcomment\n\tcomment\n---}]]`. Regular `--` singleline and `--[[ ]]` multiline comments are ignored by the documentation generator. More than three consecutive dashes (e.g. `----`) are _not_ docstrings and should be ignored.

"Standalone" docstrings are docstrings preceeded by a line that contains no alphanumeric characters (whitespace, EOF, other symbols). "Attached" docstrings are 'return type' docstrings or regular single / multiline docstrings that are immediately followed by a line that contains alphanumeric characters that isn't a comment

## Breakdown

```lua
--- an attached single comment
function f(x)

--[[{
    an attached multiline comment

        with some internal indentation that's preserved

--}]]
function f(x)

--- ### this is a standalone docstring with three hashes
   -- because this is a regular comment / whitespace

--- this is an attached docstring
because this is a line of code -- with a regular comment

```

The attached code becomes a `#` header. The level of the header (the number of `#`) is based on the starting level plus the indentation level of the comment. The indentation level is determined as the count of "indentations" before the start of the comment. The attached docstring becomes text underneath the header, separated by a newline. Indentations are counted by a user-configurable pattern, e.g. four spaces or one tab `    |\t` may be one level of indentation. 

```md
# function f(x)

an attached single comment


# function f(x)

an attached multiline comment

    with some internal indentation that's preserved

### this is a standalone docstring with three hashes

# this is an attached docstring

because this is a line of code 

```
Note that indentation from multiline blocks is removed up to the level where the block starts, plus one extra indentation token. Whitespace beyond that level is retained.

'return type' docstrings (`--> `) must be preceeded by alphanumeric characters on the same line.

```lua

    --> not a return type docstring because its just whitespace

function f1(x) --> trailing return type: some description

--- attached singleline
function f2(x) --> trailing return type on the same line

random text --> other text

--[[{ attached multiline --}]]
function f3(x)  --> trailing return: desc
    somecode()

    -- regular comment
```

Returntype docstrings are rendered into quote blocks with a specific format: `> **Returns:** {beforeColon}` plus `\n> \n> {afterColon}` if a `:` with text after it exists. Given the above example, the output should be:

```md
# function f1(x)

> **Returns:** trailing return type
>
> some description

# function f2(x)

attached singleline

> **Returns:** trailing return type on the same line

# random text

> **Returns:** other text

# function f3(x)

attached multiline

> **Returns:** trailing return
>
> desc

```

Note that the return docstrings are either part of another attached docstring, or on their own. If they're on their own, then the text before `-->` becomes a header. Otherwise, the returntype docstring will probably be encountered during the processing of an attached docstring one line above.

Adjacent docstrings should be treated as separate and have a newline between them.

## Python Script

The doc generator should be a python script which takes a mandatory lua filepath as input, and an optional filepath as output, and an optional `-l / --level` number with which to start the `#` headers with. With no output path, just print to stdout. All user-configurable variables should be global constants near the top of the file, such as default level depth, indentation pattern string. Include variables for a header and footer that will be appended to the final output. Include tests that can be run without arguments.

## Example

Lua input

```lua
--- standalone singleline

--[[{
    standalone
    multiline
    
    ~~~lua
        with some embedded codeblock
    ~~~
--}]]

-- ignored
--- standalone singleline followed by a comment (`--+`)
------ ignored

--- attached
x = 1

function f1() --> returntype
function f2() --> returntype: optional description

--- attached
function f3() --> with a returntype: and description

--[[{
    multiline
    attached to a table
--}]] 
tbl = {

    --[[{
        multiline

            attached one level deep
    --}]] 
    y = 5
    
    tbl2 = {
        --- attached level two
        x = y
        --- indented singleline standalone followed by non-alphanumeric characters
    }
}

--- # with a hash in the string

```

Desired markdown output (with an initial header level 2, meaning that first-level headers are `##` )

```md
standalone singleline

standalone
multiline

~~~lua
    with some embedded codeblock
~~~

standalone singleline followed by a comment (`--+` ignored)

## x = 1

attached

## function f1()

> **Returns:** returntype

## function f2()

> **Returns:** returntype
>
> optional description

## function f3()

attached

> **Returns:** with a returntype
>
> and description

## tbl = {

multiline
attached to a table

### y = 5

multiline

    attached one level deep

#### x = y

attached level two

indented singleline standalone followed by non-alphanumeric characters

# with a hash in the string

```

---

If you have any questions or would like anything clarified, please ask before you begin.

Note: your output should be textual to this chat, not to the filefilesystem.
