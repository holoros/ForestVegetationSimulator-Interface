import tokenize, io, hashlib, sys
def code_md5(path):
    toks=[t for t in tokenize.generate_tokens(io.StringIO(open(path).read()).readline)
          if t.type not in (tokenize.COMMENT, tokenize.NL, tokenize.NEWLINE, tokenize.INDENT, tokenize.DEDENT)]
    return hashlib.md5(" ".join(t.string for t in toks).encode()).hexdigest()
for p in sys.argv[1:]: print(code_md5(p), p)
