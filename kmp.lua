local inspect = require "inspect"

local teststr = arg[2]

local keywords = {}
for v in string.gmatch(arg[1], "[a-zA-z]+") do
    table.insert(keywords, v)
end

print("TestStr: " .. teststr)
print("Keywords: [" .. table.concat(keywords, ", ") .. "]")

local function split(str)
    -- "abc" -> {"a","b","c"}
	local i
	local ret = {}
	for i=1,string.len(str) do
		table.insert(ret, str:sub(i,i))
	end
	return ret
end

local function genTrie(keywords)
    local count = 0
    local function newNode(parent)
        local node = {}
        node.children = {}
        node.id = count
        count = count + 1
        node.parent = parent
        return node
    end

    local root = newNode(nil)
    local i, keyword, j, char
    for i, keyword in ipairs(keywords) do
        local workingNode = root
        local chars = split(keyword)
        for j, char in ipairs(chars) do
            if not workingNode.children[char] then
                workingNode.children[char] = newNode(workingNode)
            end
            workingNode = workingNode.children[char]
            
            if j == #chars then
                workingNode.endOfSeq = true
                workingNode.text = keyword
            end
        end
    end
    return root
end

local function bfs(trie)
    -- returns a bfs iterator for a trie
    local unvisited = { { "", trie } }
    local function push(a)
        local char, v
        for char, v in pairs(a) do
            table.insert(unvisited, {char, v})
        end
    end
    local function pop()
        return table.unpack(table.remove(unvisited, 1) or {})
    end
    return function()
        local char, workingNode
        char, workingNode = pop()
        if workingNode then
            push(workingNode.children)
        end
        return char, workingNode
    end
end

local function genFailureTable(trie)
    trie.failure = trie
    for char, node in bfs(trie) do
        local parent = node.parent
        if not parent then
            -- root node, ignore it...
            -- tfw no continue
        else
            -- find t
            local t = parent.failure
            while t ~= trie.failure and t.children[char] == nil do
                t = t.failure
            end
            
            if parent ~= trie and t.children[char] then
                t = t.children[char]
            end
            
            node.failure = t
        end
    end
end

local function search(str, trie)
    local workingNode = trie
    local matchedNode = nil -- allows us to go back if we did match a str
    local i, char
    for i, char in ipairs(split(str)) do
        if workingNode.children[char] then
            workingNode = workingNode.children[char]
            if workingNode.endOfSeq then
                matchedNode = workingNode
            end
        else
            workingNode = workingNode.failure
        end
    end
    if matchedNode then
        return matchedNode.text
    end
end

local trie = genTrie(keywords)

-- generate failure table in place
genFailureTable(trie)

print(inspect(trie))

local result = search(teststr, trie)

if result then
    print('Found string: "' .. result .. '"')
else
    print("No match found")
end
