import docx,sys
d=docx.Document(sys.argv[1])
body=d.element.body
i=0
for el in body.iterchildren():
    tag=el.tag.split('}')[1]
    if tag=='p':
        t=''.join(x.text or '' for x in el.iter() if x.tag.endswith('}t'))
        print(f"P{i}\t{t}")
    elif tag=='tbl':
        rows=[]
        for tr in el.iter():
            if tr.tag.endswith('}tr'):
                cells=[]
                for tc in tr:
                    if tc.tag.endswith('}tc'):
                        cells.append(''.join(x.text or '' for x in tc.iter() if x.tag.endswith('}t')))
                rows.append(' | '.join(cells))
        print(f"T{i}\t"+"\n\t".join(rows))
    i+=1
