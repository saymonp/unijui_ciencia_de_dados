from pdf_parser import PdfParser
import json
import re
from bs4 import BeautifulSoup
import csv
import datetime
import pickle


def gera_lista_func(cp_pages):
    # Captura em grupos -> group(1) = id; group(2) = nome; group(3) = cargo 
    # Ex: "Funcionário: 4.378.334 - Carlos Eduardo Silva | cargo: sdfjskdfk"
    padrao = re.compile(
        r'Funcionário:\s*([\d\.\-]+)\s*-\s*(.+) \| Cargo: (.*)')

    funcionarios = []

    for page in cp_pages:
        soup = BeautifulSoup(page, 'html.parser')

        # passa por todas tags <p> da página
        for p in soup.find_all('p'):
            texto = p.get_text()
            match = padrao.search(texto)
            if match:
                funcionario_id = match.group(1).strip()
                nome = match.group(2).strip()
                cargo = match.group(3).strip()

                func_data = {'id': funcionario_id,
                             'nome': nome, 'cargo': cargo}
                if func_data not in funcionarios:
                    funcionarios.append(func_data)

    return funcionarios


def captura_dados(pages, id_alvo, nome_alvo):
    dados = {}

    # Regex para encontrar o mês e o ano no cabeçalho ex: JUNHO / 2014
    meses_map = {
        'JANEIRO': 1,
        'FEVEREIRO': 2,
        'MARÇO': 3,
        'ABRIL': 4,
        'MAIO': 5,
        'JUNHO': 6,
        'JULHO': 7,
        'AGOSTO': 8,
        'SETEMBRO': 9,
        'OUTUBRO': 10,
        'NOVEMBRO': 11,
        'DEZEMBRO': 12,
    }

    competencia_re = re.compile(r'Competência:\s*(\w+\s*/\s*\d{4})')

    # Regex para capturar dias, pode ser 01 ou intervalo 02 a 06
    dia_intervalo_re = re.compile(r'^(\d{1,2})(?:\s+a\s+(\d{1,2}))?')
    horario_re = re.compile(r'\d{2}:\d{2}')

    for page in pages:
        if id_alvo not in page:
            continue

        soup = BeautifulSoup(page, 'html.parser')
        linhas = [p.get_text(' ', strip=True) for p in soup.find_all('p')]

        # Descobre o mês e ano desta página específica
        for linha in linhas:
            comp_m = competencia_re.search(linha)
            if comp_m:
                partes = comp_m.group(1).split('/')
                nome_mes = partes[0].strip().upper()
                ano_num = int(partes[1].strip())
                if nome_mes in meses_map:
                    mes_num = meses_map[nome_mes]
                break

        for linha in linhas:
            # Busca dia ou intervalo no caso deste cp
            m = dia_intervalo_re.match(linha)
            if not m:
                continue

            dia_inicio = int(m.group(1))
            dia_fim = int(m.group(2)) if m.group(2) else dia_inicio

            resto = linha[m.end():].strip()

            semana_m = re.search(
                r'\b(SEG|TER|QUA|QUI|SEX|SÁB|SAB|DOM)\b', resto, re.IGNORECASE
            )
            semana = semana_m.group(1).upper() if semana_m else '?'

            # texto normalizado
            texto = resto.upper()

            # Define o tipo de ocorrência e horários base
            horarios_base = None
            justificativa = 'Normal'

            if 'INSS DOENÇA' in texto:
                horarios_base, justificativa = [
                    '0'] * 8, 'Falta Justificada;INSS DOENÇA'
            elif 'ATESTADO MÉDICO' in texto:
                horarios_base, justificativa = [
                    '0'] * 8, 'Atestado;Atestado médico'
            elif 'FERIAS' in texto or 'FÉRIAS' in texto:
                horarios_base, justificativa = ['0'] * 8, 'Férias'
            elif 'FERIADO' in texto or 'NORM-FER' in texto:
                horarios_base, justificativa = ['0'] * 8, 'Feriado'
            elif 'COMP' in texto:
                horarios_base, justificativa = ['0'] * 8, 'Compensação'
            elif 'DISPENSA' in texto:
                horarios_base, justificativa = [
                    '0'] * 8, 'Falta Justificada;Dispensa'
            elif 'FOLG' in texto or 'FOLGA' in texto:
                horarios_base, justificativa = ['0'] * 8, 'Folga'
            else:
                # Caso normal: extrai horários
                horarios = horario_re.findall(linha)
                horarios.sort(key=lambda h: int(h[:2]) * 60 + int(h[3:]))
                horarios = horarios[:4]
                horarios += ['0'] * (4 - len(horarios))
                horarios8 = horarios + ['0'] * (8 - len(horarios))
                horarios_base = horarios8

            # Expande para cada dia dentro do intervalo ex: de 02 a06
            for dia_atual in range(dia_inicio, dia_fim + 1):
                try:
                    data_obj = datetime.datetime(ano_num, mes_num, dia_atual)
                    data_str = data_obj.strftime(r'%d/%m/%Y')

                    # Se for fim de semana e não tiver justificativa explícita, ajusta rótulo se necessário
                    dia_semana_num = data_obj.weekday()  # 5=Sábado, 6=Domingo
                    semana_str = semana
                    if semana == '?' or semana == '':
                        dias_str = ['SEG', 'TER', 'QUA',
                                    'QUI', 'SEX', 'SÁB', 'DOM']
                        semana_str = dias_str[dia_semana_num]

                    dados[data_str] = [semana_str,
                                       horarios_base, justificativa]
                except ValueError:
                    # Caso dia inválido só ignora
                    continue

        resultado = dict(
            sorted(
                dados.items(),
                key=lambda x: datetime.datetime.strptime(x[0], '%d/%m/%Y'),
            )
        )

        cp_path = rf'arquivos_gerados\CP-{id_alvo}-{nome_alvo}.json'
        with open(cp_path, 'w', encoding='utf-8') as f:
            json.dump(resultado, f, ensure_ascii=False, indent=4)

        print(f'Gerado com sucesso: {id_alvo}')


def gera_avulte_csv(id_alvo, nome):
    path = rf"arquivos_gerados\CP-{id_alvo}-{nome}.json"
    with open(path, "r", encoding="utf-8") as f:
        resultado = json.load(f)

    with open(rf"arquivos_gerados\{id_alvo}-{nome}-avulte.csv",
              "w", newline='', encoding="utf-8") as file:

        writer = csv.writer(file, delimiter=';', quoting=csv.QUOTE_MINIMAL)

        for data in sorted(resultado, key=lambda d: datetime.datetime.strptime(d, r"%d/%m/%Y")):
            dia_semana, horarios, tipo = resultado[data]
            linha = [data, dia_semana] + horarios + [tipo]
            writer.writerow(linha)


if __name__ == "__main__":

    # Converte pdf para texto com padrão xml em páginas
    # Salva em Pickle, assim o código não precisa mais ser executado
    '''
    pdfParser = PdfParser()
    cp_pages = pdfParser.read_by_page(r"Cartao_Ponto_6_Meses.pdf")
    with open(r'arquivos_gerados\\cp_pages.pkl', 'wb') as file:
        pickle.dump(cp_pages, file) 
    '''
    with open(r'arquivos_gerados\\cp_pages.pkl', 'rb') as file:
        cp_pages = pickle.load(file)
    # print(cp_pages[0])

    # Gera lista de funcionários, salva em json. Não precisa mais ser executado
    '''
    funcionarios = gera_lista_func(cp_pages)
    with open(r"arquivos_gerados\funcionarios.json", 'w', encoding='utf-8') as f:
        json.dump(funcionarios, f, ensure_ascii=False, indent=4)
    '''
    with open(r"arquivos_gerados\funcionarios.json", "r", encoding="utf-8") as f:
        funcionarios = json.load(f)

    # Busca os Dados de cada funcionário
    for func in funcionarios:
        print("Buscando: ", func['id'], func['nome'])
        # captura_dados(cp_pages, func['id'], func['nome'])

    for func in funcionarios:
        gera_avulte_csv(func['id'], func['nome'])
