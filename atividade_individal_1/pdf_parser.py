from tika import parser

import re
from PyPDF2 import PdfReader, PdfWriter


class PdfParser(object):

    def __init__(self):
        pass

    def read(self, file):
        # Parse data from file
        file_data = parser.from_file(file)
        # Get files text content
        text = file_data["content"]

        return text

    def read_xml(self, file):
        # Parse data from file
        file_data = parser.from_file(file, xmlContent=True)
        # Get files text content
        text = file_data["content"]

        return text

    def read_by_page(self, file):
        parsed_data_full = parser.from_file(file, xmlContent=True)
        parsed_data_full = parsed_data_full['content']

        return re.findall('<div class="page">(.[\s\S]*?)<\/div>', parsed_data_full)

    def parse_from_file(self, file=str):
        headers = {
            'X-Tika-PDFextractInlineImages': 'true',
        }
        parsed = parser.from_file(file)

        return parsed['content']

    def read_by_page_extrato(self, file):
        parsed_data_full = parser.from_file(file, xmlContent=True)
        parsed_data_full = parsed_data_full['content']

        return re.findall('Pág\.(.[\s\S]*?)<p>Assinado eletronicamente', parsed_data_full)

    def cut_pdf(self, input_path, output_path, ranges: list[tuple[int, int]]):
        """
        Exemplo de ranges:
        ranges = [
                (1558-1, 2623),
                (2878-1, 2967),
                (2977-1, 2988),
                (3262-1, 3842),
                (4879-1, 5392),
                (6329-1, 7806)
                ]
        """
        with open(input_path, "rb") as inputStream:
            pro = inputStream
            reader = PdfReader(pro)
            writer = PdfWriter()

            for start, end in ranges:
                print(f"Adicionando páginas de {start} até {end}")
                for page_num in range(start, end):
                    try:
                        writer.add_page(reader.pages[page_num])
                    except IndexError:
                        print(f"Erro: página {page_num} não existe no PDF")
                        break

        with open(rf"{output_path}.pdf", "wb") as outputStream:
            writer.write(outputStream)
