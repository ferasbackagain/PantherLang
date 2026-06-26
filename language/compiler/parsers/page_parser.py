import re
from language.compiler.ast import ASTPage
from .block_utils import extract_named_blocks


class PageParser:
    def parse(self, source):
        pages = []
        for name, body in extract_named_blocks(source, "page"):
            title = ""
            table = ""
            mt = re.search(r'title\s+"([^"]+)"', body)
            if mt:
                title = mt.group(1)
            mb = re.search(r'table\s+([A-Za-z_][A-Za-z0-9_]*)', body)
            if mb:
                table = mb.group(1)
            pages.append(ASTPage(name=name, title=title, table=table))
        return pages
