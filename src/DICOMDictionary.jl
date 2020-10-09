module DICOMDictionary

using EzXML

function make_dicom_dictionary(outputfile; url = "http://dicom.nema.org/medical/dicom/current/source/docbook/part06/part06.xml", xmlfile = "dicom.xml")
    download(url, xmlfile)
    xml = readxml(xmlfile)
    meta_registry = parse_chapter(xml, "Registry of DICOM File Meta Elements")
    data_registry = parse_chapter(xml, "Registry of DICOM Data Elements")
    open(outputfile, "w+") do io
        write(io, "dcm_dict = Dict(\n")
        write_registry(io, meta_registry)
        write_registry(io, data_registry)
        write(io, ")\n")
    end
    println("DICOM dictionary saved at: $outputfile")
    return nothing
end

function parse_chapter(xml, chaptername)
    # Traverse the XML tree until we reach table
    chapter = find_chapter(xml, chaptername)
    contents = elements(chapter)
    table = find_node(contents, "table")
    tablenodes = elements(table)
    tablebody = find_node(tablenodes, "tbody")    
    tablerows = elements(tablebody)
    # Each tablenode represents a DICOM attribute
    registry = []
    for row in tablerows
        entry = parse_tablerow(row)
        if entry.tag !== (0x0000,0x0000) && !isempty(entry.keyword)
            # (0x0000, 0x0000) is failure to parse tag
            # this is because some tags contain 'xx'
            push!(registry, entry)
        end
    end
    return registry
end

function find_chapter(xml, chaptername)
    parents = elements(xml.root)
    chapters = find_nodes(parents, "chapter")
    for chapter in chapters
        children = elements(chapter)
        titles = find_nodes(children, "title")
        for title in titles
            if nodecontent(title) == chaptername
                return chapter
            end
        end
    end
    error("$chaptername not found")
end

find_nodes(nodes, name) = nodes[@. nodename(nodes) == name]
find_node(nodes, name) = only(find_nodes(nodes, name))

function parse_tablerow(nodes::EzXML.Node)
    d = strip.(nodecontent.(elements(nodes)))
    tag = intify(d[1])
    keyword = replace(d[3], "\u200b" => "") # Delete zero-width spaces
    vr = d[4]
    # Some elements can have variable VR, e.g. "US or SS". Pick the first one.
    if length(vr) > 2
        vr = vr[1:2]
    end
    return (; tag = tag, keyword = keyword, vr = vr, vm = d[5])
end

function intify(tag)
    regex = match(r"\(([0-9A-F]{4}),([0-9A-F]{4})\)", tag)
    if isnothing(regex)
        extracted_tag = ["0000", "0000"]
    else
        extracted_tag = regex.captures
    end
    (group, element) = @. parse(UInt16, "0x" * extracted_tag)
    return ((group, element))
end

function write_registry(io, registry)
   for entry in registry
        out = "$(entry.tag) => [:$(entry.keyword), \"$(entry.vr)\", \"$(entry.vm)\"],\n"
        write(io, out)
    end
    return nothing
end

export make_dicom_dictionary

end
