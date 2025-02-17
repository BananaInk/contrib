#!/usr/bin/python3

# Generates the docs in README.md. Write the docs like luadoc/ldoc (using three --- to denote the start of something)

import os
import shutil

print("generating readme")

lua_dir = "/swamp/workspace"
output_dir = "/swamp/repos/contrib"

luadocs = []

os.chdir(lua_dir)
for root, dirs, files in os.walk(".", topdown=False):
    for f in files:
        if f.endswith(".lua"):
            f = root[2:] + "/" + f
            
            comment = None

            with open(f) as fp:
                for line in fp.readlines():
                    line = line.strip()

                    if comment is None:
                        if line.startswith("---") and len(line)>3 and line[3]!="-":
                            comment = line[4 if line[3]==" " else 3:]
                    else:
                        if line.startswith("--") and (len(line)==2 or line[2]!="-"):
                            comment += "\\\n" + line[3 if len(line)>3 and line[3]==" " else 2:]
                        elif line=="":
                            # todo: file comment?
                            comment = None
                        else:
                            # can end with --- to put something that isnt actually code in the code slot
                            if line.startswith("---"):
                                line = line[3:].strip()
                            luadocs.append({
                                "code":line,
                                "comment": comment,
                                "file": f
                            })
                            comment = None

luadocs.sort(key= lambda x: ("!" if x["file"].startswith("lua") else "") +x["file"]+" "+x["code"])

docgen = "".join(
    f"""
### {x["code"]}
{x["comment"]}\n\\
*file: [{x["file"] + ("" if os.path.isfile(output_dir+"/"+x["file"]) else " (hidden)") }](https://github.com/swampservers/contrib/blob/master/{x["file"]})*
""" for x in luadocs
)

with open(output_dir+"/readme_format.md") as fp:
    fmt = fp.read()

with open(output_dir+"/README.md", "w") as fp:
    fp.write(fmt.replace("DOCSGOHERE", docgen))

print("done")